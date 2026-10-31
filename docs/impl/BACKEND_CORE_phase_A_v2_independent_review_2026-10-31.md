# BACKEND-CORE – Independent Review zu Geminis konsolidiertem Gate-A-Entwurf v2

**Datum:** 31.10.2026  
**Status:** `GATE A = HOLD` – Entwurf v2 **substanziell verbessert**, aber noch nicht geschlossen. Kein Feature-Coding.  
**Repository-Basis:** `StradaDelSole/proviantplaner`, main-HEAD `2ec14c66e825078990689b5a753f1566bed13405`  
**Tracking:** Issue #36; Docs-PR #37 (Draft).  
**Quelle:** Gemini-Bericht `BACKEND-CORE – Phase A Architecture Gate (Konsolidierter Entwurf v2)`, 31.10.2026, vom Owner übermittelt.

## 1. Überprüfte Verbesserungen

- **Upload + Download:** R2 `put(ReadableStream)` und `get().body` mit `Response(ReadableStream)` sind in Cloudflares Workers-R2-API grundsätzlich unterstützt. Anders als v1 ist auch der HTTP-Download abgedeckt.
- **R2/D1-Zustandsmodell:** `pending / active / deleting` ist ein sinnvoller Ansatz, ohne Schein-Atomarität über Dienste hinweg.
- **50-MiB-Belegumfang:** Keine eigenmächtige Produktkürzung; Option C1 ist die richtige Zielrichtung, **nicht** die bewiesene Implementierbarkeit.
- **Sensible Daten:** Kanonische Client-Serialisierung als primäre Privacy-Grenze und ehrliche Aussage, dass opake Streams nicht vollständig serverseitig auf IBANs geprüft werden können.
- **EU:** `d1 create --jurisdiction=eu` und `r2 bucket create --jurisdiction=eu` sind korrekte Vorgaben; tatsächliche Ressourcendaten müssen auf Stage kontrolliert werden.
- **Identität:** Provy-Daten und HullQ-Auth0-Identität werden getrennt betrachtet; serverseitige Provy-Entitlements statt unkritisch übernommener JWT-Fachberechtigungen.

Offizielle Plattformgrundlagen: https://developers.cloudflare.com/r2/api/workers/workers-api-reference/ ; https://developers.cloudflare.com/workers/runtime-apis/streams/ ; https://developers.cloudflare.com/workers/platform/limits/ ; https://developers.cloudflare.com/d1/configuration/data-location/ .

## 2. Noch offene Architektur-Blocker

### V2-1 BLOCKER – Nur Worker-Streaming, kein definierter mobiler Speichervertrag

`BackupCoordinator._executeCreateBackupLocked` erzeugt weiterhin große `imageBase64`-Strings und einen vollständigen `jsonEncode`-Payload; `restoreBackup` nutzt `jsonDecode` auf dem vollständigen String. Der vorgeschlagene Flutter-Download in eine temporäre Datei allein behebt das **nicht**. "Isolate-gestützt ODER stream-orientiert" sind zwei unterschiedliche Entwürfe, kein vollständiger Vertrag. Das angekündigte `< 2 MB` Worker-Peak und `< 10 MB` E2E-Testziel sind bislang ungemessen; Cloudflare-Limit ist **128 MB pro Isolate**, das mehrere Requests behandeln kann.

**Gate-Kriterium:** Eine **konkrete** Strategie für Erzeugung, temporäre Datei, Upload, Download, Größen-/Integritätsprüfung, Parsing, Recovery und atomare Dateibereinigung auf Android/iOS festlegen; Arbeitsspeicherlimits und Leistung auf echten Geräten/Staging messen oder als noch zu beweisenden Gate-Bedarf markieren. Nicht zwingend sofort völlig streamingfähigen JSON-Parser bauen; Aufwand vs. geeignete, deterministisch begrenzte Dateiverarbeitung nachweisen.

### V2-2 BLOCKER – Lease-/GC-Zeitmodell nicht sicher

