# ADR-BC-004 – D1/R2 Backup- und Lösch-Lifecycle

**Status:** PROPOSED / TECHNICAL GATE A – kein Implementierungsrelease.  
**Owner-Produktentscheidungen:** ADR-BC-001 (Provy-only-Löschung), ADR-BC-002 (50-MiB-Belegziel): ACCEPTED.  
**Scope:** Worker+D1+R2, konkurrierende mobile Geräte, abgebrochene Uploads, Retention und Recovery; nicht HullQ-Fachdaten.

## Nicht verhandelbare Invarianten

1. Cloud-Backup wird für Benutzer ausschließlich als **active** angezeigt, wenn zu diesem Zeitpunkt eine vollständig verifizierte R2-Version referenziert ist; ein `pending`/unvollständiger Snapshot gilt nicht als gültige Sicherung.
2. Eine erfolgreiche Serverantwort hängt von einem nachweisbaren D1-Commit und vorhandenem, plausibel vollständigem R2-Objekt ab. Antwortverlust nach Commit darf nicht ungeprüft einen zweiten Snapshot erzeugen.
3. D1 und R2 besitzen **keine** gemeinsame Transaktion; jeder Abbruchpunkt muss dauerhaft rekonstruierbar sein – kein `catch` nach Prozess-Kill als alleinige Recovery.
4. Ein Account im Zustand `deleting`/`deleted` kann keine neuen aktiven Backups, Berechtigungen oder Auto-Re-Registrierung bekommen. HullQ/Auth0-Sub wird nicht global gelöscht.
5. Bounded, idempotente Reconciliation läuft auch **ohne spätere Nutzeraktivität**. Temporäre Backups und Restobjekte bleiben nicht unbegrenzt bestehen.
6. Bei Retention wird kein letzter gültiger Restore-Snapshot versehentlich vernichtet. Die Zahl sichtbarer Backups ist unter konkurrierenden Schreiboperationen konsistent begrenzt (Ziel: höchstens 5); physische R2-Objekte können während späterer Cleanup-Arbeit zeitweise mehr sein.

## Daten-/Statusmodell (Architekturvorschlag)

- `accounts`: `active | deleting | deleted` oder äquivalente sichere Status; erforderliche Lösch-/Re-Registrierungs-Metadaten minimal mit dokumentierter Aufbewahrungsdauer. `GET /me` erzeugt nicht implizit neu.
- `backups`: `pending | active | deleting` sowie `account_id`, `r2_key`, `snapshot_version`, Bytegröße, optionaler Digest/prüfbare Integritätsmetadaten, `client_request_id` (unique pro Account), `operation_generation` für Fencing, `started_at`/`expires_at` und bounded GC-/Retry-Status.
- Optionaler `account_deletion_jobs`-/Audit-Status bis tatsächliche Löschung abgeschlossen; keine unbegrenzte personenbezogene Logaufbewahrung. DB-Status und R2-Daten sind ein **verteiltes Zustandsmodell**, keine atomare Ressourcenverschiebung.
- D1-SQL-Migrationen **vor** neuen Worker-Operationen anlegen und aus echten Migrationsdateien testen. `db.batch()` ist nur innerhalb D1 atomar, nie zusammen mit `R2.put/delete`.

## Upload-Sequenz

1. JWT validieren, Account `active` prüfen, Autorisierung/Quota/Bounded-ID/Size/Medientyp prüfen. Client erzeugt **stabile** Request-ID für Retries.
2. D1-Reservation `pending` mit einmaligem R2-Key und Request-ID, so dass wiederholte Requests denselben Status nachschlagen. Unterschiedlicher Snapshot unter gleicher Request-ID wird abgelehnt.
3. Body mit tatsächlich gezählten Bytes an R2 streamen; eventuelle R2-Bestätigung prüfen. Ein begrenzter Maximalupload samt kontrolliertem Abbruch, Ownership-Token/Generation und ggf. erneuerbarer Lease muss echte langsame Verbindungen erlauben, aber weder GC noch alten Retry auf einen neuen Owner wirken lassen. **Eine feste 5-Minuten-Lease allein ist verboten.**
4. Nach R2-Put Metadaten (`head`, Größe, ggf. Digest) validieren. D1-`active`-Transition nur konditional nach erneutem Account-`active`-Check, gültiger Operation-Generation und unverändertem `pending`-Status. In einem SQL-konsistenten Schritt pro Account Retention/Statuswechsel koordinieren; D1-Mechanismus muss im Test beweisen, dass gleichzeitige Uploads das sichtbare 5er-Limit nicht überschreiten.
5. Bei abgebrochener/cancelled Operation kein falscher `201`; Retrying Request-ID wird deterministisch `pending/retryable`, `active/success` oder `deleting/failed` zugeordnet.

## GC, Lease und Prozessabbruch

