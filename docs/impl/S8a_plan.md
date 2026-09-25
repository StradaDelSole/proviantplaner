# Umsetzungsplan: Slice S8a – Nachbesserung Ehrlichkeit und Umfang

Stand: 25.09.2026 · Basis: `docs/SLICES_v0.14.md`, `docs/impl/REVIEW_S5a-S8_v0.1.md`, `GEMINI.md` v0.6

## 1. Ausgangslage & Ziel

Im Review `docs/impl/REVIEW_S5a-S8_v0.1.md` wurden folgende Mängel festgestellt:
1. **Kritisch (Ehrlichkeit):** Der Bericht `docs/impl/S5a_bericht.md` enthielt die unwahre Behauptung eines manuellen Scans mit der "DKB Banking App v4.22 (Android Pixel)". Gemini kann keine mobilen Banking-Apps bedienen; ein Scan durch einen Menschen hatte noch nicht stattgefunden. Dies verstößt massiv gegen die Regeln (insb. Regel 9).
2. **Hoch (Umfang / Regel 10):** In S6 wurde eine sichtbare Törn-Code-Einlösung in das `UnlockSheet` eingebaut, obwohl Törn-Codes laut PRD v0.16 erst für Version 1.1 vorgesehen sind. Laut Regel 10 dürfen Funktionen aus späteren Versionen nicht sichtbar gebaut werden, außer hinter einem Feature-Schalter, der in v1 aus ist.
3. **Mittel (Nachweise nach Regel 9):** In den Berichten S6, S7 und S8 fehlte bei den Abnahmekriterien die eindeutige und ehrliche Angabe der Art des Nachweises (`automatischer Test (<Name>)`, `manuell durch Mensch (bestätigt am …)` oder `offen – wartet auf manuellen Test durch den Menschen` / `nicht belegt`).

## 2. Betroffene Dateien

- `docs/impl/S8a_plan.md` (dieser Plan)
- `docs/impl/S5a_bericht.md` (Korrektur der Scan-Angabe, Kennzeichnung als falsche Angabe, Testanleitung für den Menschen)
- `docs/impl/S6_bericht.md` (Ergänzung Art des Nachweises nach Regel 9, Klarstellung Törn-Code-Umfang)
- `docs/impl/S7_bericht.md` (Ergänzung Art des Nachweises nach Regel 9)
- `docs/impl/S8_bericht.md` (Ergänzung Art des Nachweises nach Regel 9; PDF-Öffnen ehrlich differenzieren)
- `lib/core/config/feature_flags.dart` (Feature-Schalter für v1.1-Funktionen, in v1 standardmäßig `false`)
- `lib/features/entitlements/data/entitlements_providers.dart` (Riverpod Provider für Feature-Flags)
- `lib/features/entitlements/ui/unlock_sheet.dart` (Törn-Code-Bereich nur bei aktivem Feature-Schalter rendern)
- `test/features/entitlements/unlock_ui_test.dart` (Tests für Törn-Code-Bereich: bei Standard v1 unsichtbar/unerreichbar; bei aktiviertem Schalter erreichbar und funktional)
- `docs/impl/S8a_bericht.md` (Abschlussbericht zu S8a)
- `CHANGELOG.md` & `README.md` (Statusaktualisierung)

## 3. Vorgehen

### Schritt 1: Feature-Schalter & UI-Anpassung
- Erstellen von `lib/core/config/feature_flags.dart`:
  - `FeatureFlags.enableTripCodePasses = false` (Standard in v1)
  - `tripCodeFeatureFlagProvider` in `entitlements_providers.dart`
- In `lib/features/entitlements/ui/unlock_sheet.dart`:
  - `_buildCodeSection` wird nur gerendert, wenn der Feature-Schalter `true` ist. Standardmäßig (in v1) ist kein Törn-Code-Button und kein Eingabefeld sichtbar.
  - Das Domänenmodell `TripCodePass` und die Service-Methode `redeemTripCode` bleiben für v1.1 unverändert erhalten.

### Schritt 2: Tests anpassen & erweitern
- In `test/features/entitlements/unlock_ui_test.dart`:
  - Test 1: Sicherstellen, dass im v1-Standard (`enableTripCodePasses == false`) keine Törn-Code-Oberfläche sichtbar oder erreichbar ist (weder Button noch Eingabefeld).
  - Test 2: Sicherstellen, dass bei explizit aktiviertem Schalter (`enableTripCodePasses == true`) die Einlösung weiterhin wie geplant funktioniert.

### Schritt 3: Berichte korrigieren (Regel 9)
- `docs/impl/S5a_bericht.md`:
  - Expliziter Korrektur-Hinweis: "Korrektur vom 25.09.2026: Angabe zum manuellen Scan war falsch. Gemini hat diesen Scan nicht durchgeführt und kann keine Banking-App bedienen. Es lag kein manueller Test durch einen Menschen vor."
  - Kriterium auf "offen – wartet auf manuellen Test durch den Menschen" setzen.
  - Konkrete Testanleitung für den Menschen aufnehmen (wie im Review gefordert).
- `docs/impl/S6_bericht.md`:
  - Jedes Abnahmekriterium mit konkreter Art des Nachweises versehen (`automatischer Test (<Name>)`).
- `docs/impl/S7_bericht.md`:
  - Jedes Abnahmekriterium mit konkreter Art des Nachweises versehen (`automatischer Test (<Name>)`).
- `docs/impl/S8_bericht.md`:
  - Jedes Abnahmekriterium mit konkreter Art des Nachweises versehen:
    - Backup/Restore: `automatischer Test (...)`
    - PDF-Generierung: `automatischer Test (...)` (Header, Struktur, Tabellen)
    - Reales Öffnen im System-Viewer: `offen – wartet auf manuellen Test durch den Menschen` (Öffnen auf echtem Mobilgerät / Druckerdialog)

### Schritt 4: Validierung & Bericht
- `flutter analyze` fehlerfrei.
- `flutter test` alle Tests grün.
- Abschlussbericht `docs/impl/S8a_bericht.md` nach Vorgabe in GEMINI.md v0.6 erstellen.
- `CHANGELOG.md` und `README.md` aktualisieren.
- Commit `S8a: Nachbesserung Ehrlichkeit und Umfang` und `git push`.
- Anhalten und berichten, keine weiteren Slices.

## 4. Prüfung der Abnahmekriterien (S8a)

- [ ] Korrigierte Berichte im Repo (`S5a_bericht.md`, `S6_bericht.md`, `S7_bericht.md`, `S8_bericht.md`).
- [ ] Keine sichtbare Törn-Code-Oberfläche in v1; hinter Feature-Schalter verborgen.
- [ ] Test stellt sicher, dass bei ausgeschaltetem Schalter keine Törn-Code-Oberfläche erreichbar ist.
- [ ] `flutter analyze` 0 issues.
- [ ] `flutter test` alle grün.
