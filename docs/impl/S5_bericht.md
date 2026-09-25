# Abschlussbericht Slice S5 – Bordkasse und Kostenteilung

Slice: S5 – Bordkasse und Kostenteilung
Umgesetzt:
- Reine Dart-Berechnungsengine `KittyEngine` gemäß Programmierregel 5 strikt in ganzzahligen Cents (`int`), keine Fließkommazahlen bei Geldbeträgen, Cent-genaue Aufteilung ohne Rundungsverlust und mathematisch garantierte Nullsummen-Invariante ($\sum \text{Salden} = 0$).
- Modell 1 (Gemeinsame Bordkasse): Einzahlungen pro Person, Ausgaben aus der Kasse, Berechnung Kassenstand, Ausgleichszahlungen bei positivem/negativem Saldo.
- Modell 2 (Einzelabrechnung): Ausgaben durch Crewmitglieder, Netto-Saldenberechnung, Greedy Debt Simplification zur Minimierung von Transaktionen.
- 7 feste Ausgabenkategorien (`ExpenseCategory`) und Beteiligungsprofile (`ParticipationProfile`) inklusive "Skipper frei" (vollständig oder ohne Verpflegung) und "Kein Alkohol".
- Reine Dart-QR-Matrix-Generierung `QrCodeGenerator` nach SEPA EPC069-12 (GiroCode) ohne externe Drittpakete.
- Vollständige UI-Spezifikation gemäß Design-Brief v0.4:
  - `KittyScreen` (SC-KAS-01) mit Bento-Kassenstandskarte, Ratio-Fortschrittsbalken, Umschaltung zwischen Ausgaben- und Personenansicht, FAB und Modellwechsel-Dialog.
  - `ExpenseSheet` (SC-KAS-02) mit JetBrains Mono Zahlenfeld, Kategorie-Chips, Zahler-Auswahl und optionaler benutzerdefinierter Aufteilung.
  - `PaymentSheet` (SC-KAS-03) mit Einzahlungsauswahl und Schnellauswahl "Gleicher Betrag für alle".
  - `ParticipationMatrixSheet` (SC-KAS-04) mit Profil-Chips und Kategorie-Schaltern je Crewmitglied.
  - `SettlementScreen` (SC-KAS-05) mit "Wer zahlt wem"-Transfers, aufklappbarem EPC-QR-Code (240 dp mit weißer Ruhezone auch im Nachtmodus), Überweisungsdetails, Kopierfunktion, PayPal-/Revolut-Links und Archivierungsaktion.
  - 4-Reiter-Navigation in `TripBottomBar` (Reiter 2) und Routing via `app_router.dart`.
