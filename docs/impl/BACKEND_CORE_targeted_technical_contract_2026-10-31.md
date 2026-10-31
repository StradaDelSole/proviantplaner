# BACKEND-CORE – Konkreter Technical Architecture Contract (Phase A)

**Datum:** 31.10.2026. **Status:** TECHNICAL DESIGN SELECTED / EVIDENCE REQUIRED – **Gesamt-Gate A weiterhin HOLD**.  
**Repository-Baseline:** main `2ec14c66e825078990689b5a753f1566bed13405`.  
**Referenzen:** ADR-BC-001/002 OWNER-ACCEPTED; ADR-BC-003/004 bisher PROPOSED; Issue #36, Docs-PR #37.  
**Ziel:** Zwei verbliebene technische Entscheidungen konkretisieren, ohne neue generische Gemini-Amendment-Runden und ohne Produktcode.

## 1. Entscheidung T1 – Backup-Wire- und Dateiformat

**Ausgewählt (Architekturvorgabe, noch nicht gemessen):** additive `/v2/backups` API mit Raw-Streaming in R2, direktem R2-Stream als Download; intern **Snapshot-v4 als bounded line-delimited JSON (NDJSON)**. Backup-v3 bleibt als Legacy-Leseformat erhalten.

Warum NDJSON: Ein einzelnes großes v3-JSON-Dokument enthält komplette Base64-Bilder und erzwingt derzeit grosse Zwischenobjekte in Flutter. Eine typisierte Records-Struktur erlaubt echten Stream-Import und -Export mit strikter Recordgrenze, ohne eine komplexe Streaming-JSON-Parserbibliothek oder ein neues Binärarchiv einzuführen. Ein zusätzlicher Container oder presigned S3-Upload ist derzeit unnötig.

### 1.1 Snapshot-v4, kanonisches Format

- Erste Zeile `header`: format="provy-snapshot", version=4, canonical field names, export id, required capabilities, optional Counts. **Keine Headerwerte für Berechtigungen vertrauen.**
- Für jede persistierte Entität eine `record`-Zeile mit `type`, `old_id`, `old_trip_id`, den zulässigen fachlichen Feldern; Byte-Größen und String-Limits pro Typ. Restore validiert Schema und ID-Referenzen vor Promotion.
- Belegbilddaten als `receipt_chunk`-Zeilen: höchstens **192 KiB rohe Bildbytes pro Chunk** (Base64 ≈256 KiB), `receipt_id`, `seq`, `chunk_count`, `byte_count`. Der Parser begrenzt jede eingehende Zeile auf **512 KiB** und schreibt Bilder direkt in privates Staging. Kein vollständiges Base64-Bild als einzelner JSON-String. `chunk_count`/Größen durch Manifest und Endprüfung begrenzen; `seq` streng aufsteigend.
- Letzte Zeile `footer`: deklarierte Record-/Belegzählungen und Gesamtvolumen, Abschlussmarker; exakter Endzustand wird durch Digest/Size des **gesamten** kanonischen Datei-Streams überprüft. Ein einzelner Client-Hash ohne R2-Abgleich ist nicht vertrauenswürdig. Keine nachträglichen Bytes hinter dem Footer.
- Bekannte Tabellen, fremde Schlüssel, ID-Remapping und frühere Datenlücken aus ADR-BC-002 sind verpflichtend. **Lieferanten/DeliveryOrders** erfordern vollständige Reconciliation inkl. Stop-ID und Trip-ID, keine stillen ausgelassenen Datensätze. `checkState`/`isAdopted` bleiben erhalten. Geheimnisse/strukturierte Zahlungsdaten bleiben ausgeschlossen; in Bildern sichtbare Bankdaten sind nicht automatisch herausgefiltert.
- Raw NDJSON MIME `application/x-ndjson`; `wire_version=2`, `snapshot_version=4` voneinander unabhängig.

### 1.2 Flutter-Workflow

