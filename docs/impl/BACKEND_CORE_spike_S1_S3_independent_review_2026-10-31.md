# BACKEND-CORE – Independent Technical Evidence Review (Spikes S1–S3)

**Datum:** 31.10.2026  
**Gate:** `HOLD – EVIDENCE GAP`, kein Phase-B-Go.  
**Repo:** `StradaDelSole/proviantplaner`; main `2ec14c66e825078990689b5a753f1566bed13405`; Docs-PR #37, Issue #36.  
**Geprüfter Bericht:** vom Owner am 31.10.2026 eingereichter „BACKEND-CORE – Phase-A Technischer Nachweisbericht (Spikes S1–S3)“.  
**Nicht als unabhängig bewiesen:** Testausführungen `S1 3/3`, `S2 5/5`, `S3 3/3` wurden **nur im Bericht behauptet**. Keine Spike-Dateien in `main` oder im Head von PR #37 gefunden, keine zugehörigen CI-Artefakte. Daher keine Review-Möglichkeit für Testcode, Assertions, Versuchsanordnung, Ressourcen oder Messmethoden. Keine Behauptung, dass der implementierte Produktionscode bereits geprüft/geändert sei.

## A. Bestätigte und wertvolle Hinweise aus dem Bericht

- Der gemeldete S1.2-Versuch mit `put` nach `delete` zeigt **unter den beschriebenen Simulationsbedingungen** eine R2-Ghost-Objekt-Gefahr. Fachliche Konsequenz: D1-Status-CAS verhindert Sichtbarkeit, aber ein **periodischer R2-Keyspace-Sweep** muss verspätete physische Objekte erfassen. Die tatsächliche Cloud-Runtime bleibt Stage-Evidence.
- R2 Worker Bindings besitzen dokumentierte Stream-APIs für `put` und `get(...).body`, nicht jedoch eine automatische Cross-System-Transaktion mit D1.
- S2-Tests berichten CAS gegen gleichzeitig gelöschte Accounts, Idempotency und Retention. Ein numerischer SQLite-Zeitvergleich bzw. konsequentes `datetime(lease_expires_at)` ist notwendig, wenn ISO-8601-`T`-Werte und SQLite-`datetime('now')` gemischt werden. Normiertes UTC-Epoch-Sekundenfeld ist ggf. einfacher.
- NDJSON mit begrenzter Zeilen- und Chunksize ist eine plausible Richtung für mobil speicherschonende Backups. Die Datenintegrität des echten Drift-/Receipt-Restore ist dadurch noch nicht nachgewiesen.

## B. Drei gezielte Gate-relevante Findings

### S-1 – BLOCKER: Testharness/Beweiskette nicht am Exact-HEAD nachvollziehbar

Die im Bericht genannten `backend/test/spike_s1_r2_fencing.spec.ts`, `backend/test/spike_s2_d1_activation.spec.ts` und `test/spike/spike_s3_streaming_backup_test.dart` sind im geprüften `main` **und** in `docs/backend-core-phase-a-architecture-2026-10-30` **nicht vorhanden**. 11 erfolgreich gemeldete Tests können daher weder statisch auditiert noch durch GitHub CI reproduziert werden.

**Nachweis:** Testdateien und relevante Harness-Konfiguration in einem **eigenen nur-testbezogenen Branch/PR** committen; alle drei Suiten sowie Befehle, lokale Versionsangaben, vollständige Test-/Messlogs und deterministische Assertions liefern. Gemeldete S3-Messwerte als Desktop-Lokal-Messung kennzeichnen. Kein Produktionscode, kein echter Cloud-Resource-Zugriff ohne separate Owner-Zustimmung.

### S-2 – BLOCKER: Bekannte R2-Stream-Länge vs. geplanter Byte-Counter nicht nachgewiesen

Der Bericht enthält einen entscheidenden Hinweis: `R2.put()` akzeptiert nach seiner Laufzeitprüfung keine beliebigen `ReadableStream`-Instanzen ohne bekannte Länge. Die bisherige ADR-BC-003/004-Pipeline verlangt hingegen einen **zählenden `TransformStream` vor `R2.put`**. Ein gewöhnlicher `TransformStream` kann die bekannte Länge des HTTP-Bodys verlieren und `R2.put` mit `TypeError` scheitern lassen. S1.1 testet einen `FixedLengthStream`, nicht die vollständige Transform-/Request-/R2-Produktionskette.

**Nachweis (ein gezielter Test):** Tatsächliche Route `Request.body -> größenprüfender Byte-Counter -> R2.put` bei korrekter, fehlender, falscher und überschrittener `Content-Length`-Angabe ausprobieren. Lösung wählen, die gleichzeitig Length-Contract, Memory-Bound, Security-Limit und saubere Abbruchsemantik erfüllt. Falls das nicht in einem Stream-Übergang möglich ist: `R2.put(request.body)` mit strikt validierter deklarierten Länge und abgesicherter R2-Size-/Digest-Kontrolle vor D1-Aktivierung oder `FixedLengthStream`-Piping prüfen; nicht heimlich den Sicherheitszähler entfernen.

**Präzisierung:** R2 dokumentiert `onlyIf`-Bedingungen für `put`. Das ist **keine D1/R2-weite Generation-Fencing-Garantie**; pauschal „R2 hat gar kein serverseitiges CAS“ ist technisch zu weit gefasst. `onlyIf`-Bedingungen und eindeutig neue Keys pro Attempt müssen im Modell unterschieden werden.

### S-3 – HIGH: S3-Mengen- und Memory-Aussagen nicht ausreichend belegbar

