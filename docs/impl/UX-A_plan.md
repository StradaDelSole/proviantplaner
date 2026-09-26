# Implementierungsplan UX-A – Navigation, Törn anlegen, Törn-Übersicht

Grundlage: `docs/design/UX_KONZEPT_v0.4.md` (Abschnitte 1, 2.1–2.3, 3, 4) und `docs/SLICES_v0.16.md` (UX-A).
Vorrang vor Design-Brief v0.5 bei Informationsarchitektur, Bildschirmen, Bedienmustern und Begriffen.

## 1. Betroffene Dateien
- `lib/core/routing/app_router.dart`: Routen anpassen (`/trips/:id` für Törn-Übersicht, keine tiefere Verschachtelung als 2 Ebenen)
- `lib/features/home/ui/start_screen.dart`: Überarbeitung "Meine Törns" (Ablauf-Schritt auf jeder Karte, großer "Neuer Törn"-Button, Einstellungen-Icon oben rechts, Archiv als eingeklappter Bereich, keine Reiterleiste)
- `lib/features/trip/ui/trip_wizard_screen.dart`: Überarbeitung "Törn anlegen" (Ein scrollbarer Screen mit drei aufeinanderfolgenden Abschnitten: Törn, Crew ohne Zahlungsdaten, Essen an Bord mit Restaurant-Zählern und Kühlschrank; direktes Navigieren zur Übersicht)
- `lib/features/trip/ui/widgets/crew_member_dialog.dart`: Entfernen aller Zahlungsdaten-Felder (IBAN, PayPal, Revolut)
- `lib/features/trip/ui/trip_overview_screen.dart` (NEU): Rückgrat-Bildschirm "Törn-Übersicht" mit 4 Ablauf-Schritten (Liste, Einkaufen, Unterwegs, Abschließen), Akzentrahmen für den nächsten Schritt, Kassenstand & Ausgaben, schwebender Button "Ausgabe erfassen", eingeklappte "Tage im Detail"
- `lib/features/trip/data/trip_service.dart`: `setRestaurantCounts` zum reaktiven Einstellen von Restaurantbesuchen; `createTripWithCrew` ohne Bootstyp-/Klima-Pflichtabfragen
- `lib/features/kitty/ui/settlement_screen.dart`: Kassenwart-Zahlungsdaten als Basis für Einzahlungen; bei Auszahlungen Wahl zwischen "bar ausgezahlt" und "Überweisen" mit IBAN-Abfrage erst bei Bedarf
- `lib/l10n/app_de.arb` & `lib/l10n/app_en.arb`: Lokalisierung der neuen Texte und Labels
- Tests: `test/features/ux/ux_a_navigation_test.dart` (NEU), Anpassung bestehender Widget- und Flow-Tests

## 2. Detailliertes Vorgehen

### A. Törn-Setup & Restaurant-Zähler
- In `TripService`:
  - `setRestaurantCounts(int tripId, {required int dinners, required int lunches})` implementieren. Verteilt Restaurant-Tage auf die ersten X/Y Tage des Törns und berechnet die Mahlzeitenmengen reaktiv neu.
  - In `createTripWithCrew`: Parameter `dinnersCount` und `lunchesCount` übernehmen; `boatType` und `climate` standardmäßig vorbelegen ohne Nutzerabfrage.
- In `TripWizardScreen`:
  - Einzelschirm mit drei aufklappbaren Sektionen (`ExpansionTile` oder animierte Cards):
    1. Törn: Name, Startdatum, Dauer (1–180 Tage mit Schnellauswahl), Charter oder eigenes Boot.
    2. Crew: Chips mit Name, Kind, Veggie, Kein Alkohol, Skipper; "+ Person". Keine Zahlungsdaten.
    3. Essen an Bord: "Wie isst eure Crew?" (Appetit), "Esst ihr auch auswärts?" mit zwei Zählern (Abendessen X von N, Mittagessen Y von N), Kühlschrank (Zahlenfeld Liter oder Schalter "kein Kühlschrank"), Reserve für Ankertage.
  - Unten fix: "Törn anlegen" -> navigiert direkt zu `/trips/$tripId`.
- In `CrewMemberDialog`:
  - Entfernen der Textfelder für IBAN, PayPal und Revolut.