1. Unter dem bestehenden `StorageOperationCoordinator` typisierte Daten konsistent lesen; Staging-File in privatem Cache/Docs-Verzeichnis erstellen, Serializer schreibt inkrementell, ohne vollständiges Backup-Objekt im RAM.
2. Belege chunkweise lesen und Base64 nach Längen-/Integritätsprüfung kodieren. 50 MiB Roh-Belegbilder ist das verbindliche Produktbudget (ADR-BC-002). Kein stiller Ausschluss. Für eine vollständige Sicherung gelten zusätzliche, **zu vermessende** Gesamt-Datei-/Freispeichergrenzen.
3. Snapshot zum Schluss validieren (Header/Footer/Bytezählung/Schema); vollständige Temp-Datei als HTTP-Body in Chunks senden. **Weder Flutter noch Worker bauen beim Upload einen einzigen großen String.**
4. Download in private Temp-Datei; HTTP-Status, tatsächlich empfangene Bytes, Content-Length falls vorhanden und verifiziertes R2-Checksum/Hash mit Datei prüfen. Bei Fehler nur Temp-Datei entfernen; bestehende Drift-DB und Belegordner bleiben unangetastet.
5. Streaming-Parser liest Record-weise; validiert vor dem Commit, schreibt alle relationalen Daten in eine vorübergehende, gebundene Repräsentation/temporäre Tabelle und Bilder ins Staging. **RECEIPT1 Crash-/Journal-/Commit-Semantik unverändert bewahren.** Kein produktiver DB-/Datei-Swap vor Gesamtkonsistenzprüfung.
6. Erfolgreich abgeschlossener Restore räumt Temp-Dateien nach Journal-/Commit-Finalisierung auf. Unterbrochener Restore überlebt App-Kill und kann anhand der akzeptierten RECEIPT1-Recovery-Regeln wiederanlaufen.
7. **Legacy:** bestehende Snapshot-v1/v2/v3-Dateien bleiben lesbar über versionierten, gesondert getesteten Importpfad. Große v3-Daten auf leistungsschwachen Geräten sind ein **gezieltes Geräte-/Memory-Release-Gate**; wenn der bestehende `jsonDecode`-Pfad nicht genügt, vor Phase-B-Acceptance einen begrenzten Legacy-Importer ergänzen. Ein nur im Happy Path funktionierender v4-Import genügt nicht.

### 1.3 Größenbudgets und Plattform

- 50 MiB Rohbilder = 52.428.800 Bytes; Base64 erfordert mindestens 69.905.068 ASCII-Bytes, zuzüglich NDJSON-Record-Overhead und übrigen fachlichen Daten.
- **90.000.000 Bytes** als **vorläufiger, explizit PROPOSED** Gesamt-HTTP-Body-Deckel (unter derzeit 100 MB auf Cloudflare Free/Pro), sofern die gemessene vollständige Snapshot-Ausdehnung damit verträglich ist. Kein stilles 75-MB-Limit. Validierte Records und Dateisystemgrenzen zusätzlich erforderlich.
- Ein Nutzer mit mehr als dem gemessenen sonstigen Datenbudget erhält einen klaren Abbruch **vor** dem Remote-Upload und kann sein Backup nicht als abgeschlossen ansehen. Wenn das Produktversprechen dadurch praktisch verletzt wird: erneut Owner-Entscheidung, nicht unbemerktes Limit.
- Worker-Limit **128 MB pro Isolate**, nicht pro Request. CPU Free **10 ms**; eine ausschließlich auf papiergestützte "Streaming <1 ms"-Behauptung ist verboten. Echte Messungen unter parallelen Requests/realen Geräten sind vor Stage-/Store-Go Pflicht.
- Transport nachprüfbar: bounded Headergröße, JWT, Request-/Responsegröße und `R2.put(..., {sha256})` wenn von verwendeter Runtime/Paketversion geprüft; R2 HEAD/Version/Size und Client-seitig gemessener Hash. `Content-Length` allein reicht nicht, Byte-Counter verpflichtend.

## 2. Entscheidung T2 – D1/R2 Upload-, Delete-, Retry- und GC-Protokoll

**Ausgewählt:** Eindeutige, unveränderliche physische R2-Objektschlüssel pro Upload-Versuch, D1-Zustände `pending/active/deleting`, stabile Client-Idempotency-Key und **konditionale Aktivierung**. GC wird nicht allein auf einen Lease-Timestamp gestützt, sondern auf gefencete Terminalzustände + einen periodischen D1- und R2-Abgleich.

### 2.1 Upload-Sequenz

