# Implementierungsplan Slice S5 – Bordkasse und Kostenteilung

## 1. Ziel und Umfang
Gemäß `SLICES_v0.12.md` und `DESIGN_BRIEF_v0.4.md`:
- **Berechnungsmodelle (Reines Dart gemäß Leitplanken & Programmierregel 5):**
  - Beträge strikt in Cent als ganze Zahlen (`int`), keine Rundungsfehler durch Floating-Point.
  - **Modell 1: Gemeinsame Bordkasse (Standard):**
    - Einzahlungen pro Person (in Cent).
    - Ausgaben aus der Kasse.
    - Kassenstand = Einzahlungen − Ausgaben.
    - Abrechnung: Bei positivem Kassenstand Rückzahlung ("wer bekommt wie viel vom Rest zurück"); bei negativem Kassenstand Nachschuss ("wer muss wie viel nachschießen").
  - **Modell 2: Einzelabrechnung ("wer schuldet wem"):**
    - Jede Person zahlt Ausgaben selbst.
    - Berechnung der Netto-Salden für jede Person: Summe aller bezahlten Beträge minus Summe aller zu tragenden Anteile.
    - Summe aller Salden ist mathematisch immer exakt 0 Cent.
    - Vereinfachung der Ausgleichszahlungen (Debt Simplification / Greedy Match) für minimale Anzahl von Überweisungen.
- **Ausgaben & Kategorien:**
  - 7 Kategorien als striktes Enum `ExpenseCategory`: Proviant (`provisions`), Getränke (`drinks`), Hafen und Liegeplatz (`marina_berth`), Diesel (`fuel`), Charter und Kaution (`charter_deposit`), Restaurant (`restaurant`), Sonstiges (`other`).
  - Ausgaben erfassen (SC-KAS-02): Betrag (Cent), Titel, Kategorie, Datum/Tag, bezahlt von (Kasse oder Person), individuelle Aufteilung (optional).
  - Einzahlungen erfassen (SC-KAS-03): Betrag, Person, Datum, Option "Gleicher Betrag für alle".
- **Beteiligungsregeln (SC-KAS-04):**
  - Beteiligung pro Person und Kategorie.
  - Schnellauswahl-Profile:
    - Überall beteiligt (`all`)
    - Skipper frei (ganz) (`skipper_free_full`: 0 % auf alles)
    - Skipper frei bei Charter, Hafen, Diesel (`skipper_free_charter_marina_fuel`: zahlt Essen, Trinken, Restaurant mit)
    - Kein Alkohol (`no_alcohol`: zahlt bei Getränken 0)
  - Cent-genaue Verteilung: Anteile Nichtbeteiligter werden auf die übrigen Beteiligten verteilt. Rest-Cent werden deterministisch aufgeteilt, so dass die Summe aller Anteile exakt dem Gesamtbetrag entspricht.
- **Zahlungen anstoßen (SC-KAS-05):**
  - EPC-QR-Code (GiroCode) nach EPC069-12 / SEPA Credit Transfer Spezifikation aus IBAN, Name, Betrag und Verwendungszweck.
  - Reine Dart-Erzeugung des QR-Codes / Canvas ohne externe Pakete außerhalb der Leitplanken.
  - Anzeige des QR-Codes (240 dp mit weißer Ruhezone auch im Nachtmodus für Scanbarkeit).
  - Zahlungslinks für PayPal (`paypal.me/...`) und Revolut (`revolut.me/...`).
  - Reine lokale Datenhaltung, keine Zahlungsabwicklung.

## 2. Betroffene Dateien
### Zu ändernde / zu erstellende Dateien
- `lib/l10n/app_de.arb` & `lib/l10n/app_en.arb`: Lokalisierung für Kassenbegriffe, Kategorien, Salden, Abschluss.
- `lib/core/database/tables.dart` & `lib/core/database/daos.dart`:
  - `Expenses` und `KittyPayments` in Cent (`amountInCents` bzw. Konvertierung).
  - `CrewMember`: Speicherung der Beteiligungs-Einstellungen (JSON oder Spalte).
  - DAOs für Ausgaben, Einzahlungen und Kassenstand.
