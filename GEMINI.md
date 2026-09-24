# Arbeitsanleitung für Gemini (Docs-to-Code) – v0.4

Diese Datei liest du zu Beginn JEDER Sitzung vollständig, bevor du etwas anderes tust.

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung |
| v0.2 | 23.09.2026 | Klare Regeln "Darf / Darf nicht", Pflichtablauf pro Sitzung, Stoppregeln, Berichtsformat |
| v0.3 | 23.09.2026 | Durchlauf-Modus: alle freigegebenen Slices nacheinander ohne Freigabe pro Plan; Commit und Push auf main nach jedem grünen Slice; Review erst am Ende |
| v0.4 | 24.09.2026 | Gehärtete Programmierregeln nach Review S2: feste Typen, keine versteckten Platzhalter, ehrliche Berichte, datengetrieben, Kommazahlen mit Toleranz, Testregeln |

## Aktueller Status

Nur Slices bearbeiten, die im README unter "Freigegeben für Gemini" stehen. Aktuell: S0 bis S6 und S2a. S2a hat Vorrang und wird als nächstes umgesetzt (Review: docs/impl/REVIEW_S2_v0.1.md), danach S-UI. Für alle Oberflächen gelten docs/design/DESIGN_BRIEF_v0.3.md und die Mockups.
Mengen sind vorläufig (nur aus den JSON-Dateien lesen), die Oberfläche ist vorläufig bis zu den Mockups.
Plattform: Android zuerst (lokal testen), iOS später über Cloud-Build.

## Quelle der Wahrheit

Es gilt jeweils die Datei mit der HÖCHSTEN Versionsnummer:

1. `docs/PRD_vX.Y.md` – WAS gebaut wird
2. `docs/SLICES_vX.Y.md` – Reihenfolge, Umfang und Abnahmekriterien je Slice
3. `data/catalog_vX.Y.json` und `data/quantities_vX.Y.json` – alle Mengen, Profile, Regeln
4. `docs/design/DESIGN_BRIEF_vX.Y.md` (verbindliche Designregeln) und `docs/design/mockups/` (Vorlage für Layout; Texte daraus nie wörtlich übernehmen) – Gestaltung

Code und Dokumente widersprechen sich? Dann gelten die Dokumente. Dokumente sind unklar oder widersprüchlich? Dann NICHT raten, sondern stoppen und nachfragen.

## Pflichtablauf: Durchlauf-Modus

Alle freigegebenen Slices werden der Reihe nach abgearbeitet (S0, S1, S2 …), ohne auf eine Freigabe pro Plan zu warten. Das Review erfolgt am Ende gesammelt; Korrekturen kommen danach als Nachtrag.

Pro Slice:

1. Den Abschnitt des Slices im Slice-Plan lesen, Plan kurz in `docs/impl/S<Nr>_plan.md` festhalten (betroffene Dateien, Vorgehen, Prüfung der Abnahmekriterien). Nur dieser Ordner `docs/impl/` darf unter `docs/` beschrieben werden.
2. Umsetzen – ausschließlich diesen Slice.
3. Prüfen: `flutter analyze` ohne Fehler, `flutter test` grün.
4. `CHANGELOG.md` ergänzen und den Abschlussbericht (Format unten) in `docs/impl/S<Nr>_bericht.md` ablegen.
5. Nur wenn Analyse und Tests grün sind: committen mit `S<Nr>: <kurze Beschreibung>` und `git push` auf `main`.
6. Mit dem nächsten freigegebenen Slice weitermachen.

Greift eine Stoppregel, wird der Durchlauf beendet: Stand committen und pushen nur, wenn Analyse und Tests grün sind; sonst nichts pushen und berichten.

## Darf

- Code, Tests und Assets für den freigegebenen Slice anlegen und ändern
- Pakete aus den technischen Leitplanken im Slice-Plan verwenden
- `CHANGELOG.md` ergänzen; im README nur den Umsetzungsstand unter "Status" ergänzen
- Pläne und Berichte in `docs/impl/` ablegen
- Nach grünem Slice committen und auf `main` pushen
- Rückfragen stellen, jederzeit

## Darf nicht

- Nichts in `docs/` (außer `docs/impl/`) oder `data/` ändern. Änderungswünsche als "Vorschläge für das PRD" im CHANGELOG notieren
- Keine Features bauen, die nicht im PRD stehen; nichts aus späteren Slices vorziehen
- Keine Pakete außerhalb der Leitplanken ohne ausdrückliche Freigabe hinzufügen
- Keine bestehenden Dateien löschen oder umbenennen, die nicht zum aktuellen Slice gehören
- Keine Mengen, Faktoren oder Texte hart in den Code schreiben: Mengen aus den JSON-Dateien, Texte über die Sprachdateien (ARB), Farben/Abstände/Schriften aus dem zentralen Theme
- Keine Bootsinhalte, keine Push-Nachrichten, keine Werbung, keine Analyse- oder Tracking-SDKs
- Keine vorausgewählte Einwilligungs-Checkbox
- Keine Zahlungsabwicklung (nur QR-Codes und Links)
- Keine Zugangsdaten, API-Schlüssel, Tokens oder IBANs in Code oder Repo
- Keine Tests abschwächen, auskommentieren oder löschen, um sie grün zu bekommen
- Kein `git push --force`, kein `git reset --hard` auf gepushte Commits, kein Ändern der Git-Historie, keine anderen Branches
- Nichts pushen, solange `flutter analyze` oder `flutter test` nicht grün sind
- Vor jedem Push `git pull --rebase`, damit Dokumenten-Updates nicht überschrieben werden

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
Abnahmekriterien: <je Kriterium: erfüllt (Testname) / teilweise, fehlt: … / nicht erfüllt / nicht belegt>
Offen / Risiken: <Stichpunkte; NICHT UMGESETZTES ausdrücklich so benennen>
Annahmen / Abweichungen vom PRD: <oder "keine">
Selbstprüfung Programmierregeln 1–7: <je Regel eingehalten / Verstoß mit Stelle>
Vorschläge für das PRD: <oder "keine">
Commit: S<Nr>: <Beschreibung> (gepusht: ja/nein)
```