1. Auth0-JWT (Issuer/Audience/Expiry) und **Provy-Account active** serverseitig bestätigen. Bound `device_id`, `request_id`, `snapshot_version`, `expected_size` und `expected_sha256` bei Reservation. **Request-ID pro fachlicher Sicherung stabil**, jeder tatsächliche neue Upload-Versuch erhält ein zufälliges `attempt_id`/Generation und einen einzigartigen R2-Key; Keys niemals zwischen verschiedenen Versuchen überschreiben.
2. D1-Reservation in `pending`; UNIQUE(`account_id,request_id`). Identischer Retry mit abgeschlossener Sicherung liefert dieselbe aktive Backup-ID. Neue Versuche nach Fehler dürfen nur mit eindeutiger Generation und fehlender laufender Vorversion übernommen werden.
3. Worker liest Raw-Body mit Byte-Counter, optionalem Content-Length und **endlichem Upload-Wallclock-Budget**; `R2.put` muss beendet/abgebrochen werden können. Ein fester **5-Minuten-GC-Lease ist verboten**. Temporäres, später nicht aktiviertes Objekt ist nicht downloadbar.
4. Nach bestätigtem R2.put `head`/Objekt-Metadaten auf wirklich empfangene Größe, Version und SHA-256-Digest abgleichen. Der Worker darf weder einen bloßen Header noch Client-Success ohne R2-Beweis als gültig einstufen.
5. D1-Aktivierung + Retention in **einer** transaktionalen D1-Batch oder nachgewiesen äquivalenter SQL-CAS-Folge: `UPDATE backups ... status='active' WHERE status='pending' AND attempt_generation=? AND EXISTS(SELECT 1 FROM accounts WHERE id=? AND status='active')`. Ergebnis muss exakt eine Zeile beeinflussen; sonst kein `201`. In demselben atomaren D1-Abschnitt überschüssige `active` Backups (sortiert `created_at DESC,id DESC`) auf `deleting` setzen; Ziel `<=5` sichtbare gültige Backups auch bei zwei gleichzeitigen Aktivierungen.
6. Wenn Client-Antwort verloren geht: `GET /v2/backups/by-request/{request_id}` (oder vertraglich äquivalente statusabfrage) ergibt `pending | active | failed/deleting`. Keine automatische doppelte Upload-Retrierung mit neuer Request-ID.

### 2.2 Zeit-/GC-Vertrag ohne Late-Put-Datenverlust

- **Endliche Upload-Laufzeit muss technisch nachgewiesen werden**, nicht nur dokumentiert. Vorschlag als Testparameter: max. 30 Minuten Wallclock für einen 90-MB-Transfer; bei 1 Mbit/s braucht der reine Upload rund 12 Minuten. Langsamere Netze dürfen mit transparentem Retry/Resume-Vertrag umgehen; eine unbegrenzte Upload-Session ist nicht zulässig.
- Cron (zunächst z.B. stündlich) verarbeitet `pending` und `deleting` in **bounded batches**. `pending` darf bei unklar laufendem Upload nie allein wegen 5 Minuten Alter gelöscht werden. Erst nach nachgewiesenem Ende/Timeout **und Sicherheitsfrist** als terminal `deleting` markieren; die Aktivierung wird durch Status/Generation-CAS gefenct.
- R2-Objekte werden beim `deleting`-Status entfernt; D1-Tombstone/GC-Journal bleibt, bis R2-Abwesenheit verifiziert ist. **Ein verspätetes `R2.put` nach einem ersten `R2.delete` kann erneut einen Orphan erzeugen.** Daher zusätzlich periodisch über den eindeutig benannten R2-Backup-Prefix mit Cursor iterieren und nichtreferenzierte, nicht mehr lebende Keys nach Alters-/Statusprüfung erneut entfernen. Niemals einen **aktiven** Snapshot auf Grundlage nur eines alten R2-List-Ergebnisses löschen; bei verdächtigen Zuständen konservativ nicht löschen, Fehler melden.
- Erst wenn die Worker-Abbruch-/Fencing-Semantik und damit die maximal mögliche Spätschreibphase **auf Stage nachgewiesen** ist, darf der GC-Aufbewahrungshorizont festgelegt werden. Der oben genannte Zeitraum 30 Minuten ist ein **Design-Parameter, keine verifizierte Cloudflare-Garantie**.
- Cloudflare R2 unterstützt `list(prefix,cursor,limit)` und Cron-Triggers. Optionaler R2-Lifecycle-Schutz für **ausschließlich terminale/staging Prefixe** kann Zusatzgarantie bieten, darf **niemals** aktiv referenzierte Snapshot-Keys nach pauschalem Alter löschen.
- D1-/R2-Kosten/Rate-Limit, Cron-Free-Tier-CPU-Budget (10 ms) und ein bezahlter Minimalplan werden **gemessen**, nicht vorausgesetzt. Kein unbegrenztes R2-Prefix-Vollscan pro Cron.

### 2.3 Account-Delete-Vertrag

1. Benutzer bestätigt „Provy-Cloud-Daten löschen“ nach dem vereinbarten ADR-BC-001-UX-Vertrag. D1-Transition `active -> deleting` ist vor R2-/D1-Delete-Schritten verbindlich.
2. Neue Reservations, Aktivierungen, Cloud-Reads und Entitlement-Requests auf `deleting/deleted` scheitern. Bereits laufende Uploads bleiben als pending/terminal referenziert, bis ein sauberes Ende und R2-Abwesenheit belegt sind.
3. D1-Kinddaten explizit und idempotent löschen; Parent-UPDATE aktiviert kein CASCADE. R2-Objekte und mögliche späte nichtreferenzierte Uploads werden durch denselben Reconciler bereinigt.
4. **202 deletion pending** bei laufenden/unklaren Uploads oder R2-Störungen. **200 deletion completed** erst nach tatsächlichem, auf den definierten R2-Keyspace geprüften Abschluss inklusive bereits begonnener Upload-Versuche. Der maximal mögliche Zeitraum bis finaler Löschmeldung folgt aus dem geprüften Upload-/GC-Vertrag; keine Fake-Erfolgsmeldung.
5. `deleted` blockiert implizite Account-Neuanlage; bewusste Neuregistrierung erst nach bestätigter Löschung. Identitäts-Tombstone minimal, Aufbewahrungsdauer/Datenschutztext noch zu bestimmen. HullQ/Auth0-Identität bleibt unberührt.

