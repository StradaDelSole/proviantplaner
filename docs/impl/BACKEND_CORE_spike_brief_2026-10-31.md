# BACKEND-CORE – Narrow Technical Proof / Spike Brief (NO FEATURE CODE)

**Status:** DRAFT – Architecture-Evidence-Auftrag; nicht automatisch implementierungsfreigegeben.  
**Referenz:** `docs/impl/BACKEND_CORE_targeted_technical_contract_2026-10-31.md`, ADR-BC-003/004, Issue #36.  
**Ziel:** In einem kleinen, getrennten technischen Testharness ausschließlich die offenen mechanischen Fragen von Gate A beantworten. Keine produktive Backend- oder Flutter-Logik ändern.

## Proof S1 – Worker/R2 End-of-Upload, Fencing, Late Put

- Kontrollierbarer `ReadableStream` mit künstlich verzögerten Chunks, Timeout/Abort und einem festgehaltenen `R2.put`-Promise.
- Teste D1 pending -> terminal/deleting bei Ablauf, R2-Delete, anschließend verspätete Put-Fertigstellung.
- Unterscheide ausdrücklich: Abort stoppt Request-Stream, Abort stoppt R2-Write tatsächlich, Worker-Invocation wird gekillt, Put-Promise liefert verspätet Erfolg.
- Wenn R2 weiterhin schreiben kann: dokumentiere, welche Konvergenzgarantie der periodische Prefix-Sweep bietet; wann ein Accountdelete wirklich als vollständig bestätigt werden darf.
- Nachweis aus Worker-Testumgebung **und**, soweit nötig, späterer Stage-Sandbox. Lokale Mocks beweisen kein Verhalten der realen R2-Runtime.

## Proof S2 – D1 conditional activation + retention

- Durch echte D1-SQL-Migrationen initialisierte lokale Workers-/D1-Tests, **nicht** hartkodierte Kopie der Migration.
- `pending -> active` nur wenn current generation und Account active. Ein Delete race und zwei Uploads gleichzeitig.
- R2 Erfolg, D1 Fehler; D1 Erfolg, Client-Timeout; gleiche Request-ID mehrfach.
- Zwei Aktivierungen bei bereits vier aktiven Snapshots: danach **nie mehr als fünf sichtbare**; letzte intakte Sicherung bleibt verfügbar.
- GC arbeitet cursor-/batch-bounded, ohne zugängliche aktive Objekte zu löschen; GC nach Tag ohne Nutzeruploads.

## Proof S3 – mobiles Streaming-Backup/Restore

- Reine isolierte Testdaten, **keine** Produktionscode-Modifikation: 50 MiB synthetische valide JPEG-Belegbilder, mehrere Tausend Records, Abgrenzung großer Accounts.
- V4-NDJSON-Chunks mit Zeilenlimit und Record-ID-Reconciliation; Hash/Size, UTF-8, IDs, Trailer, Abbruch in beliebiger Chunkposition.
- Messungen: Peak RAM/CPU, temporärer Disk-Overhead, Zeit, Flutter RESTORE-Crash-Recovery-Invarianten. Echte Gerätedatenmessung als **OFFEN** markieren, falls lokal nicht verfügbar; nicht erfinden.
- Legacy Snapshot v1/2/3 ist *eigener* Nachweis, da `jsonDecode` heutige Vollpufferung nutzt.

## Protokoll und STOP

1. Vor Testproduktion der exakte main-HEAD, Testharness-Toolchain und vorhandene D1-/R2-Emulatorfähigkeiten verifizieren.
2. Designfragen **keine** Fake-Testpass-Aussagen: Tabellen S1–S3 mit beobachtetem Ergebnis, Abweichung zur Annahme und offener Stage-/Device-Evidence.
3. Kein Secret, keine fremde Cloud-Ressource, keine produktiven Worker-/Flutter-/D1-Dateien editieren.
4. STOP nach dem Spike-Report zur Independent Gate-A-Review; kein Merge, kein Issue-Abschluss, keine Phase-B-Freigabe.

**Phase-B-Go:** ausdrücklich getrennte Owner-Entscheidung nach Gate A.