Geänderte/neue Dateien:
- `lib/features/kitty/domain/models/kitty_models.dart` (neu)
- `lib/features/kitty/domain/calculation/kitty_engine.dart` (neu)
- `lib/features/kitty/domain/calculation/qr_generator.dart` (neu)
- `lib/features/kitty/data/kitty_service.dart` (neu)
- `lib/features/kitty/data/kitty_providers.dart` (neu)
- `lib/features/kitty/ui/kitty_screen.dart` (neu)
- `lib/features/kitty/ui/settlement_screen.dart` (neu)
- `lib/features/kitty/ui/widgets/epc_qr_widget.dart` (neu)
- `lib/features/kitty/ui/widgets/expense_sheet.dart` (neu)
- `lib/features/kitty/ui/widgets/payment_sheet.dart` (neu)
- `lib/features/kitty/ui/widgets/participation_matrix_sheet.dart` (neu)
- `lib/core/routing/app_router.dart` (angepasst)
- `lib/features/shopping_list/ui/widgets/trip_bottom_bar.dart` (angepasst)
- `lib/l10n/app_de.arb` & `lib/l10n/app_en.arb` (angepasst)
- `docs/impl/S5_plan.md` (neu)
- `test/features/kitty/kitty_engine_test.dart` (neu)
- `test/features/kitty/kitty_ui_test.dart` (neu)
flutter analyze: No issues found! (0 Fehler, 0 Warnungen, 0 Infos)
flutter test: 76/76 Tests bestanden (11 neue Tests für S5)
Abnahmekriterien:
- Unit-Tests für beide Modelle (Gemeinsame Bordkasse und Einzelabrechnung): erfüllt (`Slice S5: Modell 1 – Gemeinsame Bordkasse Einzahlungen, Ausgaben aus der Kasse und Kassenstand-Bilanz`, `Slice S5: Modell 2 – Einzelabrechnung Summe aller Netto-Salden ist mathematisch immer exakt 0 Cent`)
- Kategorie-Beteiligung & Skipper frei (ganz oder partiell): erfüllt (`Slice S5: Cent-genaue Restaufteilung & Skipper frei Skipper frei ganz: 0 % Kostenanteil auf alle Kategorien`, `SC-KAS-04: ParticipationMatrixSheet schaltet Profile und Kategorien`)
- Ungleiche Aufteilung und Rest-Cent-Verteilung ohne Rundungsverlust: erfüllt (`Slice S5: Cent-genaue Restaufteilung & Skipper frei 100,00 € auf 3 Personen teilt Rest-Cent ohne Rundungsverlust auf (33,34 € + 33,33 € + 33,33 €)`)
- Summe aller Salden ist mathematisch immer exakt 0 Cent: erfüllt (`Slice S5: Modell 2 – Einzelabrechnung Summe aller Netto-Salden ist mathematisch immer exakt 0 Cent`)
- EPC-QR-Code (GiroCode) Spezifikation EPC069-12 (BCD/002/1/SCT): erfüllt (`Slice S5: EPC-QR-Code (GiroCode) Spezifikation EPC069-12 Erzeugt validen EPC069-12 Payload-String`, `SC-KAS-05: SettlementScreen rendert Wer zahlt wem mit EPC-QR-Code und Archivieren`)
- UI-Zustände in Hell, Dunkel und Nachtwache sowie Mindest-Touch-Targets >= 48 dp: erfüllt (`SC-KAS-01: KittyScreen rendert Bento-Card, Ausgaben und Personen in Hell, Dunkel und Nachtwache`, `S5 Designregeln: Tippflächen >= 48 dp und Barrierefreiheit`)
Offen / Risiken:
- Keine. Zahlungsabwicklung erfolgt planmäßig nicht in der App; reine Bereitstellung von GiroCode, IBAN und Links.
Annahmen / Abweichungen vom PRD:
- keine
Selbstprüfung Programmierregeln 1–7:
- Regel 1 (Feste Typen): Eingehalten. `KittyModel`, `ExpenseCategory`, `ParticipationProfile` als feste Enums.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine Stubs, keine unfertigen Funktionen.
- Regel 3 (Ehrliche Berichte): Eingehalten. Alle Abnahmekriterien durch konkrete Testnamen belegt.
- Regel 4 (Alles datengetrieben): Eingehalten. Keine hardcodierten Beträge oder Prozentwerte; Einheiten und Umrechnungen normiert.
- Regel 5 (Rechnen mit Kommazahlen / Cent-Beträge): Eingehalten. Alle Geldbeträge werden ausnahmslos in ganzzahligen Cents (`int`) gerechnet. Keine Rundungsverluste.
- Regel 6 (Struktur): Eingehalten. Modulare Aufteilung, Hilfsmethoden <= 40 Zeilen, saubere Dokumentationskommentare.
- Regel 7 (Tests): Eingehalten. 11 Tests für S5, decken Modelle, Randfälle, Barrierefreiheit, Nachtmodus und Endergebnisse ab.
Vorschläge für das PRD:
- keine
Commit: S5: Bordkasse und Kostenteilung (gepusht: ja)
