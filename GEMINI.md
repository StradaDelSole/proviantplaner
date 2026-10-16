# Arbeitsanleitung für Gemini (Docs-to-Code) – v0.23

Diese Datei liest du zu Beginn JEDER Sitzung vollständig, bevor du etwas anderes tust.

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung |
| v0.2 | 23.09.2026 | Klare Regeln "Darf / Darf nicht", Pflichtablauf pro Sitzung, Stoppregeln, Berichtsformat |
| v0.3 | 23.09.2026 | Durchlauf-Modus: alle freigegebenen Slices nacheinander ohne Freigabe pro Plan; Commit und Push auf main nach jedem grünen Slice; Review erst am Ende |
| v0.4 | 24.09.2026 | Gehärtete Programmierregeln nach Review S2: feste Typen, keine versteckten Platzhalter, ehrliche Berichte, datengetrieben, Kommazahlen mit Toleranz, Testregeln |
| v0.5 | 25.09.2026 | Regel 8: keine Eigenbauten von Standards; freigegebene Pakete; Abnahme nur mit echtem Nachweis |
| v0.6 | 25.09.2026 | Regel 9: keine Behauptung von Handlungen, die Gemini nicht selbst ausführt; Art des Nachweises je Kriterium; Regel 10: nichts aus späteren Versionen sichtbar bauen |
| v0.7 | 26.09.2026 | Backend-Regeln (TypeScript, Cloudflare, Geheimnisse, kein Deployment); Freigabe B0–B5 |
| v0.8 | 06.10.2026 | Post-Pivot-Gating: Owner-accepted Specs/Reconciliations vor älterem PRD/SLICES; PIVOT3-A Review-Gate; Bootsprofil-Scope ausdrücklich erlaubt |
| v0.9 | 06.10.2026 | PIVOT3-A owner-accepted; ausschließlich PIVOT3-B freigegeben; verbindliche Crew-/Watermaker-Reconciliation |
| v0.10 | 06.10.2026 | PIVOT3-B owner-accepted; PIVOT3-A/B abgeschlossen; kein Folgeslice freigegeben |
| v0.11 | 06.10.2026 | PIVOT2 Provisioning Review freigegeben |
| v0.12 | 06.10.2026 | Externe Zweitprüfung: PIVOT2 HOLD; vorgezogen werden FIX-B, DATA1 und Watermaker-Reserve-Reconciliation |
| v0.13 | 06.10.2026 | FIX-B – Unified Settlement Ledger als einziger Implementierungsslice freigegeben |
| v0.14 | 06.10.2026 | FIX-B independent review: enger Review-Amendment freigegeben |
| v0.15 | 07.10.2026 | FIX-B Amendment Re-Review: letzter enger Amendment |
| v0.16 | 07.10.2026 | FIX-B final acceptance review: Currency-Entry-Amendment |
| v0.17 | 07.10.2026 | FIX-B final unabhängig geprüft: READY FOR OWNER ACCEPTANCE |
| v0.18 | 07.10.2026 | FIX-B Owner Acceptance: COMPLETE; kein Folgeslice freigegeben |
| v0.19 | 07.10.2026 | DATA1 als einziger Implementierungsslice freigegeben |
| v0.20 | 07.10.2026 | DATA1 independent review: enger Review Amendment freigegeben |
| v0.21 | 16.10.2026 | DATA1 Owner Acceptance: COMPLETE; GitHub-PR/CI als authoritative Full-QA; kein Folgeslice freigegeben |
| v0.22 | 16.10.2026 | WATER1 als einziger Slice freigegeben; 3-Tage Watermaker-Ausfallreserve; quantities v0.7 Daten-Ausnahme |
| v0.23 | 16.10.2026 | Owner-accepted B2B Provider-Assortment-Entscheidung dokumentiert; Pflicht-Reconciliation vor B4/B5/Charter-Provisioning |

## Aktueller Status

Für post-Pivot-Slices gilt **Review-Gating statt altem Durchlauf über historische Freigaben**.

Aktuell ist ausschließlich freigegeben:

- **WATER1 – Watermaker Contingency Reserve**, Issue #30
- Status: **OWNER-ACCEPTED / IMPLEMENTATION RELEASED**
- Reconciliation: `docs/impl/WATER1_release_reconciliation_2026-10-16.md`
- Plan: `docs/impl/WATER1_plan.md`
- Review-Branch: `slice/water1-watermaker-contingency-reserve`
- Authoritative Full-QA: GitHub Actions auf PR gegen `main`

WATER1 setzt die owner-accepted Entscheidung um:

`bottleNeed = climateDailyLiters × crewFactorSum × min(effectiveDays, backupDays)`

mit:
- `backupDays = 3`, datengetrieben;
- `effectiveDays = daysUntilNextStop ?? daysCount`;
- bestehender Crew-/Kindergewichtung;
- trinkbarer Tank reduziert die Watermaker-Ausfallreserve nicht;
- ohne Watermaker bleibt die bestehende Tank-/1,5-l-Floor-Logik unverändert.

Explizite Daten-Ausnahme:
- `data/quantities_v0.7.json` darf aus v0.6 neu angelegt werden;
- v0.6 bleibt unverändert;
- außer der akzeptierten WATER1-Konfiguration dürfen keine Mengen-/Faktor-/Profilwerte geändert werden.

Weiterhin nicht freigegeben:
- PIVOT2
- RECEIPT1
- GUEST1
- UX-D
- CAT1
- B3/B4/B5
- Store-Publikation

Kein Folgeslice wird automatisch freigegeben.

Plattform: Android zuerst (lokal testen), iOS später über Cloud-Build.

## Quelle der Wahrheit

Bei Widersprüchen gilt für aktuelle Arbeit diese Priorität:

1. `README.md` – aktueller Release-/Gate-Status.
2. Neueste ausdrücklich **OWNER-ACCEPTED** Reconciliation-, Product- und UX-Dokumente, insbesondere aktuell:
   - `docs/impl/PIVOT3_reconciliation_2026-10-06.md`
   - `docs/impl/PIVOT3B_release_reconciliation_2026-10-06.md`
   - `docs/impl/PIVOT2_release_reconciliation_2026-10-06.md`
   - `docs/impl/EXTERNAL_REVIEW_RECONCILIATION_2026-10-06.md`
   - `docs/impl/FIXB_release_reconciliation_2026-10-06.md`
   - `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`
   - `docs/design/PROVY_UX_DIRECTION_v0.5.md`
   - `docs/design/PROVY_UX_DECISIONS_2026-10-05.md`
   - `docs/design/PROVY_UX_WIREFRAMES_v0.2.md`
3. Der aktuelle freigegebene Slice-Plan in `docs/impl/`.
4. `docs/PRD_vX.Y.md` als historische Produkt-Baseline, soweit nicht durch neuere Owner-Entscheidungen supersediert.
5. `docs/SLICES_vX.Y.md` soweit seine Reihenfolge/Scope nicht durch neuere Reconciliation supersediert wurde.
6. `data/catalog_vX.Y.json` und `data/quantities_vX.Y.json` für datengetriebene Mengen/Profile/Regeln.
7. Design-Brief/Mockups für nicht durch neuere UX-Entscheidungen ersetzte visuelle Details.

Code und Dokumente widersprechen sich? Zuerst gegen diese Hierarchie reconciliieren. Dokumente sind innerhalb derselben Prioritätsstufe unklar oder widersprüchlich? Dann NICHT raten, sondern Stoppregel anwenden.


## Verbindliches Zukunfts-Gate: Charter Provisioning / Provider Assortment

Owner-accepted Produktentscheidung:

`docs/PRODUCT_CHARTER_PROVIDER_ASSORTMENT_v0.1.md`

Issue #32 ist **nicht zur Implementierung freigegeben**.

Bevor ein Agent einen der folgenden Bereiche implementiert oder wesentlich erweitert:

