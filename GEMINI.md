# Arbeitsanleitung für Gemini (Docs-to-Code)

Diese Datei liest du zu Beginn jeder Sitzung, bevor du Code schreibst.

## Quelle der Wahrheit

1. `docs/PRD_vX.Y.md` mit der höchsten Versionsnummer beschreibt, WAS gebaut wird.
2. `docs/SLICES_vX.Y.md` mit der höchsten Versionsnummer beschreibt, in welcher Reihenfolge und mit welchen Abnahmekriterien.
3. `data/catalog_vX.Y.json` (Vorratskatalog) und `data/quantities_vX.Y.json` (Mengen und Profile), jeweils höchste Version, enthalten alle Mengenwerte. Werte niemals im Code hart codieren.

Wenn Code und Dokumente sich widersprechen, gelten die Dokumente. Wenn die Dokumente unklar oder widersprüchlich sind: nicht raten, sondern nachfragen.

## Aktueller Status

Nur Slices bearbeiten, die im README unter "Freigegeben für Gemini" stehen. Aktuell: S0 bis S6. Mengen sind vorläufig (nur aus den JSON-Dateien lesen), die Oberfläche ist vorläufig bis zu den Mockups.

Plattform: Android zuerst (lokal testen), iOS später über Cloud-Build.

## Arbeitsweise

- Pro Sitzung genau EIN Slice. Nenne zu Beginn den Slice (z. B. "S2 – Mengen-Engine") und fasse die Abnahmekriterien in eigenen Worten zusammen.
- Nur bauen, was im PRD steht. Keine zusätzlichen Features, keine Bootsinhalte, keine Push-Nachrichten, keine Werbung.
- Offline zuerst: Außer Login, Sicherung und Konto löschen darf nichts Netz voraussetzen.
- HullQ nur über die Interfaces `HullqAuthService` und `HullqBackupService` ansprechen, bis die echte API dokumentiert ist; bis dahin Mock-Implementierungen verwenden.
- Rechenlogik (Mengen, Bordkasse, Freischaltung) als reines Dart mit Unit-Tests.
- Am Ende jedes Slices: `flutter analyze` und `flutter test` ausführen und das Ergebnis berichten.

## Nach jedem Slice

- `CHANGELOG.md` im Repo-Root um einen Eintrag ergänzen: Datum, Slice, was umgesetzt wurde, offene Punkte.
- Commit-Nachricht im Format: `S<Nr>: <kurze Beschreibung>` (z. B. `S5: Bordkasse mit Ausgleichsberechnung`).
- Wenn dabei etwas am PRD geändert werden müsste: NICHT das PRD ändern, sondern den Vorschlag im CHANGELOG unter "Vorschläge für das PRD" notieren. Das PRD wird separat versioniert.

## Tabu

- Keine Zugangsdaten, API-Schlüssel oder Tokens in den Code oder ins Repo.
- Keine Analyse- oder Tracking-SDKs ohne ausdrückliche Anweisung.
- Keine vorausgewählte Einwilligungs-Checkbox.
