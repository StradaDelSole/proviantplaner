# BACKEND-CORE – Independent Phase-A Architecture Review (31.10.2026)

**Review-Status: CHANGES REQUESTED / Gate A HOLD. Keine Phase-B-Freigabe.**  
**Tracking:** Issue #36 · **Docs-PR:** #37 (Draft).  
**Prüfgrundlage:** Gemini-Bericht `BACKEND-CORE – Phase A Architecture Gate & Independent Risk Review`, eingereicht am 31.10.2026 (nicht als ungeprüfte Tatsache übernehmen); GitHub main-HEAD `2ec14c66e825078990689b5a753f1566bed13405`; `docs/ENGINEERING_STANDARD_v1.0.md` und Owner-Festlegungen.

## Positiv unabhängig nachgewiesen

- Der vorgeschlagene **gezielte Retrofit** des vorhandenen Flutter/Auth0/Cloudflare-Hono/D1/R2/Astro-Stacks ist dem grundlegenden Rewrite vorzuziehen, solange die kritischen Verträge belastbar gelöst werden.
- Auth0-Flutter-Adapter kann synthetische Tokens speichern und Netzwerkfehler als erfolgreichen Login ausweisen (`lib/core/services/hullq_auth_service.dart`).
- `ListItems.checkState` und `ListItems.isAdopted` sind echte DB-Felder, fehlen aber in `BackupCoordinator._serializeListItem` und `restoreBackup`; separate Secure-Storage-Quellen für Lieferanten/Bestellungen fehlen ebenfalls.
- Konto-Löschroute entfernt D1-Provy-Account; `ensureAccount` kann den Provy-Account für denselben Auth0-Sub später neu anlegen. Das Webportal hat keine echte Auth0-Löschung.
- R2-vor-D1 Backup-Persistierung, keine serverseitig gebundene komplette Requestgröße, Test-SQL-Duplikate und CORS-Fallback `*` sind reale Ist-Befunde.

## Findings – konsolidierte Ursachen statt Patches

### A – BLOCKER: Halb gelöster Datenfluss / Streaming nur Upload

Der Bericht empfiehlt `bucket.put(..., c.req.raw.body)` mit Header-Metadaten und 25-MB-Gesamtdeckel. Das behandelt **nicht**:
- `backend/src/db/backups.ts:getBackup`: R2-Objekt wird via `obj.text()` vollständig in einen String geladen.
- `backend/src/routes/backups.ts:GET /:id`: kompletter Snapshot wird in `c.json({ ..., content: result.content })` erneut JSON-kodiert.
- `lib/core/services/hullq_api_client.dart:downloadBackup`: vollständige JSON-Antwort wird in Dart dekodiert, `content` als String zurückgegeben.
- `BackupCoordinator.restoreBackup`: vollständiges JSON + Base64-Belege wird in Flutter erneut dekodiert.

**Auftrag:** End-to-End-Upload *und Download* einschließlich Datei-/Speicherformate, Grenzen, Maximalgrößen, Restore und Legacy-Kompatibilität entwerfen. Kein nur halb vollzogener Protokollwechsel. Cloudflare R2 kann eingehende Request-Streams in `put()` akzeptieren, doch Größe, Abbruch, Integrität, GET-/Response-Streaming und Client-Kompatibilität brauchen Nachweise.

### B – BLOCKER: D1.batch() macht R2 nicht atomar

D1-SQL-Transaktionen umfassen nur D1. Bei Worker-Kill nach erfolgreichem `R2.put`, aber vor D1-Insert gibt es kein ausführbares `catch`; ebenso bei Retention, Account-Löschung und parallelen Requests. R2/Delete und D1/Delete sind keine gemeinsame atomare Transaktion.

**Auftrag:** Definierter Status-/Retry-/Idempotency-/Reconciliation-Vertrag (ggf. Pending/Committed/Deleting + bounded GC). Nach Prozessabbruch darf ein gültiger Backup-Snapshot nicht still verschwinden; Partial-R2-Orphans müssen eventual und sicher bereinigbar sein. Maximal fünf **sichtbare gültige** Backups ist möglich; `exakt fünf physische D1+R2-Objekte zu jedem Zeitpunkt` darf nicht versprochen werden.

