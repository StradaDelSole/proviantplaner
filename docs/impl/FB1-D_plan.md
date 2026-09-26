# Implementierungsplan FB1-D – Bordkasse neu

Grundlage: `docs/impl/FEEDBACK_R1_v0.1.md` Punkt 9 und `docs/SLICES_v0.15.md` (FB1-D).

## Ziel
Bordkasse neu strukturieren:
1. Kassenwart-Prinzip: "Die Kasse" ist kein eigenes Konto; alle Zahlungen an oder aus der Kasse laufen über den Kassenwart. Beim ersten Öffnen Abfrage "Wer verwaltet die Kasse? (Standard: Skipper)".
2. Einzahlen in einem Schritt: "Wie viel zahlt jeder ein?" – ein Betrag für alle, darunter Checkliste der Crewmitglieder zum Abhaken.
3. Ausgabe mit drei Pflichtfeldern: Betrag, Wofür (Kategorie), Wer hat bezahlt (SegmentedButton: Kasse oder Person). Zusätzliche Optionen (Titel/Notiz, abweichende Aufteilung) eingeklappt unter "Mehr Optionen".
4. Nachschuss-Hinweis: Bei Kassenstand < 50 € erscheint ein Hinweisbanner: "Kasse fast leer – jeder legt 50 € nach?" mit Button "Übernehmen" (öffnet das Einzahlungs-Sheet vorbefüllt mit 50 €).
5. Abrechnung auf einem Bildschirm: Je Person klare Zeilen "bekommt 18,00 € von Anna" oder "zahlt 42,10 € an Anna" mit Button "Bezahlen". Keine Zeilen "→ Kasse". Summe aller Salden mathematisch immer exakt 0 Cent.
6. Bezahlen-Button: Öffnet EPC-QR-Code und Links mit den Zahlungsdaten des jeweiligen Empfängers. Fehlen dessen Zahlungsdaten, erscheint der Hinweiskasten "Für [Name] sind keine Zahlungsdaten hinterlegt" mit "Jetzt eintragen".

## Betroffene Dateien
- `lib/core/database/tables.dart` (Feld `treasurerMemberId` in Trips)
- `lib/core/database/app_database.dart` (Schema-Version 5 & Migration)
- `lib/core/database/app_database.g.dart` (Generierter Drift-Code)
- `lib/core/database/daos.dart` (`setTripTreasurer`)
- `lib/core/services/backup_coordinator.dart` (Backup-Serialisierung für `treasurerMemberId`)
- `lib/features/kitty/domain/models/kitty_models.dart` (`MemberBalance.isTreasurer`, `actualDepositsInCents`)
- `lib/features/kitty/domain/calculation/kitty_engine.dart` (Kassenwart-Logik, mathematische Summe 0, Ausgleichstransfers nur Kassenwart <-> Crew)
- `lib/features/kitty/data/kitty_service.dart` (`setTreasurer`, Laden des Kassenwarts)
- `lib/features/kitty/ui/kitty_screen.dart` (Kassenwart-Dialog bei Erstaufruf, Kassenwart-Karte, Nachschuss-Banner)
- `lib/features/kitty/ui/settlement_screen.dart` (Abrechnung ohne Kasse-Zeilen, Bezahlen-Akkordeon je Empfänger)
- `lib/features/kitty/ui/widgets/expense_sheet.dart` (3 Felder + Mehr Optionen)
- `lib/features/kitty/ui/widgets/payment_sheet.dart` (1-Schritt Einzahlung)
- `test/core/database/migration_test.dart`
- `test/features/kitty/kitty_engine_test.dart`
- `test/features/kitty/kitty_fb1d_test.dart` (Neu)

## Prüfung der Abnahmekriterien
1. **Alle Kassenzahlungen laufen über den Kassenwart**: Automatische Tests in Engine und UI belegen, dass alle Transfers der Kasse ausschließlich den Kassenwart als Gegenpartei haben und keine Transfers mit "Bordkasse" existieren.
2. **Abrechnung ohne Zeilen '→ Kasse'**: Test auf `SettlementScreen` belegt, dass kein "→ Kasse", "an Kasse", "von Kasse" oder Pseudomitglied angezeigt wird.
3. **Summe der Salden ist mathematisch immer exakt 0 Cent**: Unit-Tests über verschiedene Konstellationen (Kasse im Plus, Kasse im Minus, Kasse glatt).
4. **Bezahlen öffnet QR mit den Daten des Empfängers**: Widget-Test auf `SettlementScreen` prüft Anzeige des EPC-QR-Codes mit Name und IBAN des Empfängers nach Tippen auf "Bezahlen".
5. **Fehlende Zahlungsdaten zeigen Hinweiskasten**: Widget-Test verifiziert Hinweiskasten "Für [Name] sind keine Zahlungsdaten hinterlegt" mit Aktion "Jetzt eintragen".
