# Abschlussbericht FIX-A: Navigation & Lifecycle Regression Repair

Slice: FIX-A – Navigation & Lifecycle Regression Repair
Umgesetzt:
- **Behebung Issue #11 (Einlagerung & Rücksprung):** Abschluss der Einlagerung in `StorageChecklistScreen` aktualisiert die `TripPhase` auf `underway` und navigiert deterministisch per `context.go('/trips/$tripId')` zurück zur Törn-Übersicht statt zum Listen-Editor.
- **Behebung Issue #12 (Bordkasse & Törnverlauf wieder erreichbar):** Direkte Einstiege in `TripOverviewScreen`: Button „Bordkasse öffnen“ führt zur vollen `KittyScreen`-Funktionalität (inkl. Kassenwart, Einzahlungen, Ausgaben, Beteiligungsmatrix); Button „Tagesleiste öffnen“ in der Tage-im-Detail-Sektion führt zu `TripTimelineScreen`.
- **Behebung Issue #13 (Lifecycle & Stepper-Logik):** `TripDao` und `TripService` um `setTripPhase` erweitert. Stepper-Berechnung in `TripOverviewScreen` (`_calculateCurrentStep`) orientiert sich an der persistierten `TripPhase` (plan, shopping, storage, underway, conclusion) und prüft echten Listenstand (`isAdopted || isCustom`), anstatt alle generierten Vorratsvorschläge fälschlicherweise als fertige Nutzerliste zu werten.
- **Behebung Issue #14 (Einkaufsabschluss: Später vs. Streichen):** `ShoppingListService.handleUnboughtItems` implementiert:
  - „Später“ (`postpone: true`): Verschiebt ungedeckte Mengen auf den nächsten Einkaufsstopp (legt Folgestopp an, falls noch keiner existiert) und passt Allokationen an.
  - „Streichen“ (`postpone: false`): Reduziert die Gesamtmenge der betroffenen Positionen bzw. entfernt sie aus der Liste (`isAdopted: false`).
- **Behebung Issue #15 (Törn-Details, Einkaufsstopps & Crew bearbeiten):**
  - `TripService.updateTripDetails`: Bearbeiten von Törn-Name, Startdatum, Reisedauer (`daysCount` mit automatischer Anpassung der `TripDays`), Kühl- und Gefrierkapazität sowie Wassertank und Trinkwasser-Eigenschaft inkl. sofortiger Mengen-Neuberechnung.
  - Dialog „Törn bearbeiten“ (`_showEditTripDialog`) in `TripOverviewScreen` bietet vollständiges Setup an.
  - Einkaufsstopp-CRUD (Hinzufügen, Umbenennen, Löschen mit Schutz des Initialstopps) direkt in der Törn-Übersicht.
  - Crew-Verwaltung (Hinzufügen, Bearbeiten, Löschen mit Schutz vor Leerung) direkt in der Törn-Übersicht.
- **Behebung Issue #18 (Konsistenter Routingvertrag):** Detail-Screens (`ShoppingListScreen`, `ShoppingModeScreen`, `StorageChecklistScreen`, `KittyScreen`, `SettlementScreen`, `TripTimelineScreen`) werden per `context.push()` geöffnet. App-Bar-Zurück-Buttons verwenden konsistenten Fallback `context.canPop() ? context.pop() : context.go('/trips/$tripId')` für sicheren Rückweg auch bei Direktaufruf oder isoliertem Stack.
- **Behebung Issues #16 & #17 (Lokalisierung & No-op-Kacheln):** Kacheln „Gemerkte Packungsgrößen“ und „Sprache“ in `MoreScreen` mit lokalisierten Strings und informativen Dialogen (`AlertDialog`) versehen. Lokalisierungen für alle 6 Sprachen nach UX-C-Regeln ergänzt.
- **Behebung Issue #19 (Automatisierte Journey- & Lifecycle-Tests):** Neue Testsuite `test/features/ux/fix_a_journey_test.dart` mit 6 End-to-End-Journey-Tests deckt alle 11 Punkte der Definition of Done ab.

