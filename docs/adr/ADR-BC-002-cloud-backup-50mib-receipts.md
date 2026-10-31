# ADR-BC-002 – Cloud-Backup mit 50 MiB Belegbildbudget

**Status:** ACCEPTED – Owner-Produktentscheidung vom 31.10.2026.  
**Kontext:** BACKEND-CORE Phase A · Issue #36 · PR #37.

## Entscheidung O-02 (verbindlich)

Das bisherige **50-MiB-Limit für die Summe der unkomprimierten Belegbild-Dateibytes** aus RECEIPT1 wird als Produktziel beibehalten. **Keine eigenmächtige Kürzung** auf 20 MiB, 25 MB Gesamt-Upload oder „Bilder nur lokal“, um die erste Backend-Implementierung zu vereinfachen.

Das 50-MiB-Budget gilt **nur für die Belegbildbytes**, nicht für die gesamte JSON-Datei, den HTTP-Request oder den Cloudflare-Worker-Speicher. Der eigentliche vollständige Backup-Snapshot muss ebenfalls innerhalb eines expliziten, überprüften Protokollbudgets transportierbar sein.

## Rechenbasis und tatsächliche Nachweispflicht

- `50 * 1024 * 1024 = 52.428.800` Bytes Belegbilder.
- Base64 daraus: `4 * ceil(52.428.800 / 3) = 69.905.068` Bytes ASCII, ohne Törn-, Bordkassen-, Lieferanten- und Format-Overhead.
- Ein vorläufiger Uploaddeckel von **75.000.000 Bytes** lässt nur `5.094.932` Bytes übrigen Spielraum und ist deshalb **noch keine nachgewiesene Garantie** für jeden zulässigen Törn.
- Worker-Limits, Request-/Response-Grenzen, mobiles RAM/Storage, Decode-Peaks, CPU und Kosten sind mit synthetischen Worst-Case- und repräsentativen realen Sicherungen nachzuweisen. Die 128-MB-Memorygrenze gilt **pro Worker-Isolate, nicht pro Request**; ein Worker kann mehrere Requests bedienen.
- Angemessener Stream-/Datei-Prozess soll Datenverlust und stilles Weglassen vermeiden. Kann der volle Funktionsvertrag technisch nicht gehalten werden, folgt eine neue **explizite Owner-Entscheidung**, kein automatischer Funktionsabbau.

## Datensatz-Vollständigkeit

Ein als vollständig beworbenes Cloud-Backup muss alle als sicherungswürdig klassifizierten Provy-Daten aufnehmen. Nachgewiesene derzeitige Lücken: `ListItems.checkState`, `ListItems.isAdopted`, `SupplierService.saved_suppliers_json` und `DeliveryOrderService.delivery_orders_json`. Für Lieferaufträge sind alte/neue Trip- und Stop-IDs beim Restore korrekt abzubilden. Versionierte Migrationen und Abgrenzung alter Snapshots gehören zum Design.

**Absichtliche Ausschlüsse:** Auth-/Refresh-Tokens und geheime Schlüssel. Bankdaten (IBAN usw.) werden weiterhin nicht strukturiert in den Cloud-Snapshot aufgenommen. Bilder können selbst sichtbare Bankinformationen enthalten; es gibt **keine** unbelegte serverseitige Zusage, dass opake Fotos solche Informationen nicht enthalten. Backup-UI/Datenschutzhinweise müssen die tatsächliche Behandlung richtig beschreiben.

## Die gewählte Architektur bleibt evidenzabhängig

Bevorzugt ist die vorhandene Cloudflare R2/Worker/D1-Basis mit streamingfähigem **Upload und Download** und geprüfter, begrenzter mobiler Datei-/Speichernutzung. Binäre/chunked Container oder ein Rewrite sind nicht automatisch freigegeben. Endgültige Byte-Limits, Streaming-Format, Retention und Kosten werden technisch belegt, nicht erraten.

**Gate:** Owner-Produktfrage O-02 ist entschieden. Protokoll-, Last- und Geräte-Nachweise bleiben offen; dieser ADR ist kein Stage-/Store-/Phase-B-Go.

## Quellen

RECEIPT1 `BackupCoordinator.defaultMaxBackupReceiptBytes`; verifizierter main-HEAD `2ec14c66e825078990689b5a753f1566bed13405`; Cloudflare Workers Limits https://developers.cloudflare.com/workers/platform/limits/ (29.10.2026); R2 Workers API https://developers.cloudflare.com/r2/api/workers/workers-api-reference/ (31.07.2026).