- `lib/features/kitty/domain/models/kitty_models.dart`:
  - `ExpenseCategory` Enum mit Icons und Labels.
  - `KittyModel` Enum (`sharedKitty`, `individual`).
  - `ParticipationProfile` Enum (`all`, `skipperFreeFull`, `skipperFreePartial`, `noAlcohol`, `custom`).
  - `PaymentTransfer`: Wer zahlt wem wie viel (Cent).
  - `EpcQrData`: Validierung und Generierung des EPC-Strings nach EPC069-12.
- `lib/features/kitty/domain/calculation/kitty_engine.dart`:
  - Reine Dart-Berechnungs-Engine: Cent-genaue Kostenverteilung, Salden-Berechnung, Schulden-Minimierung, Restbetrags-Verteilung.
- `lib/features/kitty/data/kitty_service.dart` & `kitty_providers.dart`:
  - Service und Riverpod-Provider für Kassenstand, Ausgabenliste, Salden und Abschluss.
- `lib/features/kitty/ui/`:
  - `kitty_screen.dart` (SC-KAS-01 Übersicht mit Kassenstand, Ausgaben-/Personen-Segment, Salden)
  - `widgets/expense_sheet.dart` (SC-KAS-02 Ausgabe erfassen)
  - `widgets/payment_sheet.dart` (SC-KAS-03 Einzahlung erfassen)
  - `widgets/participation_matrix_sheet.dart` (SC-KAS-04 Beteiligung je Person)
  - `settlement_screen.dart` (SC-KAS-05 Törn abschließen mit EPC-QR-Code und Links)
  - `widgets/epc_qr_widget.dart` (Darstellung des EPC-QR-Codes mit weißem Rand)
- `lib/core/routing/app_router.dart`:
  - Routen für `/trips/:id/kitty`, `/trips/:id/kitty/settlement`.
- `lib/features/shopping_list/ui/widgets/trip_bottom_bar.dart`:
  - Aktivierung des 3. Reiters "Bordkasse".

### Tests
- `test/features/kitty/kitty_engine_test.dart`:
  - Gemeinsame Bordkasse: Einzahlungen, Ausgaben, Restverteilung / Nachschuss.
  - Einzelabrechnung: Cent-genaue Netto-Salden, Summe aller Salden ist immer 0 Cent.
  - Beteiligung pro Kategorie & Schnellauswahl "Skipper frei" (ganz & partiell).
  - Nicht-Trinker zahlen keinen Alkohol.
  - Ungleiche Aufteilung und Rest-Cent-Verteilung.
  - Minimale Anzahl Überweisungen (Debt Simplification).
  - EPC-QR-Code Format-Test nach EPC069-12 (GiroCode).
- `test/features/kitty/kitty_ui_test.dart`:
  - Widget-Tests für SC-KAS-01 bis SC-KAS-05 in Light, Dark und Nightwatch.
  - Verifikation von Mindest-Touch-Targets $\ge 48\text{ dp}$.

## 3. Prüfung der Abnahmekriterien (SLICES_v0.12.md)
1. **Zwei Modelle:** Unit-Tests für gemeinsame Bordkasse und Einzelabrechnung vorhanden und grün.
2. **Kategorie-Beteiligung & Skipper frei:** Centgenaue Verteilung nach Profilen ohne Cent-Verlust.
3. **Saldo-Summe:** Summe aller Salden ist mathematisch immer exakt 0 Cent.
4. **EPC-QR-Code:** Exakte Einhaltung der BCD/002/1/SCT-Spezifikation für Banking-Apps.
5. **Programmierregeln 1–7 & Designregeln 1–13:**
   - Ganze Zahlen für Beträge (`int` Cent), keine Floats.
   - Enums für Kategorien und Modelle.
   - Reines Dart für die Engine.
   - Nachtwache-konforme Darstellung.