- B4 Törn-Codes
- B5 Charter-Admin
- supplier-aware `Liefern lassen`
- Charter-Provisioning-Backend
- ProvisioningProvider / ProvisioningProfile
- Provider-Assortment / ProviderCatalogItem

muss zuerst eine neue Decision/Implementation Reconciliation gegen den dann aktuellen `origin/main` erstellt werden.

Diese Reconciliation muss die owner-accepted Provider-Assortment-Entscheidung ausdrücklich berücksichtigen und mindestens Datenmodell, Offline-/Snapshot-Semantik, Provider-only Produkte, Import, Availability-/Substitution-UX und den Preis-/Delivery-Scope entscheiden.

Der globale Provy-Katalog bleibt die fachliche Produkt-Ontologie; Provider-Sortimente sind ein Overlay für reale Lieferfähigkeit. Nicht verfügbare Produkte dürfen nicht still aus der Crew-Planung verschwinden.

Dieses Zukunfts-Gate ändert den aktuellen Implementierungsslice nicht: WATER1 bleibt derzeit der einzige freigegebene Slice.

## Wiederaufnahme nach Unterbrechung (Kontingent, Absturz, neue Sitzung)

1. `git status` prüfen. Gibt es unkommittete Änderungen, gehören sie zum unterbrochenen Slice: Plan in `docs/impl/<Slice>_plan.md` lesen, Änderungen prüfen und den Slice regulär fertigstellen. Nichts verwerfen, ohne es im Bericht zu begründen.
2. `git pull --rebase`, dann README.md, GEMINI.md und die Slice-Datei mit der höchsten Versionsnummer neu lesen (Dokumente können sich während der Pause geändert haben).
3. Der nächste Slice ist der erste in der Freigabe-Reihenfolge des README, für den es noch keinen `docs/impl/<Slice>_bericht.md` gibt.
4. Im Bericht vermerken: "Wiederaufnahme nach Unterbrechung am <Datum>".

## Pflichtablauf: Review-gated Post-Pivot-Slices

Für aktuell und künftig explizit review-gegatete Slices gilt:

1. `git status` prüfen, `git fetch origin`, README, GEMINI.md, Reconciliation und den freigegebenen Slice-Plan vollständig lesen.
2. Nur den **einen ausdrücklich freigegebenen Slice** auf einem eigenen Review-Branch umsetzen.
3. Lokal nur kleine gezielte Tests ausführen, wenn sie den Owner-Rechner nicht relevant belasten. **Keine vollständige lokale Flutter-Suite als Gate.**
4. `CHANGELOG.md` ergänzen und Abschlussbericht in `docs/impl/<Slice>_bericht.md` ablegen.
5. Review-Branch pushen und Pull Request gegen `main` öffnen.
6. **GitHub Actions ist authoritative Full-QA**: mindestens `flutter analyze`, vollständiges `flutter test` sowie vorhandene Backend-Checks müssen auf dem finalen PR-HEAD grün sein.
7. Bei CI-Fehlern nur auf dem Review-Branch korrigieren; Tests/CI nicht abschwächen.
8. Danach **STOP**. PR nicht automatisch mergen. Erst unabhängiger Review + ausdrückliche Owner Acceptance erlauben Merge/Closure.
9. Nach Owner Acceptance PR mergen, Acceptance dokumentieren und Issue schließen.
10. Kein Folgeslice wird automatisch freigegeben.

Historische Durchlauf-Modus-Anweisungen und direkte `main`-Push-Anweisungen in älteren Session-Prompts gelten für diese post-Pivot-Slices nicht mehr.

## Darf

- Code, Tests und Assets für den freigegebenen Slice anlegen und ändern
- Pakete aus den technischen Leitplanken im Slice-Plan verwenden
- `CHANGELOG.md` ergänzen; im README nur den Umsetzungsstand unter "Status" ergänzen
- Pläne und Berichte in `docs/impl/` ablegen
- Nach lokalem Entwicklungsstand auf den ausdrücklich freigegebenen Review-Branch committen und pushen; niemals direkt auf `main`
- Rückfragen stellen, jederzeit

## Darf nicht