`pending`-Reservation mit **fixer Fünf-Minuten-Lease** widerspricht möglicherweise einem 75-MB-Upload über eine langsame Yacht-/Mobilverbindung. Bei 1 Mbit/s benötigt allein der Transport ungefähr **10 Minuten** (ohne Overhead). Ein zweiter Request kann nach fünf Minuten vermeintlich abgelaufene aktive Staging-Daten löschen; danach kann eine späte Aktivierung eine fehlende R2-Datei als gültiges Backup markieren.

Zusätzlich läuft vorgeschlagene Garbage Collection **nur bei einem späteren erfolgreichen Upload**. Wenn der Nutzer danach nie wieder ein Backup ausführt, bleiben `pending`- und `deleting`-Artefakte unbegrenzt bestehen. "Keine unkontrollierte Müllansammlung" ist damit nicht belegt.

**Gate-Kriterium:** Renewable/heartbeat lease mit Generation/Fencing **oder** eine andere einfache nachweislich sichere Variante: niemals einen aktiven Upload wegräumen; konditionale Aktivierung mit Leasestatus + Accountstatus + tatsächlichem R2-Objekt, R2-/D1-Statusübergang in richtigem Ablauf. Periodische oder anderweitig garantierte **bounded** GC auch ohne spätere Nutzeraktivität; Fehler, Retry, Race und Ausbleiben von Retries testen. Keine Cron-Infrastruktur ohne Kosten-/Komplexitätsvergleich automatisch verlangen.

### V2-3 BLOCKER – Account-Delete-Races und wirkliche Löschung nicht durchdesignt

`UPDATE backups SET status='active' WHERE id=? AND account_id=?` beweist **nicht**, dass das Account während Upload noch `active` ist. Ein gleichzeitig laufendes `DELETE /me` kann damit von einer verspäteten Aktivierung bzw. einem neuen R2-Objekt überholt werden.

`ON DELETE CASCADE` löscht beim bloßen `UPDATE accounts SET status='deleted'` **keine** Child-Rows. Es braucht ausdrücklich definierte, wiederholbare D1-Child-Deletes/R2-Deletes, einen `deleting`-Accountstatus, konditionale Transaktionen/Updates, gesperrte Re-Registrierung bis zum Bereinigungsabschluss sowie einen Nachweis vollständiger Löschung. `status='deleted'` mit dauerhaftem `auth0_sub` verlangt begründete minimale Aufbewahrung, Löschfristen, Privacy-Beschreibung.

**Gate-Kriterium:** Zustandsmatrix für `active -> deleting -> deleted -> optional explicit new registration`, Upload/Download während Löschung, Offline-Zweitgerät, R2-Delete-Fehler/Worker-Kill, Tombstone-Datenminimierung; keine Erfolgsmeldung vor Abschluss der zugesagten Löschung.

### V2-4 HIGH – Unvollständiger Wire-/Backup-Versionsvertrag

Der bisherige Flutter-Client erwartet `POST /v1/backups` mit JSON-Hülle `{device_id, content}` und `GET /v1/backups/:id` mit `{backup, content}`. Die neue Variante sendet rohe Backup-Bytes und empfängt rohe Streams, u. a. mit neuen Headern. Die Behauptung "bestehende Backups bleiben JSON, also rückwärtskompatibel" beantwortet weder bestehende **Clients** noch die Endpunkt-/Versionsmigration.

**Gate-Kriterium:** Explizit versionierte Endpunkte oder sichere Capability-Negotiation; Migrations-/Rollback-Strategie für Altclients, bestehende R2-Objekte und Backup-v1/v2/v3 sowie Backup-v4 inklusive `checkState`, `isAdopted`, Lieferanten-/Bestell-IDs. Fehlende v3-Daten lassen sich rückwirkend nicht rekonstruieren; Dokumentation erforderlich. Kein erzwungener Restore alter Geräte aus einem inkompatiblen neuen Protokoll.

### V2-5 HIGH – 75-MB-Budget noch nicht bewiesen

50 MiB Bilder ergeben Base64 **69.905.068 Bytes** (dezimal) vor übrigen Snapshot-Daten. Ein 75.000.000-Byte-Cap lässt nur **5.094.932 Bytes** für alle anderen Daten, Metadaten und Protokolloverhead. Ein sonst gültiger 50-MiB-Beleg-Snapshot kann daher trotzdem am neuen Upload-Limit scheitern. Die Angaben zu 350–600 KB Reisepayload und 250–400 KB je JPEG sind **Schätzungen**, keine Messungen. Server-Content-Length + gezählter Stream, Client-Limit und R2-Objektgröße müssen denselben Bytebegriff verwenden.

