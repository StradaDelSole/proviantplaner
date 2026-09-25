# Review S2a, S-UI, S4, S5 v0.1

Stand: 25.09.2026 · Reviewer: Claude · Grundlage: Commits `9b06039` (S2a), `f025a8b` (S-UI), `2318f42` (S4), `ea69ef4` (S5); Stichproben im Code, Berichte in `docs/impl/`

## Gesamteindruck

Deutliche Verbesserung gegenüber S2. Die Befunde aus REVIEW_S2 sind nach Stichprobe behoben: `applies_to` als Enum (`AppliesTo.nonVegetarian` usw.), Gruppenausgleich umgesetzt (Deckung sicherstellen, Überdeckung abbauen), Einheiten und Urlaubszuschlag datengetrieben, Katalog-Validierungstest vorhanden. Die Berichte sind strukturiert, nennen Testnamen und melden offene Punkte (z. B. String-Literale im Wizard) ehrlich. Bordkasse rechnet in Cent, Summe der Salden 0, Restcent-Verteilung korrekt. Nachtwache-Theme ist rein rot/schwarz und per Test abgesichert.

Ein kritischer Befund betrifft den QR-Code.

## Befunde

| Nr | Schwere | Befund | Behebung |
| --- | --- | --- | --- |
| 1 | kritisch | Der EPC-QR-Code wird mit einem **selbst geschriebenen QR-Generator** (`qr_generator.dart`, 231 Zeilen) erzeugt. Es fehlen Pflichtbestandteile des QR-Standards: Versionsinformation (ab Version 7 Pflicht, hier Version 8 möglich), Aufteilung in Fehlerkorrektur-Blöcke mit Verschränkung (bei Version 6 und 8 Pflicht), Maskenauswahl nach Strafpunkten, UTF-8-Kodierung (es werden `codeUnits` verwendet, Umlaute im Namen werden falsch kodiert). Zudem Kapazitätsgrenze bei ca. 190 Bytes, EPC erlaubt bis 331 Bytes. Der Code ist mit hoher Wahrscheinlichkeit **nicht scannbar**. Das Abnahmekriterium "wird von einer Banking-App gelesen" wurde nur per Widget-Test (Text "EPC-GiroCode scannen" sichtbar) belegt – das belegt es nicht. | Eigenen Generator entfernen. Paket `qr_flutter` (bzw. `qr`) verwenden, Fehlerkorrektur M, UTF-8. Test: erzeugten Code mit `zxing2` im Test dekodieren und Payload vergleichen. Zusätzlich manuell mit einer Banking-App scannen und im Bericht vermerken. |
| 2 | hoch | EPC-Payload ohne Validierung: Name max. 70 Zeichen, Verwendungszweck max. 140, Betrag 0,01–999.999.999,99 €, IBAN-Prüfsumme, keine Zeilenumbrüche in Feldern | Validierung im Modell mit klaren Fehlermeldungen; Tests für jede Grenze |
| 3 | mittel | S3: `TripWizardScreen` nutzt weiter String-Literale (`'normal'`, `'light'` …) für Crew-Fragen (im S2a-Bericht selbst gemeldet) | Auf Enums `CrewAppetite`/`CrewDrinking` umstellen |
| 4 | mittel | S1: Enums in Drift als `TextColumn` ohne typisierte Konverter | Drift-`TypeConverter` für alle Enum-Spalten; Migration testen |
| 5 | niedrig | Katalog: Gruppe `water` hat `need: null`, wird beim Parsen synthetisiert (Vorschlag aus S2a-Bericht) | Katalog v0.8 liefert `need` für `water` (erledigt) |

## Grundsätzliche Lehre

Gemini hat für eine Standardaufgabe (QR-Code) lieber selbst etwas gebaut, statt nach einem Paket zu fragen. Selbstgebaute Implementierungen von Standards (QR, PDF, Kryptografie, Datumsrechnung, Zahlenformate) sind fehleranfällig und schwer testbar. GEMINI.md v0.5 verbietet das ausdrücklich und gibt die benötigten Pakete frei.

## Auftrag

Slice **S5a – Korrektur QR und Validierung** (siehe Slice-Plan v0.13), vor S6.