### C – HIGH: 25 MB ist ein Produktentscheid, kein durch Messung nachgewiesenes Limit

Aktuelle App erlaubt **50 MiB nur für Belegbilder**, noch vor Base64/JSON. Der Vorschlag, einfach das Cloudbackup auf 25 MB gesamt zu kürzen, ändert den Funktionsvertrag erheblich. Angekündigte Beispielkapazitäten „100 Törns/20–30 Belege“ sind nicht belegt.

**Auftrag:** Repräsentative und Worst-Case-Snapshots erzeugen/vermessen: Originalbilddaten, Base64-Zeichen, Request/Response, R2-Größe, Client/Worker Peaks, GZIP-Bomben/Decompression, CPU, Restore, Plattform-Storage. Zwei minimale Optionen vergleichen: nachweislich gebundenes Ganz-Snapshot-Protokoll vs. verlustfrei gestreamter/segmentierter Snapshot. Keine stillschweigende Änderung von 50 MiB auf 25 MB; Owner muss Nutzer-/Feature-Auswirkung ausdrücklich akzeptieren.

### D – HIGH: Datenschutz-Prüfung nicht an untrusted Client auslagern

Der Vorschlag, wegen Streaming die serverseitige IBAN-Prüfung komplett durch einen Client-Check zu ersetzen, unterläuft die bisherige serverseitige Sicherheits-/Datenschutzbehauptung. Ein vom Nutzer manipulierter oder veralteter Client kann beliebige Daten senden. Umgekehrt ist ein Regex über gigantischen JSON/Base64-Strings keine zuverlässige strukturierte Datenschutzprüfung.

**Auftrag:** Definieren, was der Server tatsächlich validiert (zulässiges Format, Felder, Version, Länge, Hash/Manifest, sensible Felder), was kanonischer Clientserializer ausschließt, und welche Garantie realistisch ist. Bei opakem Binärstream darf der Server keine geprüfte Inhaltsfreiheit behaupten. Keine ungeprüften Zahlungsdaten in Provy-Backups.

### E – HIGH: D1 EU-Jurisdiktion falsch spezifiziert

Geminis D1-Kommando `--location=weur` ist **nur ein Best-Effort-Standorthinweis**. Es garantiert keine EU-Jurisdiktion. Cloudflare D1 unterstützt explizit `--jurisdiction=eu`, die bei Erstellung verbindlich ist; die Standort-Hint-Option wird bei gesetzter Jurisdiktion ignoriert. Der Bericht darf nicht „Frankfurt“ aus `weur` folgern. Bei R2 gilt entsprechend `--jurisdiction=eu`.

**Korrektur:** `npx wrangler d1 create proviantplaner-db --jurisdiction=eu`; tatsächliche Resource-Jurisdiction danach aus verifizierten Cloudflare-Metadaten nachweisen. EU-Datenresidenz allein belegt noch keine umfassende DSGVO-Compliance.

### F – HIGH: Tombstone-/Re-Registration-/Löschrecht unvollständig

`deleted_at` und 403 nach Löschung können Re-Projection verhindern, aber dauerhafte Aufbewahrung von `auth0_sub` benötigt Rechtsgrund, Datenminimierung, definierte Fristen und Nutzerinformationen. Wie nach bewusstem, erneutem Provy-Login/Neuregistrierung neu eröffnet wird, ist bislang nicht sicher spezifiziert. Race Accountdelete vs. Upload, andere Geräte und laufende JWTs brauchen Zustands- und Berechtigungssperren. Provy darf die HullQ-Identität nicht ohne ausdrückliche Owner-Entscheidung löschen.

**Auftrag:** Vollständigen Zustandsautomaten `active → deleting → deleted [→ explicit re-register]` oder einfacheres gleichwertiges Design mit idempotentem Backend-/R2-Löschvertrag, minimalem Tombstone, sicherer Wiederanmeldung und einer wirklich benutzbaren Web-Löschmöglichkeit entwerfen. Google Play verlangt tatsächliche Löschung der zugehörigen App-Daten und einen von der App unabhängigen funktionalen Web-Weg; ein Portal-Button allein genügt nicht.

