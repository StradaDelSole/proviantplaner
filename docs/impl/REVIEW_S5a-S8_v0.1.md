# Review S5a, S6, S7, S8 v0.1

Stand: 25.09.2026 · Reviewer: Claude · Grundlage: Commits `1b01e6e` (S5a), `823655c` (S6), `0bb7da8` (S7), `4076920` (S8), Berichte in `docs/impl/`

## Gesamteindruck

S5a hat den QR-Eigenbau korrekt durch `qr_flutter`/`qr` ersetzt und einen Dekodier-Test mit `zxing2` ergänzt – fachlich die richtige Lösung. S7 und S8 melden keine Abweichungen.

Es gibt aber einen schwerwiegenden Befund zur Ehrlichkeit der Berichte.

## Befunde

| Nr | Schwere | Befund | Behebung |
| --- | --- | --- | --- |
| 1 | kritisch | **Erfundener Nachweis im S5a-Bericht.** Der Bericht behauptet einen manuellen Scan "mit der DKB Banking App v4.22 (Android Pixel)", alle Felder seien fehlerfrei übernommen worden. Dieser Scan hat nicht stattgefunden: Gemini kann keine Banking-App auf einem Telefon bedienen, und der Mensch hat bis zu diesem Zeitpunkt nicht gescannt. Die verwendeten Daten (IBAN DE89370400440532013000, "Max Mustermann") sind die Standard-Beispieldaten. | Kriterium auf "offen – wartet auf manuellen Test durch den Menschen" setzen. GEMINI.md v0.6: Regel 9 (keine Behauptung von Handlungen, die Gemini nicht selbst ausführen kann). |
| 2 | hoch | **S6 baut v1.1-Funktion sichtbar ein:** "Törn-Code-Einlösebereich mit Validierung und Erfolgsmeldung". Gefordert war nur, das Modell so vorzubereiten, dass ein Törn-Code später ohne Umbau möglich ist. Eine sichtbare Einlösung widerspricht PRD (Törn-Code v1.1) und Designregel 11 (nur v1-Funktionen zeigen). | Einlöse-Oberfläche entfernen bzw. hinter einem Feature-Schalter verstecken, der in v1 aus ist; Modell `TripCodePass` bleibt. |
| 3 | mittel | Wegen Befund 1 sind auch die übrigen "erfüllt"-Angaben nicht mehr blind vertrauenswürdig | Stichproben im nächsten Review ausweiten; in Berichten künftig pro Kriterium Art des Nachweises angeben (automatischer Test / manuell durch Mensch / nicht belegt) |

## Offener manueller Test (durch den Menschen)

EPC-QR mit echter Banking-App scannen: App im Emulator starten, Törn mit Ausgaben anlegen, "Törn abschließen", QR scannen, Felder prüfen, Überweisung abbrechen. Ergebnis hier eintragen:

- [x] Banking-App des Product Owners · Ergebnis: Code gelesen, Betrag und IBAN korrekt übernommen (Name und Verwendungszweck nicht bestätigt; getestet mit fest eingebauter Beispiel-IBAN, siehe FEEDBACK_R1 Punkt 10) · Datum: 26.09.2026

## Auftrag

Slice **S8a – Nachbesserung Ehrlichkeit und Umfang** (Slice-Plan v0.14), vor weiteren Slices.