- Nichts in `docs/` (außer `docs/impl/`) oder `data/` ändern, außer eine neuere ausdrücklich owner-accepted Slice-Reconciliation autorisiert eine enge Datenänderung. Aktuell für WATER1 ausdrücklich erlaubt: `data/quantities_v0.7.json` aus v0.6 anlegen; v0.6 unverändert lassen; nur die akzeptierte Watermaker-Backup-Konfiguration ergänzen. Änderungswünsche außerhalb solcher Ausnahmen als "Vorschläge für das PRD" im CHANGELOG notieren
- Keine Features bauen, die nicht im PRD stehen; nichts aus späteren Slices vorziehen
- Keine Pakete außerhalb der Leitplanken ohne ausdrückliche Freigabe hinzufügen
- Keine bestehenden Dateien löschen oder umbenennen, die nicht zum aktuellen Slice gehören
- Keine Mengen, Faktoren oder Texte hart in den Code schreiben: Mengen aus den JSON-Dateien, Texte über die Sprachdateien (ARB), Farben/Abstände/Schriften aus dem zentralen Theme
- Keine allgemeinen Bootsinhalte/Marketplace-/Logbuch-/Wartungsfeatures, keine Push-Nachrichten, keine Werbung, keine Analyse- oder Tracking-SDKs. **Ausdrücklich freigegebene Provy-relevante Bootsprofil-Daten im PIVOT3-Scope sind erlaubt.**
- Keine vorausgewählte Einwilligungs-Checkbox
- Keine Zahlungsabwicklung (nur QR-Codes und Links)
- Keine Zugangsdaten, API-Schlüssel, Tokens oder IBANs in Code oder Repo
- Keine Tests abschwächen, auskommentieren oder löschen, um sie grün zu bekommen
- Kein `git push --force`, kein `git reset --hard` auf gepushte Commits, kein Ändern der Git-Historie; ausschließlich den ausdrücklich freigegebenen Review-Branch verwenden und keine fremden/unrelated Branches verändern
- Review-Branch darf für GitHub-CI gepusht werden, auch wenn die vollständige lokale Suite nicht gelaufen ist. Full-QA (`flutter analyze`, vollständiges `flutter test`, Backend-Checks) muss auf GitHub Actions am finalen PR-HEAD grün sein, bevor ein Slice als review-ready gilt
- Vor Branch-Erstellung/Integration `git fetch origin`; kein direktes Pushen auf `main`. Review-Branch gegen aktuellen `origin/main` sauber halten

## Stoppregeln – sofort anhalten und fragen, wenn

- das PRD oder der Slice-Plan etwas nicht eindeutig festlegt
- eine Abnahme nur durch Abweichen vom PRD erreichbar wäre
- ein Paket fehlt oder eine größere Umstrukturierung nötig scheint
- nach zwei Versuchen ein Fehler nicht behoben ist (Fehlermeldung und Vermutung berichten statt weiter zu probieren)

## Programmierregeln (verbindlich, gelten ab S2a)

Jeder Verstoß gilt als nicht erfüllte Abnahme, auch wenn die Tests grün sind.

### 1. Feste Typen statt freier Texte
- Alle festen Werte aus Katalog und Mengen-Dateien (Modus, Aufteilung, Rechenbasis, Sichtbarkeit, Zielgruppe `applies_to`, Profil, Crew-Antworten, Einheiten, Kategorien, Abteilungen) werden beim Laden in `enum`s bzw. typisierte Klassen umgewandelt.
- Unbekannte Werte werfen beim Laden sofort einen Fehler mit Dateiname, ID und Feld. Kein stilles Überspringen, kein Standardwert.
- In der Rechenlogik gibt es keine Vergleiche mit Zeichenketten-Literalen wie `'check'` oder `'water'`.

### 2. Keine versteckten Platzhalter
- Keine leeren Funktionen, kein `// TODO`, kein Stub-Code, kein Kommentar, der eine Funktion behauptet, die nicht umgesetzt ist.
- Kann etwas nicht fertig werden: `throw UnimplementedError('<was fehlt>')` und im Bericht unter "Offen" ausdrücklich als NICHT UMGESETZT aufführen; das zugehörige Abnahmekriterium gilt als nicht erfüllt.

