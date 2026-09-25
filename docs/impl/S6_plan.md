# Implementierungsplan Slice S6 – Freischaltungslogik

## 1. Ziel und Umfang
Gemäß `SLICES_v0.12.md` und `PRD_v0.16.md`:
- **Reine Dart-Logik `Entitlements`:**
  - Drei Stufen: `Probetörn` (`trial`), `Mitglied` (`member` via HullQ-Login), `Pro` (`pro` via Abo / Mock bis v1.1).
  - Jede Zeile der PRD-Funktionstabelle wird typisiert als `AppFeature` abgebildet:
    1. Anzahl Törns (Probetörn: 1, Mitglied: unbegrenzt, Pro: unbegrenzt)
    2. Crewgröße (alle: unbegrenzt)
    3. Vorratsliste aus dem Katalog (alle: ja)
    4. Konsumprofile pro Person (alle: ja)
    5. Mengen überschreiben, Gesamtzahl, eigene Positionen (alle: ja)
    6. Einkaufsliste nach Supermarkt-Abteilung (alle: ja)
    7. Einlagerungs-Checkliste (alle: ja)
    8. Essgewohnheiten der Crew (alle: ja)
    9. Bordkasse und Kostenteilung (alle: ja)
    10. Export Einkaufsliste und Abrechnung (alle: ja)
    11. Sicherung, Wiederherstellung, mehrere Geräte (Probetörn: nein, Mitglied: ja, Pro: ja)
    12. Teilen mit der Crew ab v1.1 (Probetörn: nein, Mitglied: ja, Pro: ja)
    13. Menüplan ab v1.1 (alle: ja)
    14. Mehrere Währungen in der Bordkasse (Probetörn: ja, Mitglied: nein, Pro: ja)
    15. Eigene Rezepte und Mengen speichern (Probetörn: ja, Mitglied: nein, Pro: ja)
    16. Vorlagen aus früheren Törns (Probetörn: entfällt, Mitglied: nein, Pro: ja)
- **Erweiterbarkeit für zeitlich begrenzte Freischaltung / Törn-Code (v1.1):**
  - Datenmodell `TripCodePass` (Code, Törn-ID, Gültig bis, Freigabestufe) direkt in der Engine integriert, ohne Umbau nutzbar.
- **Integration und UI:**
  - `SC-ACC-01`: Freischalten-Dialog / Bottom Sheet ("Weiteren Törn planen" / "Mit HullQ-Konto anmelden").
  - StartScreen (SC-HOME-01): Wenn Probetörn verbraucht ist (bereits 1 Törn vorhanden und Status trial), öffnet der FAB "+ Neuer Törn" den Freischalten-Dialog `SC-ACC-01` statt des Setup-Assistenten.
  - Checkbox "Ja, ich möchte über den aktuellen Bootsmarkt informiert werden" ist standardmäßig IMMER unmarkiert (Designregel 4).

## 2. Betroffene Dateien
### Zu erstellende / zu ändernde Dateien
- `lib/features/entitlements/domain/entitlements.dart`:
  - `EntitlementLevel` Enum (`trial`, `member`, `pro`).
  - `AppFeature` Enum für alle 16 Tabellenzeilen.
  - `TripCodePass` Klasse für zeitlich begrenzte / törnbezogene Freischaltung.
  - `EntitlementsManager` reine Dart-Klasse zur Ermittlung der Freischaltung.
- `lib/features/entitlements/data/entitlements_service.dart` & `entitlements_providers.dart`:
  - Riverpod Provider zur Abfrage des aktuellen Status und Törn-Zählers.
- `lib/features/entitlements/ui/unlock_sheet.dart` (SC-ACC-01):
  - Freischalten-Sheet mit HullQ-Optionen (Google, Apple, E-Mail), Törn-Code-Eingabe, leerer Checkbox und Powered-by-HullQ.
- `lib/features/home/ui/start_screen.dart`:
  - Einbindung des Freischalt-Checks beim Anlegen eines neuen Törns.
- `lib/l10n/app_de.arb` & `lib/l10n/app_en.arb`:
  - Lokalisierungsstrings für SC-ACC-01.

### Tests
- `test/features/entitlements/entitlements_test.dart`:
  - Unit-Tests für **jede einzelne Zeile** der PRD-Funktionstabelle (16 Zeilen x 3 Stufen).
  - Test für den 2. Törn im Probetörn (Sperre greift).
  - Test für zeitlich begrenzte Törn-Codes (`TripCodePass`) und Ablauf-Prüfung.
- `test/features/entitlements/unlock_ui_test.dart`:
  - Widget-Tests für SC-ACC-01 in Hell, Dunkel und Nachtwache.
  - Prüfung der unmarkierten Einwilligungs-Checkbox.
  - Prüfung, dass FAB auf StartScreen bei verbrauchtem Probetörn SC-ACC-01 öffnet.

## 3. Prüfung der Abnahmekriterien (SLICES_v0.12.md)
1. **Funktionstabelle PRD:** Unit-Tests decken jede Zeile der Tabelle im PRD ab.
2. **Zweiter Törn:** Der zweite Törn zeigt den Freischalten-Dialog (SC-ACC-01).
3. **Zukunftssicherheit:** Das Modell erlaubt zeitlich begrenzte Freischaltung pro Törn (Törn-Code, v1.1) ohne Umbau.
4. **Programmierregeln 1–7 & Designregeln 1–13:**
   - Feste Enums (`EntitlementLevel`, `AppFeature`).
   - Keine stummen Platzhalter oder unfertigen Stubs.
   - Reines Dart ohne Flutter-Abhängigkeit für die Engine.
   - Unmarkierte Checkbox nach Designregel 4.