- Bericht: `266` Chunks mit maximal `192 KiB` rohen Bilddaten enthalten höchstens `266 × 196.608 = 52.297.728` Bytes, also **49,875 MiB** – **nicht volle 50 MiB**. Für exakt 50 MiB sind mindestens 267 Chunks erforderlich (der letzte kleiner).
- Allein diese 266 vollständigen Chunks benötigen **69.730.304 Base64-Bytes** (= **69,73 MB** dezimal = **66,5 MiB** binär), zuzüglich NDJSON-Overhead. Die gemeldete `NDJSON-Dateigröße 67,01 MB` ist damit **nur plausibel, wenn die Einheit tatsächlich MiB ist**, oder das Testset weniger Rohbytes enthält. Exakte `File.lengthSync()`-Bytes und summierte rohe Bildbytes in Assertions ausweisen.
- Gemeldetes **100,14 MB RSS-Delta auf Desktop** ist kein Nachweis eines niedrigen mobilen Peaks. RSS-Delta ist nicht gleich absolutes RSS/Heap-Maximum; Desktop in 1,9 s sagt nichts Verlässliches zu einem schwachen Android/iOS-Gerät.
- Der S3-Restore-Test bearbeitet nach Bericht nur **50 Chunks / 10 JPEGs / 500 Items**, nicht die zuvor erzeugte 50-MiB-Gesamtdatei. Der echte Restore muss mit ID-Remap, realer SQLite-Tabelle, Beleg-Staging, Journal, Crash-Gates und Finanzinvarianten zusammenspielen; ein isolierter NDJSON-LineSplitter kann dies nicht belegen.
- Die Legacy-v3-Aussage „Dart-String immer UTF-16 und 10 MiB führen garantiert zu 60–80 MB Peak / 50 MiB zwangsläufig OOM“ ist **nicht gemessen**, sondern eine unbelegte extrapolierte Worst-Case-Annahme; Dart-String-/Heap-Verhalten und OOM hängen von Runtime/Gerät/Encoding ab.

**Nachweis:** Test-Dataset/Bytezahlen und Einheiten reparieren; Full-Size-50MiB-Boundary und Full-Restore-Test, wenigstens eine begrenzte Low-RAM-Simulation und später ein echtes Android-Gerät als separaten Release-/Phase-B-Evidence-Gate. Legacy-v3-Memory mit echten Messpunkten statt „unweigerlich OOM“ ausweisen.

## C. D1- und GC-Beweiskraft präzisieren

S2.4 meldet „exakt fünf active“ **nach** zwei parallelen Aktivierungen. Das belegt nur den Endzustand, nicht notwendigerweise das stärkere Versprechen „zu keinem Zeitpunkt mehr als fünf sichtbar“. Test muss mit Barrieren/Interleavings und Beobachter-Zugriff oder SQL-atomarem D1-Übergang belegen, dass keine Zwischenansicht sechs `active` zeigt.

S2.5 simuliert GC eines alten `pending`-Eintrags; **S1.2 zeigt gerade, dass ein später `R2.put` nach dem GC ein Ghost-Objekt erzeugen kann**. Damit ist S2.5 keine vollständige Late-Put-/Deletion-Garantie. Für bounded Konvergenz ohne neue Nutzeruploads werden mindestens nachweisbar gesicherter Trigger, cursor-basierter R2-Prefix-Abgleich, echte D1-Referenzen und erneuter GC bei späten Writes benötigt. Ein allein abgelaufenes Lease darf eine laufende Übertragung nicht als beendet behandeln.

D1-Lease-Zeitwerte müssen in UTC-gleichem Format verglichen werden; bei ISO-String `datetime(lease_expires_at)` verwenden und Null-/Invalid-/Timezone-Fälle testen, oder Epoch-Integer.

## D. Gate-Entscheidung und kleinster nächster Schritt

**HOLD – nicht wegen eines erneuten allgemeinen Architekturfehlers, sondern weil die entscheidenden Spike-Beweise nicht reproduzierbar sind und S-2/S-3 noch Korrekturen verlangen.** ADR-BC-001/002 bleiben Owner-ACCEPTED; ADR-BC-003/004 und die konkrete Streaming-/GC-Mechanik bleiben TECHNICAL DESIGN SELECTED / EVIDENCE REQUIRED.

Der kleinste nächste Schritt ist **nicht** ein weiterer umfangreicher Gemini-Aufsatz, sondern:
1. **Spike-Testcode als isolierter PR** mit Runner-/CI-Evidence vorlegen, keine Produktionscodeänderung.
2. **Nur** gezielte Zusatztests für tatsächliche Worker-Byte-Counter-Pipeline, late put nach GC, konkurrierende D1-Retention, exakte 50-MiB-NDJSON-/Restore-Größen.
3. Akzeptierte technische Grenzen in ADR-BC-003/004 berichtigen, D1/R2-Semantik und spätere Stage-/Device-Nachweise getrennt halten.

Danach erneuter Independent **Testcode-/Evidence-Review**, kein drittes allgemeines Architektur-Amendment. Keine Feature-Freigabe, kein Merge von PR #37, kein Cloud-Deployment.

## Referenzen

- https://developers.cloudflare.com/r2/api/workers/workers-api-reference/
- https://developers.cloudflare.com/r2/api/workers/workers-api-usage/
- https://developers.cloudflare.com/workers/runtime-apis/request/
- https://developers.cloudflare.com/workers/platform/limits/
- https://developers.cloudflare.com/workers/testing/vitest-integration/