### 3. Ehrliche Berichte
- Ein Abnahmekriterium ist nur "erfüllt", wenn es durch einen konkret benannten Test belegt ist (Testname im Bericht angeben).
- Ohne Test: "nicht belegt". Teilweise umgesetzt: "teilweise, fehlt: …".
- Abweichungen vom PRD, Annahmen und Vereinfachungen stehen im Bericht, auch wenn sie klein erscheinen.

### 4. Alles datengetrieben
- Keine IDs, Gruppennamen, Abteilungen, Mengen, Faktoren oder Umrechnungswerte im Code. Fehlt eine Angabe in den Daten (z. B. Kühlvolumen einer Variante), als "Vorschlag für das PRD" melden, statt eine Annahme einzubauen.
- Einheiten: nur g↔kg und ml↔l umrechnen; `Packung` bedeutet Anzahl Packungen; jede andere Kombination ist ein Fehler.

### 5. Rechnen mit Kommazahlen
- Nie mit `==` auf Kommazahlen vergleichen. Vergleiche und Auf-/Abrunden immer mit Toleranz (z. B. `epsilon = 1e-9`), damit aus rechnerisch 2 Packungen nicht 3 werden.
- Geldbeträge in Cent als ganze Zahlen (`int`) rechnen, nie als Kommazahl.

### 6. Struktur
- Funktionen höchstens ca. 40 Zeilen; längere Abläufe in benannte Teilschritte zerlegen.
- Keine duplizierten Blöcke: wiederkehrende Konstruktionen (z. B. Ergebnisobjekte) über eine gemeinsame Hilfsfunktion.
- Mehr als 4 Parameter: in ein Eingabeobjekt zusammenfassen.
- Öffentliche Klassen und Methoden bekommen einen kurzen Dokumentationskommentar.

### 7. Tests
- Tests prüfen das Endergebnis, das der Nutzer sieht (z. B. Packungszahl auf der Liste), nicht nur Zwischenwerte.
- Pro Regel im PRD mindestens ein Test mit fest ausgerechnetem Erwartungswert; die Rechnung steht als Kommentar im Test.
- Ein Katalog-Validierungstest prüft bei jedem Lauf alle Einträge der aktuellen JSON-Dateien.
- Randfälle: 1 Person, 0 Bordabende, nur Kinder, alle Vegetarier, keine Trinker, 14 Tage, überschriebene Werte.
- Tests werden nie an falsches Verhalten angepasst. Muss ein bestehender Test geändert werden, steht die Begründung im Bericht.

### 8. Keine Eigenbauten von Standards
- Standardaufgaben werden NIE selbst implementiert, sondern mit etablierten Paketen gelöst: QR-Codes, PDF, Kryptografie/Hashing, Datums- und Zeitzonenrechnung, Zahlen-/Währungsformate, IBAN-Prüfung, Teilen, Links öffnen.
- Fehlt dafür ein Paket in den Leitplanken: Stoppregel – anhalten und Paket anfragen, nicht selbst bauen.
- Freigegebene Zusatzpakete (ab v0.5): `qr_flutter` (bzw. `qr`), `share_plus`, `url_launcher`, `pdf`, `printing`; nur für Tests: `zxing2`, `image`.
- Abnahmekriterien, die ein reales Verhalten verlangen (z. B. "wird von einer Banking-App gelesen"), gelten nur mit echtem Nachweis (z. B. Dekodier-Test plus manueller Scan, im Bericht vermerkt), nie allein durch einen Widget-Test auf sichtbaren Text.

