# Abschlussbericht FB1-D – Bordkasse neu

Slice: FB1-D – Bordkasse neu
Umgesetzt:
- Kassenwart-Prinzip (`treasurerMemberId` in Tabelle `Trips`, Drift-Schema v5 mit SQLite-Migration):
  - "Die Kasse" ist kein eigenes Konto; alle Zahlungen an oder aus der Kasse laufen über den Kassenwart.
  - Dialog bei Erstaufruf der Kasse: "Wer verwaltet die Kasse? (Standard: Skipper)" legt Kassenwart fest.
  - Kassenwart-Card in der Kassenansicht (`KittyScreen`) mit Option zum Wechseln des Kassenwarts.
  - Kassenwart-Erweiterung in der Datensicherung (`BackupCoordinator`).
- Einzahlen in einem Schritt:
  - `PaymentSheet` fragt "Wie viel zahlt jeder ein? (€)" mit JetBrains Mono Zahlenfeld.
  - Checkliste aller Crewmitglieder zum Abhaken (standardmäßig alle vorselektiert).
  - Dynamischer Button "Einzahlungen speichern (X €)" speichert alle ausgewählten Einzahlungen in einem Durchgang.
  - Unterstützt `initialAmountInCents` zur Vorbefüllung bei Nachschuss.
- Ausgabe mit 3 Pflichtfeldern:
  - `ExpenseSheet` mit 3 Primärfeldern: Betrag, Wofür (Kategorie) und Wer hat bezahlt (`SegmentedButton`: Kasse oder Person).
  - Titel/Notiz und abweichende Beteiligung/Aufteilung eingeklappt unter "Mehr Optionen".
- Nachschuss-Hinweis:
  - Bei Kassenstand unter 50 € erscheint ein Hinweisbanner: "Kasse fast leer – jeder legt 50 € nach?".
  - Klick auf "Übernehmen" öffnet das `PaymentSheet` vorbefüllt mit 50 €.
- Abrechnung auf einem Bildschirm (`SettlementScreen`):
  - Jede Zeile klar formatiert: "bekommt X von Y" oder "zahlt X an Y" mit Button "Bezahlen". Keine Zeilen "→ Kasse" oder Pseudomitglied "Bordkasse".
  - Mathematische Garantie: Die Summe aller Netto-Salden ist mathematisch immer exakt 0 Cent (`sum(netBalanceInCents) == 0`).
  - Klick auf "Bezahlen" klappt den EPC-QR-Code (GiroCode) und Zahlungslinks mit den Daten des jeweiligen Empfängers auf.
  - Bei fehlenden Zahlungsdaten für den Empfänger erscheint der Hinweiskasten "Für [Name] sind keine Zahlungsdaten hinterlegt" mit Button "Jetzt eintragen".