Geänderte/neue Dateien:
- `lib/core/database/daos.dart`
- `lib/features/kitty/ui/kitty_screen.dart`
- `lib/features/kitty/ui/settlement_screen.dart`
- `lib/features/more/ui/more_screen.dart`
- `lib/features/shopping_list/data/shopping_list_service.dart`
- `lib/features/shopping_list/ui/shopping_list_screen.dart`
- `lib/features/shopping_list/ui/shopping_mode_screen.dart`
- `lib/features/shopping_list/ui/storage_checklist_screen.dart`
- `lib/features/trip/data/trip_service.dart`
- `lib/features/trip/ui/trip_overview_screen.dart`
- `lib/features/trip/ui/trip_timeline_screen.dart`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_hr.arb`
- `lib/l10n/app_pt.arb`
- `test/features/ux/fix_a_journey_test.dart` (neu)
- `docs/impl/FIX-A_bericht.md` (neu)
- `CHANGELOG.md`
- `README.md`

flutter analyze:
No issues found! (0 Fehler, 0 Warnungen)

flutter test:
235/235 Tests bestanden (6 neue Tests in `test/features/ux/fix_a_journey_test.dart`, alle bestehenden 229 Tests grün)

Abnahmekriterien (Definition of Done aus REGRESSION_AUDIT_2026-10-05):
1. Törn öffnen: erfüllt – Nachweis: automatischer Test (`1. Törn-Übersicht als zentraler Hub: Einstieg und Detail-Screen Navigation mit Rückweg` in `test/features/ux/fix_a_journey_test.dart`)
2. Törn bearbeiten: erfüllt – Nachweis: automatischer Test (`5. Issue #15: Törn-Details und Crew in TripService & TripOverviewScreen bearbeiten` in `test/features/ux/fix_a_journey_test.dart`)
3. Liste öffnen und zurück: erfüllt – Nachweis: automatischer Test (`1. Törn-Übersicht als zentraler Hub: Einstieg und Detail-Screen Navigation mit Rückweg` in `test/features/ux/fix_a_journey_test.dart`)
4. Einkauf starten: erfüllt – Nachweis: automatischer Test (`1. Törn-Übersicht als zentraler Hub: Einstieg und Detail-Screen Navigation mit Rückweg` und `4. Issue #14: Einkaufsabschluss mit unvollständigen Artikeln - Später vs. Streichen` in `test/features/ux/fix_a_journey_test.dart`)
5. offene Position wirklich verschieben oder streichen: erfüllt – Nachweis: automatischer Test (`4. Issue #14: Einkaufsabschluss mit unvollständigen Artikeln - Später vs. Streichen` in `test/features/ux/fix_a_journey_test.dart`)
6. Einlagerung abschließen: erfüllt – Nachweis: automatischer Test (`2. Issue #11: Einlagerung abschließen setzt Phase underway und navigiert deterministisch zur Übersicht` in `test/features/ux/fix_a_journey_test.dart`)
7. zur Törnübersicht gelangen: erfüllt – Nachweis: automatischer Test (`2. Issue #11: Einlagerung abschließen setzt Phase underway und navigiert deterministisch zur Übersicht` in `test/features/ux/fix_a_journey_test.dart`)
8. vollständige Bordkasse öffnen: erfüllt – Nachweis: automatischer Test (`1. Törn-Übersicht als zentraler Hub: Einstieg und Detail-Screen Navigation mit Rückweg` in `test/features/ux/fix_a_journey_test.dart`)
9. Abrechnung öffnen: erfüllt – Nachweis: automatischer Test (`1. Törn-Übersicht als zentraler Hub: Einstieg und Detail-Screen Navigation mit Rückweg` in `test/features/ux/fix_a_journey_test.dart`)
10. aus der Abrechnung korrekt zurück: erfüllt – Nachweis: automatischer Test (`1. Törn-Übersicht als zentraler Hub: Einstieg und Detail-Screen Navigation mit Rückweg` in `test/features/ux/fix_a_journey_test.dart`)
11. zweiten Einkaufsstopp anlegen/bearbeiten/löschen: erfüllt – Nachweis: automatischer Test (`5. Issue #15: Törn-Details und Crew in TripService & TripOverviewScreen bearbeiten` in `test/features/ux/fix_a_journey_test.dart`)
Zusatz Issues #16 & #17: MoreScreen Einstellungsdialoge für Packungsgrößen und Sprache: erfüllt – Nachweis: automatischer Test (`6. Issues #16 & #17: MoreScreen Einstellungsdialoge für Packungsgrößen und Sprache` in `test/features/ux/fix_a_journey_test.dart`)

Offen / Risiken:
- Keine. Der zentrale Törnflow und die Lifecycle-Verwaltung sind wieder vollständig konsistent und navigierbar.

Annahmen / Abweichungen vom PRD:
- keine.

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): eingehalten (`TripPhase` als festes Enum, typisierte Methoden).
- Regel 2 (Keine versteckten Platzhalter): eingehalten (alle Aktionen mit echter Domain- und Navigationslogik ausgeführt).
- Regel 3 (Ehrliche Berichte): eingehalten (alle Abnahmekriterien durch konkret benannte Tests belegt).
- Regel 4 (Alles datengetrieben): eingehalten (keine hartcodierten Werte).
- Regel 5 (Rechnen mit Kommazahlen): eingehalten (saubere Rundung bei Allokationen und Mengen).
- Regel 6 (Struktur): eingehalten (modulare Dialog- und Service-Methoden).
- Regel 7 (Tests): eingehalten (echte Router- und Journey-Tests über die Benutzerpfade).
- Regel 8 (Keine Eigenbauten von Standards): eingehalten (GoRouter und Standard-Material-Navigation genutzt).
- Regel 9 (Nur berichten, was tatsächlich geschehen ist): eingehalten (alle Tests tatsächlich ausgeführt und verifiziert).
- Regel 10 (Nichts aus späteren Versionen sichtbar bauen): eingehalten (keine PIVOT1/TC1/GB1-Elemente vorweggenommen).

Vorschläge für das PRD:
- keine.

Commit: FIX-A: Navigation & Lifecycle Regression Repair (gepusht: ja)