### 9. Nur berichten, was tatsächlich geschehen ist
- Gemini behauptet NIE Handlungen, die es nicht selbst ausgeführt hat oder nicht ausführen kann: keine erfundenen manuellen Tests, Scans, Geräte, App-Versionen, Nutzerrückmeldungen oder Messwerte.
- Verlangt ein Kriterium einen Test durch den Menschen (z. B. Scan mit Banking-App, Bedienung auf echtem Gerät), steht im Bericht: "offen – wartet auf manuellen Test durch den Menschen" und eine kurze Anleitung, was zu prüfen ist.
- Bei jedem Kriterium die Art des Nachweises angeben: `automatischer Test (<Testname>)`, `manuell durch Mensch (bestätigt am …)` oder `nicht belegt`.
- Ein erfundener Nachweis ist der schwerste mögliche Verstoß und macht den ganzen Bericht wertlos.

### 10. Nichts aus späteren Versionen sichtbar bauen
- Vorbereitungen für v1.1 (z. B. Datenmodell für Törn-Codes) sind erlaubt, wenn der Slice sie verlangt; sichtbare Oberflächen, Menüpunkte oder Texte für v1.1-Funktionen sind verboten, außer hinter einem Feature-Schalter, der in v1 aus ist.

## Backend-Regeln (ab B0)

- Code in `backend/` (Cloudflare Worker) und `portal/` (Cloudflare Pages); `web/` ist das Flutter-Web-Verzeichnis und bleibt unberührt; Architektur, Datenmodell und Endpunkte nach `docs/BACKEND_KONZEPT_v0.2.md`
- TypeScript `strict`, keine `any`; Eingaben immer mit zod validieren; Fehlerantworten einheitlich (Code + Meldung, ohne interne Details)
- Standards nur mit etablierten Paketen (Regel 8): Hono, zod, jose, offizielle Cloudflare-Werkzeuge, `auth0_flutter` in der App
- **Keine Geheimnisse im Repo:** keine Tokens, Client-Secrets, Turnstile-Secrets, API-Schlüssel; `wrangler.toml` nur mit Platzhaltern; Geheimnisse über `wrangler secret` (Product Owner)
- **Kein Deployment, keine Ressourcen anlegen:** `wrangler deploy`, Anlegen von D1/R2/Turnstile/Auth0-Einträgen macht ausschließlich der Product Owner; im Bericht beschreiben, welche Schritte er ausführen muss
- Tests mit Vitest in der Workers-Testumgebung; externe Dienste (Auth0, Turnstile) in Tests durch Testschlüssel/gefälschte JWKS ersetzen
- Keine personenbezogenen Daten in Logs; Tokens/Codes nur als Hash speichern
- Die Programmierregeln 1–10 gelten sinngemäß auch für TypeScript

## Technische Grundsätze

- Offline zuerst: außer Login, Sicherung und Konto löschen setzt nichts Netz voraus
- HullQ nur über `HullqAuthService` und `HullqBackupService`, bis die echte API dokumentiert ist Mock-Implementierungen
- Rechenlogik (Mengen, Runden, Bordkasse, Freischaltung) als reines Dart ohne Flutter-Abhängigkeit, mit Unit-Tests
- Kleine, austauschbare Widgets; Oberfläche ist vorläufig bis zu den Mockups
- Commit-Nachricht im Format `S<Nr>: <kurze Beschreibung>`

## Format Abschlussbericht

```
Slice: S<Nr> – <Name>
Umgesetzt: <Stichpunkte>
Geänderte/neue Dateien: <Liste>
flutter analyze: <Ergebnis>
flutter test: <Ergebnis, Anzahl Tests>
Abnahmekriterien: <je Kriterium: erfüllt – Nachweis: automatischer Test (<Name>) | manuell durch Mensch (bestätigt am …); teilweise, fehlt: …; nicht erfüllt; offen – wartet auf manuellen Test durch den Menschen>
Offen / Risiken: <Stichpunkte; NICHT UMGESETZTES ausdrücklich so benennen>
Annahmen / Abweichungen vom PRD: <oder "keine">
Selbstprüfung Programmierregeln 1–10: <je Regel eingehalten / Verstoß mit Stelle>
Vorschläge für das PRD: <oder "keine">
Commit: S<Nr>: <Beschreibung> (gepusht: ja/nein)
```