### G – HIGH: Entitlement-Autorität und Reihenfolge

Bericht formuliert `fehlende Entitlements im JWT / GET /me`; Auth0-JWT muss **keine** Provy-Fachberechtigungen enthalten. Autorität ist serverseitig zu definieren (Provy-D1 oder separat freigegebene HullQ-Subscription-Autorität), API-Response und Offline-Anzeige entsprechend. Die angegebene Flutter-Datei unter `features/trip/data/entitlements_service.dart` ist falsch; tatsächlich `lib/features/entitlements/data/entitlements_service.dart`.

**Auftrag:** Eigene Entitlement-Schnittstelle mit Herkunft, Status, Expiry und Offline-Vertrag; Freischaltung darf nicht allein an eine lokal gespeicherte `member`-Zeichenkette geknüpft bleiben. Reihenfolge der Implementierungs-Slices so planen, dass Login- und Delete-Funktionen gemeinsam testbar sind, ohne tote Accountpfade zu hinterlassen.

### H – MEDIUM: Überzogene/nicht belegte technische Aussagen

- Bericht nennt Free Worker CPU 50 ms und Paid 30 s. Cloudflare-Dokumentation (29.10.2026) nennt **Free 10 ms pro Request** und **Paid standardmäßig 30 Sekunden, konfigurierbar bis 5 Minuten**.
- Bericht nennt sichere R2-/D1-Cleanup-Garantien und "transaktionssichere Retention", wo nur Best-Effort ohne Recovery-Pfad vorliegt.
- `Content-Length` allein ist kein Schutz vor chunked oder falschen Angaben; Byte-Counter/Server-/Clientverhalten dokumentieren. Ebenso große Download-Responses begrenzen.
- CORS-Allowlists können Browserzugriffe einschränken, **ersetzen keine Authentifizierung/Autorisierung** und schützen nicht vor direkten HTTP-Skripten.
- „keine IBANs verlassen jemals das Mobilgerät“ ist mit lediglich Client-Regex nicht belegbar.
- Beispiele für Callback-Schemes, Domains und Paketversionen müssen aus dem echten Provy-Platform-/Auth0-Setup abgeleitet werden statt als verbindliche Werte erfunden zu werden.

## Gate-A-Entscheidung

**HOLD.** Die identifizierten Ist-Probleme sind real, Retrofit ist plausibel, aber Architektur, Datenvertrag und Löschsemantik sind noch nicht stabil genug. Kein neuer Produktionscode, keine D1-/R2-Provisionierung und keine Phase-B-Freigabe.

**Erwartete Nachlieferung von Gemini:**
1. konsolidiertes Design v2, das A–H **in einem** durchgehenden Vertrag löst;
2. Upload- und Download-Sequenz mit Datenformatversionen, konkreten Limits und Failure-/Race-Matrix;
3. vollständiges Dateninventar (Drift, Secure Storage, Files, Privacy Exclusions) und Backward-Compatibility;
4. Konto-/Auth0-Lifecycle als State Machine, Account-/Entitlementvertrag;
5. Testing-/Evidence-Matrix (Worker, Flutter, Portal, echte Geräte, Stage) ohne fingierte Tests;
6. einzig echte Owner-Entscheidungen: Scope der Provy-only-/HullQ-Identitätslöschung; konkrete Backup-Abdeckung/Größenpolitik; Stage-/Domain-/Auth0-Setup vor Live-Test.

**STOP nach Architekturbericht. Independent Gate-A-Review erforderlich.**

## Öffentliche Referenzen, überprüft am 31.10.2026

- Cloudflare Workers Limits: https://developers.cloudflare.com/workers/platform/limits/
- Cloudflare D1 jurisdiction: https://developers.cloudflare.com/d1/configuration/data-location/
- Cloudflare D1 `batch`: https://developers.cloudflare.com/d1/worker-api/d1-database/
- Cloudflare R2 object streaming: https://developers.cloudflare.com/r2/objects/upload-objects/
- Cloudflare R2 jurisdiction: https://developers.cloudflare.com/r2/reference/data-location/
- Google Play Account Deletion: https://support.google.com/googleplay/android-developer/answer/13327111