- **Kein ausschließlich upload-getriebener GC:** bevorzugt eine schlanke Cloudflare Cron-Trigger-`scheduled()`-Reconciliation auf Stage/Prod (Laufintervall/Quota nach Kostenprüfung), die unabhängig von Benutzeraktionen in begrenzten Batches arbeitet. Für fehlgeschlagene Cron-Läufe Retry und Beobachtbarkeit vorsehen.
- GC darf keine noch aktive, langsame R2-Schreiboperation allein wegen `expires_at` löschen. Das Design muss einen **endlich begrenzten serverseitigen Upload-Zeitraum**, wirksamen Abort/Fencing und eine ausreichend große Reconciliation-Gnadenfrist oder gleichwertig robuste Leases definieren und mit echten Slow-Upload-Races beweisen.
- Für late `R2.put`-Completion nach GC darf niemals ein verwaistes ungezähltes Objekt dauerhaft entstehen: Key-/Generation-Fencing, noch sichtbare Lösch-Tombstones und/oder periodischer Prefix-Sweep mit Storage-Lifecycle-Regeln nachweisen. Nur `DELETE FROM pending` genügt nicht.
- Jeder `R2.delete`-Schritt muss retrybar sein; erst nach bestätigter Entfernung wird die dazugehörige D1-`deleting`-Referenz gemäß Vertrag entfernt. R2-Put-fertig/D1-Aktivierung-fehlgeschlagen verbleibt erkennbar und ist nicht als gültige Sicherung gelistet.
- `Retention`: stabiles Sortieren z. B. `created_at, id`, konditionale D1-Markierung von Surplus und wiederholtes R2-Löschen. Unbestätigte neue Snapshots dürfen die letzte gute Version nicht verdrängen.

## Konto-Löschsequenz (ADR-BC-001)

- Der löschende, authentifizierte Provy-Nutzer löst die Zustandsänderung `active→deleting` **zuerst** in D1 aus; alle künftigen Upload-Aktivierungen und Datenoperationen müssen serverseitig gegen diesen Status scheitern, auch mit altem JWT.
- D1-Child-Daten und R2-Objekte der betroffenen Provy-Identität werden über wiederholbare Arbeitsschritte erfasst, verarbeitet und abgeschlossen. `ON DELETE CASCADE` wirkt nicht auf ein bloßes `UPDATE accounts`.
- Abschluss `deleted` und endgültige Benutzernachricht erst bei verifiziertem Cleanup; ggf. `202 Accepted – deletion pending` vorher, **nicht** falsches `200 everything deleted`. Nachträgliche Retry-Fortsetzung über Cron/retrybare Jobs.
- Eine **bewusste** Neuregistrierung darf erst beginnen, wenn der alte Löschjob abgeschlossen ist. Provy-Daten dürfen dabei nicht aus dem früheren R2-Objektbestand auftauchen; Auth0/HullQ-Zugang bleibt unverändert.
- Minimal-Tombstone, Aufbewahrung, Hashes/Personenbezug, Bestätigungstexte und lokale Gerätedaten erhalten einen gesonderten Privacy/UX-Check vor Store-v1.

## Security/Rate/Operational Contracts

JWT Issuer/Audience/Expiry und Provy-Accountzustand auf allen Cloud-Routen validieren; CORS ist kein Ersatz für AuthN/AuthZ. Begrenzte Rate-/Bytes-/Kontoquoten und geringe Concurrent-Uploads mit dokumentierter Fairness; keine ungeschützte öffentliche Lösch- oder Upload-Route. EU-D1/R2-Jurisdiktion bei Ressourcenerstellung mit `--jurisdiction=eu` nachweisen, nicht aus `--location=weur` ableiten. Geheimnisse und Export-/Backupdaten niemals in Logs.

## Pflicht-Races / Evidence

`R2-put finished → D1-commit crash`; Abbruch vor/bei/nach Aktivierung; Netzwerk-Timeout nach Commit + Retry mit gleicher Request-ID; zwei gleichzeitige Backups mit gleicher/verschiedener Request-ID; Retention beim parallelen GET/Upload; langsamer Upload länger als die erste Lease; GC mit fehlerhaftem/verspätetem Upload; Cron-Ausfall, idempotenter Re-Run; Konto-Löschung vs. Upload/Download/Retention; alter JWT und explizite Neuregistrierung; R2-Delete-Fehler und späteres Cleanup. **Aktive Löschung darf keine neuen Provy-Objekte hinterlassen.**

## Technische Gate-A-Restfragen

Welcher konkrete Fencing-/Max-Upload-Mechanismus verhindert **late put after cleanup** unter Cloudflare-Workers-Runtime? Wie werden D1 per-Account-Statusübergänge serialisiert oder CAS-fest gemacht? Wie teuer ist der dauerhafte Cron/Reconciler auf den tatsächlich verwendeten Free/kleinen Paid-Tiers? Hier braucht es eine **kleine, gezielte Spike-/Evidence-Entscheidung**, nicht noch einen groß angelegten generischen Gemini-Amendment-Bericht.

**Status: PROPOSED/HOLD.** Die fachlichen Entscheidungen sind getroffen; erst nach dokumentierter Architekturprüfung, gewähltem Mechanismus und Test-/Stage-Vertrag folgt Gate A.
 
Quellen: https://developers.cloudflare.com/d1/worker-api/d1-database/ · https://developers.cloudflare.com/workers/configuration/cron-triggers/ · https://developers.cloudflare.com/r2/api/workers/workers-api-reference/ · https://developers.cloudflare.com/workers/platform/limits/ .