### 2.4 End-to-End-Testmatrix für Phase B

| ID | Eingriff / Race | Akzeptanz |
| --- | --- | --- |
| F01 | `R2.put` fertig, Worker vor D1-Commit beendet | pending/invisible; Retry/GC ohne stillen validen Backupverlust |
| F02 | Zwei Uploads für gleiche/different Request-ID | eindeutige Idempotenz, kein Überschreiben, aktives 5er-Limit |
| F03 | >5 Minuten langsamer Upload / GC während Body-Stream | kein Löschen oder Aktivieren falscher Version |
| F04 | GC markiert alten Versuch terminal, verspätetes `R2.put` liefert noch Daten | keine Aktivierung, periodischer Sweep entfernt Orphan, dauerhaft kein aktives stale Objekt |
| F05 | DELETE `/me` während Upload/Retention/Download | keine neue Aktivierung oder Neuprojektion; 202/200 ehrlich, nach Abschluss keine nachlaufenden Provy-Cloud-Daten |
| F06 | Client verliert `201`, wiederholt gleiche `request_id` | keine Duplikate, letzte gesunde Sicherung bleibt |
| F07 | D1 CAS scheitert, R2 objekt vorhanden / R2-Delete fail | kein Erfolg; idempotente, bounded Reconciliation |
| F08 | 50 MiB Bilder, viele Törn-/Lieferdaten, 90-MB-Wirelimit, R2 stream | kein stilles Weglassen; echte Peak-Memory/CPU-Werte; genaue Größen in Bytes |
| F09 | Legacy v1/v2/v3 und v4-Roundtrip auf echtem Gerät | keine Daten-/Referenzverluste, keine Mock-only-Behauptung |
| F10 | App-Kill während Disk-Staging/Upload/Restore | intakte lokale DB/Belege, bereinigbarer Temp-State, identische Finance-Invarianten |
| F11 | fehlende/gefälschte Header, falsche SHA-256, falsche Account-ID | 4xx und kein sichtbares invalides Backup |
| F12 | Cron fällt 24h aus, Neustart/Wiederholung | bounded Forward-Progress, verwaiste Objekte werden schließlich entfernt |

## 3. Pflichtbeweise vor Gate-A-Finalfreigabe / Stage-Go

1. **Targeted Spike (kein Feature-Code):** Stubbed Worker/D1/R2-Harness oder Stage-Sandbox zur R2-`put(Stream)`-Abbruchsemantik nach Wallclock-Timeout und möglichem Late-Put-vs-GC. Wenn keine robuste Grenze möglich, Phase A gezielt auf eine besser fencbare Alternative (z.B. Multipart mit explizitem abort) ändern. Nicht per `catch` behaupten.
2. **D1 CAS / Batch-Beweis:** zwei konkurrierende Aktivierungen mit paralleler Konto-Löschung und stochastischem Zeitplan; atomare Status-/Retention-Regeln gegen echte D1-Migration testen.
3. **Mobile Parser-/Memory-Proof:** v4-NDJSON-Rekonstruktion aus 50-MiB-Belegbildern auf repräsentativ schwachem Android-Gerät; v3-Legacy-Restore ohne OOM; ein vorhandener RECEIPT1-Restore darf nicht geschwächt werden.
4. **Release-Pflichten:** echter Auth0-Tenant/Callbacks, EU-D1-/R2-Ressourcen, Web-Löschweg, Datenschutz- und Store-Anforderungen, Last-/Quota-/Kostenmessungen.

**Bewertung:** T1 und T2 sind als **konkrete technische Designrichtung festgelegt**, nicht als bereits auf Cloudflare bewiesene Implementierung. Gesamt-Gate A ist **HOLD bis zum gezielten Spike und finalen Independent Review**. Dieser Vertrag gibt keinen neuen Feature-Slice frei.

## Offizielle Plattformreferenzen (31.10.2026)

- https://developers.cloudflare.com/workers/platform/limits/
- https://developers.cloudflare.com/r2/api/workers/workers-api-reference/
- https://developers.cloudflare.com/r2/objects/upload-objects/
- https://developers.cloudflare.com/workers/configuration/cron-triggers/
- https://developers.cloudflare.com/d1/worker-api/d1-database/
- https://developers.cloudflare.com/r2/buckets/object-lifecycles/
