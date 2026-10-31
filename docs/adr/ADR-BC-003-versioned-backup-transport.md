# ADR-BC-003 – Versionierter Backup-Transport und mobiler Speichervertrag

**Status:** PROPOSED / TECHNICAL GATE A – kein Implementierungsrelease.  
**Owner-Entscheidung:** O-02 (50 MiB rohe Belegbildbytes) in ADR-BC-002 ACCEPTED.  
**Repo-Basis:** main `2ec14c66e825078990689b5a753f1566bed13405`, Issue #36, Docs-PR #37.

## Kontext und Optionen

Alt: `POST /v1/backups` mit `{device_id, content: "<JSON string>"}`; `GET /v1/backups/:id` mit `{backup, content: "<JSON string>"}`. Das befüllt im Flutter-Client und Worker mehrere große Strings; im Backup JSON sind JPEGs als Base64 eingebettet. `BackupCoordinator` serialisiert/decodiert zusätzlich vollständig im mobilen Prozess. Allein Worker-Upload-Streaming beseitigt diese mobilen Spitzen NICHT.

**Option A (empfohlen für einen risikobegrenzten Retrofit):** eigenes, versioniertes Stream-Wire-Protokoll auf bestehenden Workers/R2/D1, Datei-basierter mobiler Serializer/Restore mit nachzuweisender Peak-Memory-Grenze, legacy v1 parallel.  
**Option B:** kompletter Chunk-/Presigned-URL-/Multipart-Rewrite. Erst erwägen, wenn A nachweislich nicht robust innerhalb der Produktlimits funktioniert.  
**Nicht empfohlen:** v1-Aufrufe in-place auf Raw-Binary/Streaming umstellen, ohne alte Clients und alte Backup-Objekte zu migrieren.

## Vorgeschlagener verbindlicher Wire-Kontrakt

Die folgenden Pfade sind **Designvorgabe, vor Phase B anhand des API-Clients zu bestätigen**:

- Bisherige `/v1/backups`-Handler bleiben für kompatible, begrenzte Legacy-Payloads zunächst erhalten; keine stillschweigende Umdeutung des JSON-Envelopes.
- `POST /v2/backups`: authentifizierter, gebundener Raw-Body (zunächst versioniertes Snapshot-JSON; MIME `application/vnd.provy.snapshot+json`); erforderlicher `Idempotency-Key` und kanonisch normalisierte `device_id` als **begrenzte** Metadaten, `snapshot_version` getrennt von `wire_version`. Ein Client darf nie auf unbestätigte Response als erfolgreich schließen.
- `GET /v2/backups`: ausschließlich nutzbare, vollständig aktivierte Versionen mit Größe und deklarierter Snapshot-Version; strikte Mandantentrennung.
- `GET /v2/backups/{id}/content`: verifizierter R2-Stream als HTTP-Response, **keine** `obj.text()`/`c.json(content)`-Zwischenpufferung; Metadaten nur in eng begrenzten Response-Headern. Responses mit `Cache-Control: no-store`, korrektem Content-Type und sauberer Client-Cancellation.
- Die Versionsmatrix legt ausdrücklich fest: alter v1-Client↔alter Worker; neuer v2-Client↔v2-Worker; neuer Client liest alte Snapshot-v1/v2/v3-Daten; neuer Snapshot-v4 nur von kompatiblen Clients. `GET /v2` ist **Wire-Version 2**, nicht automatisch Snapshot-Version 2.
- Ein neues Snapshot-v4 enthält `checkState`, `isAdopted` und alle freigegebenen persistenten Quellen inkl. Lieferanten/DeliveryOrders mit validierten ID-Remaps; Auth-Tokens und private Zahlungsfelder explizit auslassen. Alte Snapshots ohne diese Felder erhalten definierte Defaults, ohne nachträglich unmögliche Rekonstruktion zu behaupten.
- Rollout in Staging: serverseitige additive v2-Schnittstellen **vor** Client-Benutzung; v1 frühestens nach dokumentierter Mindestclientversion/Deaktivierungsentscheidung zurückbauen. Das Ändern einer v1-Routenbedeutung ist verboten.

## Mobiles Backup/Restore – tatsächliche Memory-/Dateiverträge

