# Arbeitsanleitung für Gemini (Docs-to-Code) – v0.2

Diese Datei liest du zu Beginn JEDER Sitzung vollständig, bevor du etwas anderes tust.

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung |
| v0.2 | 23.09.2026 | Klare Regeln "Darf / Darf nicht", Pflichtablauf pro Sitzung, Stoppregeln, Berichtsformat |

## Aktueller Status

Nur Slices bearbeiten, die im README unter "Freigegeben für Gemini" stehen. Aktuell: S0 bis S6.
Mengen sind vorläufig (nur aus den JSON-Dateien lesen), die Oberfläche ist vorläufig bis zu den Mockups.
Plattform: Android zuerst (lokal testen), iOS später über Cloud-Build.

## Quelle der Wahrheit

Es gilt jeweils die Datei mit der HÖCHSTEN Versionsnummer:

1. `docs/PRD_vX.Y.md` – WAS gebaut wird
2. `docs/SLICES_vX.Y.md` – Reihenfolge, Umfang und Abnahmekriterien je Slice
3. `data/catalog_vX.Y.json` und `data/quantities_vX.Y.json` – alle Mengen, Profile, Regeln
4. `docs/design/DESIGN_BRIEF_vX.Y.md` und `docs/design/mockups/` – Gestaltung

Code und Dokumente widersprechen sich? Dann gelten die Dokumente. Dokumente sind unklar oder widersprüchlich? Dann NICHT raten, sondern stoppen und nachfragen.

## Pflichtablauf pro Sitzung

1. Diese Datei, das README und den Abschnitt des angefragten Slices lesen. Nur zusätzliche Dateien lesen, die der Slice wirklich braucht.
2. **Plan vorlegen und auf Freigabe warten:** betroffene Dateien, neue Pakete (falls nötig), Vorgehen, wie die Abnahmekriterien geprüft werden. Erst nach "OK" umsetzen.
3. Umsetzen – ausschließlich den freigegebenen Slice.
4. Prüfen: `flutter analyze` ohne Fehler, `flutter test` grün. Ergebnisse wörtlich berichten.
5. `CHANGELOG.md` ergänzen (Datum, Slice, Umgesetztes, Offenes, Vorschläge für das PRD).
6. Abschlussbericht im Format unten. Kein Commit und kein Push – das macht der Mensch.

## Darf

- Code, Tests und Assets für den freigegebenen Slice anlegen und ändern
- Pakete aus den technischen Leitplanken im Slice-Plan verwenden
- `CHANGELOG.md` ergänzen; im README nur den Umsetzungsstand unter "Status" ergänzen
- Rückfragen stellen, jederzeit

## Darf nicht

- Nichts in `docs/` oder `data/` ändern. Änderungswünsche als "Vorschläge für das PRD" im CHANGELOG notieren
- Keine Features bauen, die nicht im PRD stehen; nichts aus späteren Slices vorziehen
- Keine Pakete außerhalb der Leitplanken ohne ausdrückliche Freigabe hinzufügen
- Keine bestehenden Dateien löschen oder umbenennen, die nicht zum aktuellen Slice gehören
- Keine Mengen, Faktoren oder Texte hart in den Code schreiben: Mengen aus den JSON-Dateien, Texte über die Sprachdateien (ARB), Farben/Abstände/Schriften aus dem zentralen Theme
- Keine Bootsinhalte, keine Push-Nachrichten, keine Werbung, keine Analyse- oder Tracking-SDKs
- Keine vorausgewählte Einwilligungs-Checkbox
- Keine Zahlungsabwicklung (nur QR-Codes und Links)
- Keine Zugangsdaten, API-Schlüssel, Tokens oder IBANs in Code oder Repo
- Keine Tests abschwächen, auskommentieren oder löschen, um sie grün zu bekommen
- Kein `git commit`, `git push`, `git reset` oder Ändern der Git-Historie

## Stoppregeln – sofort anhalten und fragen, wenn

- das PRD oder der Slice-Plan etwas nicht eindeutig festlegt
- eine Abnahme nur durch Abweichen vom PRD erreichbar wäre
- ein Paket fehlt oder eine größere Umstrukturierung nötig scheint
- nach zwei Versuchen ein Fehler nicht behoben ist (Fehlermeldung und Vermutung berichten statt weiter zu probieren)

## Technische Grundsätze

- Offline zuerst: außer Login, Sicherung und Konto löschen setzt nichts Netz voraus
- HullQ nur über `HullqAuthService` und `HullqBackupService`, bis die echte API dokumentiert ist Mock-Implementierungen
- Rechenlogik (Mengen, Runden, Bordkasse, Freischaltung) als reines Dart ohne Flutter-Abhängigkeit, mit Unit-Tests
- Kleine, austauschbare Widgets; Oberfläche ist vorläufig bis zu den Mockups
- Commit-Vorschlag im Bericht im Format `S<Nr>: <kurze Beschreibung>`

## Format Abschlussbericht

```
Slice: S<Nr> – <Name>
Umgesetzt: <Stichpunkte>
Geänderte/neue Dateien: <Liste>
flutter analyze: <Ergebnis>
flutter test: <Ergebnis, Anzahl Tests>
Abnahmekriterien: <je Kriterium erfüllt / nicht erfüllt, mit Begründung>
Offen / Risiken: <Stichpunkte>
Vorschläge für das PRD: <oder "keine">
Commit-Vorschlag: S<Nr>: <Beschreibung>
```