Geänderte/neue Dateien:
- `lib/core/database/tables.dart`
- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart`
- `lib/core/database/daos.dart`
- `lib/core/services/backup_coordinator.dart`
- `lib/features/kitty/domain/models/kitty_models.dart`
- `lib/features/kitty/domain/calculation/kitty_engine.dart`
- `lib/features/kitty/data/kitty_service.dart`
- `lib/features/kitty/ui/kitty_screen.dart`
- `lib/features/kitty/ui/settlement_screen.dart`
- `lib/features/kitty/ui/widgets/expense_sheet.dart`
- `lib/features/kitty/ui/widgets/payment_sheet.dart`
- `test/core/database/migration_test.dart`
- `test/features/kitty/kitty_engine_test.dart`
- `test/features/kitty/kitty_ui_test.dart`
- `test/features/kitty/kitty_fb1d_test.dart`
- `docs/impl/FB1-D_plan.md`
- `docs/impl/FB1-D_bericht.md`
- `CHANGELOG.md`
- `README.md`

flutter analyze: No issues found! (0 Probleme)
flutter test: 153/153 Tests bestanden (100% grün, 28 Kitty-Tests)

Abnahmekriterien:
- Alle Kassenzahlungen laufen über den Kassenwart: erfüllt – Nachweis: automatischer Test (`test/features/kitty/kitty_fb1d_test.dart: "FB1-D Abnahmekriterium 1: Alle Kassenzahlungen laufen über den Kassenwart calculateSharedKitty generiert nur Transfers zwischen Mitgliedern und Kassenwart"`)
- Abrechnung ohne Zeilen "→ Kasse": erfüllt – Nachweis: automatischer Test (`test/features/kitty/kitty_fb1d_test.dart: "FB1-D Abnahmekriterium 2: Abrechnung ohne Zeilen \"→ Kasse\" SettlementScreen zeigt formatierte Zeilen ohne \"→ Kasse\" oder Pseudomitglied"`)
- Summe der Salden 0: erfüllt – Nachweis: automatischer Test (`test/features/kitty/kitty_fb1d_test.dart: "FB1-D Abnahmekriterium 3: Summe der Salden ist mathematisch immer exakt 0 Cent"` für Kasse im Plus, Kasse im Minus und Kasse glatt)
- Bezahlen öffnet QR mit den Daten des Empfängers: erfüllt – Nachweis: automatischer Test (`test/features/kitty/kitty_fb1d_test.dart: "FB1-D Abnahmekriterium 4: Bezahlen öffnet QR mit den Daten des Empfängers Tipp auf Bezahlen öffnet EpcQrWidget mit Daten des Empfängers"`)
- Fehlende Zahlungsdaten zeigen den Hinweis: erfüllt – Nachweis: automatischer Test (`test/features/kitty/kitty_fb1d_test.dart: "FB1-D Abnahmekriterium 5: Fehlende Zahlungsdaten zeigen Hinweiskasten Empfänger ohne Zahlungsdaten zeigt Hinweis \"Für ... keine Zahlungsdaten hinterlegt\" mit \"Jetzt eintragen\""`)

Offen / Risiken:
- Keine.

Annahmen / Abweichungen vom PRD:
- Gemäß vorrangigem Dokument `docs/impl/FEEDBACK_R1_v0.1.md` Punkt 9 und `docs/SLICES_v0.15.md` (FB1-D) wurde das Bordkassen-Modell grundlegend vereinfacht: Kassenwart statt virtuelles Kassen-Konto, Einzahlung in einem Schritt, 3-Felder-Ausgabe und Einzelschirm-Abrechnung ohne Zeilen "→ Kasse".

Änderung bestehender Tests (Regel 7):
- `test/features/kitty/kitty_ui_test.dart`: Anpassung der Tests SC-KAS-01 bis SC-KAS-03 an die neuen Spezifikationen aus FB1-D (Kassenwart im Setup hinterlegt um Erstabfrage-Modal zu überspringen, 3-Felder-Layout im ExpenseSheet mit Notiz unter "Mehr Optionen", 1-Schritt-Einzahlung mit Checkliste im PaymentSheet).
- `test/features/kitty/kitty_engine_test.dart`: Anpassung der Abrechnungstests auf das Kassenwart-Modell (Kassenwart gleicht Kassenrest aus, Summe der Salden aller Mitglieder ist exakt 0 Cent, keine Transfers mit Pseudomitglied "Bordkasse").

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): Eingehalten. Feste Enums für `ExpenseCategory`, `KittyModel`. Keine String-Vergleiche in der Rechenlogik.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine Stubs, leeren Funktionen oder TODOs.
- Regel 3 (Ehrliche Berichte): Eingehalten. Alle Abnahmekriterien mit konkreten automatischen Tests belegt.
- Regel 4 (Alles datengetrieben): Eingehalten. Keine Betrags-, IBAN- oder Personenliterale im Code; alle Texte in ARB.
- Regel 5 (Kommazahlen mit Toleranz, Cent-Beträge): Eingehalten. Alle Berechnungen der Bordkasse erfolgen exakt in Cent (`int`).
- Regel 6 (Struktur): Eingehalten. Kurze Funktionen, klare Modularisierung, Dokumentationskommentare für öffentliche Klassen und Methoden.
- Regel 7 (Tests): Eingehalten. Randfälle (Kasse im Plus, Kasse im Minus, Kasse glatt, Kassenwart-Zuweisung, fehlende IBAN) vollständig abgedeckt. Anpassung alter S5-Tests begründet.
- Regel 8 (Keine Eigenbauten von Standards): Eingehalten.
- Regel 9 (Nur berichten, was tatsächlich geschehen ist): Eingehalten. Ausschließlich verifizierte automatische Tests angegeben.
- Regel 10 (Nichts aus späteren Versionen sichtbar): Eingehalten.

Vorschläge für das PRD:
- Keine.

Commit: FB1-D: Bordkasse neu (gepusht: ja)