### B. Meine Törns (StartScreen)
- Listet alle aktiven Törns auf Karten mit Name, Datum, Personenanzahl und dem aktuellen Ablaufschritt (z. B. "Nächster Schritt: Liste bearbeiten" bzw. "Nächster Schritt: Einkaufen").
- Großer Button "Neuer Törn".
- Einstellungen über Symbol oben rechts (`Icons.settings_outlined`), das zu `/more` führt.
- Archivierte Törns als eingeklappter Bereich ("Archiv").
- Keine Reiterleiste (`BottomNavigationBar`).

### C. Törn-Übersicht (TripOverviewScreen)
- Kopf: Törnname, Datum, Personen & Tage, Bearbeiten-Icon.
- Vier Schritte untereinander:
  1. Liste: "X Positionen · Y Vorschläge offen", Button "Liste bearbeiten".
  2. Einkaufen: Zeilen je Stopp mit Art-Icon, Button "Einkauf starten" je Stopp, "+ Einkaufsstopp".
  3. Unterwegs: Großer Kassenstand, Kassenwart, letzte Ausgaben, Buttons "Ausgabe erfassen" und "Einzahlen".
  4. Abschließen: Vorschau "Wer zahlt wem", Button "Abrechnen".
- Nächster sinnvoller Schritt wird mit Akzentrahmen hervorgehoben.
- Schwebender Button (FAB) "Ausgabe erfassen", sobald der Törn begonnen hat oder Ausgaben existieren.
- "Tage im Detail" am Ende eingeklappt.

### D. Zahlungsdaten-Konzept
- Zahlungsdaten existieren primär für den Kassenwart.
- In der Abrechnung (`SettlementScreen`):
  - Bei Rückzahlungen an ein Crewmitglied ("Anna bekommt 18,00 €"):
    - Button "Bar ausgezahlt" -> Transaktion direkt als erledigt markiert.
    - Button "Überweisen" -> fragt IBAN ab, falls noch nicht hinterlegt, validiert mit Modulo-97 und zeigt dann den EPC-QR-Code.

### E. Navigationstiefe
- Kein Bildschirm tiefer als 2 Ebenen:
  - Ebene 0: Meine Törns (`/`)
  - Ebene 1: Törn anlegen (`/trips/new`), Törn-Übersicht (`/trips/:id`), Einstellungen (`/more`)
  - Ebene 2: Liste (`/trips/:id/shopping-list`), Einkaufsmodus (`/trips/:id/shop/:stopId`), Abrechnen (`/trips/:id/kitty/settlement`)

## 3. Prüfung der Abnahmekriterien
1. **Meine Törns hat keine Reiterleiste**: Widget-Test verifiziert Abwesenheit von BottomNavigationBar.
2. **Anlegen ohne Revier/Bootstyp möglich und führt direkt zur Übersicht**: Widget-Test füllt Wizard aus und prüft Weiterleitung zur Törn-Übersicht.
3. **Zähler "Restaurant" ändern Bord-Mahlzeiten**: Test verifiziert, dass Restaurantbesuche Bord-Mahlzeiten reaktiv verringern.
4. **Übersicht zeigt vier Schritte und hebt den nächsten hervor**: Widget-Test auf `TripOverviewScreen` prüft alle 4 Karten und Akzentrahmen.
5. **"Abrechnen" und "Ausgabe erfassen" sind ohne Drei-Punkte-Menü erreichbar**: Widget-Test verifiziert direkte Sichtbarkeit der Buttons.
6. **Kein Bildschirm tiefer als zwei Ebenen**: Test prüft Router-Konfiguration und Stack-Tiefe.
7. **Crew-Verwaltung enthält keine Zahlungsdaten-Felder**: Widget-Test auf `CrewMemberDialog` stellt sicher, dass keine IBAN/PayPal/Revolut-Felder vorhanden sind.
8. **Zahlung an die Kasse nutzt die Daten des Kassenwarts**: Test prüft EPC-QR-Code-Daten des Kassenwarts.
9. **IBAN eines anderen Mitglieds wird erst bei "Überweisen" in dessen Abrechnungszeile abgefragt**: Widget-Test auf Settlement-Screen prüft "bar ausgezahlt" und IBAN-Prompt bei "Überweisen".