**Gate-Kriterium:** 75 MB vs. 75 MiB festlegen, tatsächliche vollständige Payload-Bounds im Client und Worker konsistent spezifizieren, Worst-Case + reale Törns messen, keine unbelegte Vollständigkeitsgarantie. Client ggf. vor Übertragung anhalten und klare Handlung anbieten, ohne Daten still wegzulassen.

### V2-6 HIGH – Weitere Verträge offen

- **Authentizität/Integrität:** Untrusted `x-device-id`, `x-backup-version`, `x-snapshot-manifest` nur bounded und authentifiziert/gebunden verwenden; eine Client-Manifest-Behauptung ist keine serverseitige Inhaltsprüfung. Upload-Abbruch, unvollständige Datei, Digest/Size-Verifikation vor `active`, Download nach Status/Hash/Size prüfen.
- **Retry/Idempotenz:** Client-Timeout nach D1-`active` kann Backup trotz Antwortverlust erfolgreich geschrieben haben; retry mit neuer UUID erzeugt Duplikate und triggert Retention. Idempotency-Key/Retry-Vertrag vorsehen.
- **Retention/Konkurrenz:** Zwei parallele Aktivierungen mit `created_at`-Ties und unabhängigen Listen/Deletes garantieren nicht maximal fünf `active` Snapshots. Deterministische Reihenfolge und per-Account-Commit-/Prune-Regel benötigen definierte SQL-Atomarität und Tests.
- **Entitlements:** Provy-D1 als technische Autorität ist sinnvoll; Entstehung von `member`/`pro`, tatsächliche Kauf-/Lizenz-Autorität, Ablauf und Offline-Gnadenfrist dürfen nicht allein aus lokalen Caches ohne Quellregel abgeleitet werden.
- **Release-Abhängigkeiten:** BC-1 stellt ein neues Backend-Protokoll vor BC-3-Clientumstellung bereit; vor produktivem Rollout entweder alter und neuer Handler parallel oder kompatible, atomare Deployment-Reihenfolge. Portal-Delete vor funktionaler mobiler Auth nicht als vollständiger End-to-End-Scope ausgeben.
- **CPU:** Cloudflare Workers Free 10 ms CPU/Request, Paid standardmäßig 30 Sekunden bis maximal 5 Minuten; Aussage "Streaming <1 ms" ist ohne Messung nicht belastbar.

## 3. Konsolidierter Review-Entscheid

**Nicht noch einen großen v3-Bericht aus derselben Perspektive erzeugen.** Wir haben nun zwei vollständige Architekturzyklen und sollen nach Engineering Standard die gemeinsamen Ursachen statt weiterer isolierter Amendments schließen.

**Architekturvorgabe für eine letzte, knappe Designentscheidung (kein Code):**
1. Versionierter Backup-Wire-Contract inkl. Client-Datei-/Memory-Budget, E2E-Streaming/Download, Altdaten/Altclients.
2. Einheitliche D1/R2-Operation-State-Machine mit sicheren Upload-/Delete-/GC-/Retention-Races, Lease-Semantik, periodischer Reconciliation und idempotenten Retries.
3. Explizite Owner-Entscheidungen für Provy-only-Kontolöschung und Fortgeltung des 50-MiB-Belegziels; tatsächliche Limits erst nach Größen-/CPU-/Gerätebeweisen.
4. Getrenntes Staging-/Live-/Store-Release-Gate: Real-Auth0, D1/R2-EU-Nachweise, mobile Gerätetests, Cloudflare-Last-/Memorytests, Portal-E2E.

Die Designvorgaben können als kurze ADRs durch Architektur-/Review-Assistent + Owner finalisiert werden; kein weiterer breit formulierter Gemini-Amendment-Zyklus nötig. **Gate A bleibt HOLD bis diese nachweisbaren Verträge und Owner-Entscheidungen vorliegen.**

**Keine Implementierung, keine D1-/R2-Provisionierung, kein Deployment, kein Merge.**