1. Datei-basierte Snapshot-Erzeugung in privat zugänglichem temporären Verzeichnis: JSON aus typisierten Daten inkrementell in UTF-8 schreiben; Bilddateien in gebundenen Chunks Base64-kodieren (Blockgrenzen 3 Bytes beachten), niemals `jsonEncode` eines vollständigen 70-MB-Objektgraphen als Standardpfad.
2. Vor Upload Vollständigkeit und Unversehrtheit der Datei prüfen (formale Snapshot-Version, Summe unkomprimierter Belegbytes ≤ 50 MiB, Voll-Dateigröße, Integritätsprüfung); Aufbewahrung temporärer Dateien streng begrenzen; Crash-/Restart-Cleanup mit aktiver Operationssperre.
3. App sendet temp-Datei als Stream, mit konfigurierbarer endlicher Upload-/Retry-Politik und kontrollierten Fehlern bei Offline, App-Kill, Low Storage, Timeout. Vorhandener RECEIPT1 `StorageOperationCoordinator` bleibt für die lokale Konsistenz maßgeblich, darf aber nicht zu langlebiger UI-Blockade führen.
4. Download: Response direkt in privaten temporären Dateipfad; dabei tatsächlich empfangene Bytes und vereinbarte Größe zählen, ggf. Digest/Manifest verifizieren (nicht aus einem allein vom Client gelieferten Hash auf Authentizität schließen). Bei Abbruch temp löschen, produktive SQLite-/Belegdateien unverändert.
5. **Restore muss ebenso begrenzt sein.** Nicht das Download-Tempfile mit `File.readAsString` und vollständigem `jsonDecode` zurück in den RAM holen, sofern realistische Maximalsnapshots den Gerätebudgetnachweis nicht bestehen. Konkret einen validierten Streaming-/Chunk-Parser oder anderen gemessenen, strikt begrenzten Ansatz spezifizieren. Staging/Preflight/Commit/Roll-forward-Regeln aus RECEIPT1 dürfen nicht umgangen werden.
6. Das angekündigte `<2 MB Worker-Puffer` oder `<10 MB End-to-End` sind KEINE geprüften Werte. Für den vollständigen Flow Mobile↔Worker↔R2 sind repräsentative und Worst-Case-Messungen unter parallel laufenden Requests und auf realen Geräten Release-Gates.

## Größe/Datenschutz/Integrität

Das Bildbudget ist 52.428.800 Bytes, Base64 69.905.068 Bytes. **Ein vorläufiger 75.000.000-Byte-Transportdeckel ist noch nicht als ausreichend akzeptiert**; übriges Inventar kann den Platz überschreiten. Nach Vermessung dürfen harte Transportlimits für DOS-Schutz gesetzt werden, die den von O-02 akzeptierten Funktionsumfang tatsächlich abdecken. Wenn nicht möglich, zurück zum Owner.

Der Worker prüft gültige JWTs, Accountstatus, zulässigen Medientyp/Versionsheader, bounded Metadaten, Byte-Counter zusätzlich zu optionalem `Content-Length` und R2-Objektgröße. Ein opaker Stream erlaubt **keine** serverseitige Behauptung „inhaltlich frei von IBANs“. Kanonischer Clientserializer muss private Zahlungsfelder konstruktiv auslassen; hochgeladene Fotos können selbst sichtbare sensible Informationen enthalten und müssen entsprechend geschützt werden. Authentizität des Uploaders kommt von gültigem Konto-/JWT-Kontext, **nicht** von untrusted Headern.

## Verbindliche Negativnachweise und Gate

- Legacy/new Client-Server-Matrix inklusive Alt-Backups; unbekannte Snapshot-Version wird sicher abgewiesen, nicht still falsch restauriert.
- 50 MiB Bilder + großer realistischer Katalog, Byte-Grenze knapp darunter/darüber; Token fehlt, falscher Account, falscher Content-Length, Chunked-Abbruch, Low Disk, App-Kill vor/bei/nach Temp-Datei.
- R2-Teilobjekt/Hash- oder Size-Mismatch, unvollständiger Download, Restore vor SQLite-Commit und nach Commit, Wiederanlauf mit gültigen Bildreferenzen.
- Worker-Isolett-Memory/CPU, Flutter-Peaks auf Low-End-Geräten und echtes Stage-R2; Tests müssen diese Artefakte/Traces liefern.

**Gate A noch offen:** finaler mobiler Parser-/Memoryansatz, konkret numerische gemessene Transportgrenze und Versions-/Migrationstestplan. **Keine Phase-B-Implementierung durch dieses ADR.**

**Referenzen:** https://developers.cloudflare.com/r2/api/workers/workers-api-reference/ ; https://developers.cloudflare.com/workers/platform/limits/ ; GitHub main-HEAD und RECEIPT1 Review.