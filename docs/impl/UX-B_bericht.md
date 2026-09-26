# Abschlussbericht UX-B – Liste, Einkaufsmodus, Liefern lassen

Slice: UX-B – Liste, Einkaufsmodus, Liefern lassen
Umgesetzt:
- Liste:
  - In-Place Accordion: Gruppen klappen inline auf/zu ohne modales Bottom Sheet.
  - Übernahme von Varianten und Vorschlägen (einzeln, pro Kategorie, alle).
  - Mengenanpassung inline: Tippen auf die Zahl öffnet direkt ein Textfeld im Zeilenelement.
  - Wasser-Schnellwahl: Filter-Chips für `+25% warm` und `+50% heiß` zur dynamischen Mengenanpassung.
  - Stopp-Zuordnung per Wischgeste (Dismissible von rechts nach links mit Auswahl-Sheet und Chips).
  - Floating Action Button `+ Position` zur Artikelsuche mit Fallback für benutzerdefinierte Positionen.
  - Untere feste Aktionsleiste `Einkauf starten · Tag X <Stopp>` mit Umschaltung des aktiven Einkaufsstopps.
- Liefern lassen & Bestellwesen:
  - Einkaufsstopp-Art wählbar zwischen "Selbst einkaufen" und "Liefern lassen" in Timeline und Übersicht.
  - Sheet `DeliveryConfigSheet` zur Pflege aller Lieferdaten (Marina, Liegeplatz, Bootsname, Lieferdatum/-uhrzeit, Ansprechpartner, Notizen, Lieferantenauswahl mit Speichern-Option).
  - Gespeicherte Lieferanten über alle Törns hinweg (`SupplierService`, `SupplierProfile`), verwaltbar in `MoreScreen`.
  - Vollständige Bestellvorschau `OrderPreviewSheet` mit Gruppierung nach Abteilungen, Packungsgrößen und Stückzahlen.
  - Versand über natives Teilen-Menü: Text (für WhatsApp/E-Mail) und PDF-Dokument (`PdfExportService.generateDeliveryOrderPdf`).
  - Statusverfolgung: "Bestellung als gesendet markieren", Erfassung des Sendedatums (`orderedAt`) und Erkennung von Nachträgen bei geänderter Positionenanzahl.
  - Wareneingang `DeliveryReceivedSheet`: Abhaken gelieferter Positionen, Verschieben fehlender Positionen auf Folge-Stopps und anschließendes Dialog-Angebot "Jetzt direkt einlagern?".
- Einkaufsmodus:
  - Gruppierung nach Supermarkt-Abteilungen, offene Artikel oben, abgehakte Artikel mit Durchstreichung/Transparenz am Ende der Abteilung.
  - Direkter Absprung "Ausgabe erfassen" in der AppBar.
  - "Fertig eingekauft"-Button mit Übergang zur Einlagerung.

Geänderte/neue Dateien:
- `lib/core/services/pdf_export_service.dart`
- `lib/features/shopping_list/data/supplier_service.dart` (neu)
- `lib/features/shopping_list/data/delivery_order_service.dart` (neu)
- `lib/features/shopping_list/ui/widgets/delivery_config_sheet.dart` (neu)
- `lib/features/shopping_list/ui/widgets/order_preview_sheet.dart` (neu)
- `lib/features/shopping_list/ui/widgets/delivery_received_sheet.dart` (neu)
- `lib/features/shopping_list/ui/widgets/item_row_widget.dart`
- `lib/features/shopping_list/ui/widgets/planning_view.dart`
- `lib/features/shopping_list/ui/shopping_list_screen.dart`
- `lib/features/shopping_list/ui/shopping_mode_screen.dart`
- `lib/features/trip/ui/trip_overview_screen.dart`
- `lib/features/trip/ui/trip_timeline_screen.dart`
- `lib/features/more/ui/more_screen.dart`
- `test/features/ux/ux_b_shopping_and_delivery_test.dart` (neu)
- `test/features/ux/ux_a_navigation_test.dart`
- `docs/impl/UX-B_plan.md` (neu)
- `docs/impl/UX-B_bericht.md` (neu)

flutter analyze: Keine Fehler / No issues found! (ran in 16.5s)
flutter test: 168 Tests erfolgreich (0 Fehler)

Abnahmekriterien:
- Gruppe aufklappen (inline Accordion ohne Sheet): erfüllt – Nachweis: automatischer Test (`1. Gruppe aufklappen zeigt Varianten direkt inline ohne modales Bottom Sheet` in `test/features/ux/ux_b_shopping_and_delivery_test.dart`)
- Variante übernehmen: erfüllt – Nachweis: automatischer Test (`2. Variante übernehmen übernimmt Position in die Vorratsliste` in `test/features/ux/ux_b_shopping_and_delivery_test.dart`)
- Menge inline ändern: erfüllt – Nachweis: automatischer Test (`3. Menge inline ändern öffnet Textfeld und übernimmt neue Zahl` in `test/features/ux/ux_b_shopping_and_delivery_test.dart`)
- Wischgeste ordnet Stopp zu: erfüllt – Nachweis: automatischer Test (`4. Wischgeste öffnet Stopp-Auswahl als Chips` in `test/features/ux/ux_b_shopping_and_delivery_test.dart`)
- Bestellung enthält exakt die Positionen des Stopps nach Abteilung mit Menge und Packungsgröße (Text & PDF): erfüllt – Nachweis: automatischer Test (`5. Bestellung enthält exakt die Positionen des Stopps nach Abteilung mit Menge und Packungsgröße` in `test/features/ux/ux_b_shopping_and_delivery_test.dart`)
- Lieferant wird gespeichert und in einem zweiten Törn angeboten: erfüllt – Nachweis: automatischer Test (`6. Lieferant wird gespeichert und in einem zweiten Törn angeboten` in `test/features/ux/ux_b_shopping_and_delivery_test.dart`)

Offen / Risiken:
- Keine offenen Punkte für UX-B.

Annahmen / Abweichungen vom PRD:
- keine.

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): Eingehalten. Enums und typisierte Modelle für alle Lieferdaten und Lieferanten.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine TODOs, keine Stubs.
- Regel 3 (Ehrliche Berichte): Eingehalten. Alle Abnahmekriterien durch benannte Tests nachgewiesen.
- Regel 4 (Alles datengetrieben): Eingehalten. Mengen und Packungsgrößen werden dynamisch formatiert und berechnet.
- Regel 5 (Kommazahlen/Cent): Eingehalten. Keine float-Gleichheitsvergleiche ohne Toleranz.
- Regel 6 (Struktur): Eingehalten. Modulare Sheet- und Servicestruktur.
- Regel 7 (Tests): Eingehalten. Dedizierte Tests für alle Interaktionen und Datenflüsse.
- Regel 8 (Keine Eigenbauten von Standards): Eingehalten. `pdf`, `printing` und `share_plus` verwendet.
- Regel 9 (Nur berichten was tatsächlich geschehen ist): Eingehalten. Alle Tests wurden automatisiert im Test-Runner ausgeführt.
- Regel 10 (Nichts aus späteren Versionen sichtbar bauen): Eingehalten.

Vorschläge für das PRD:
- keine.

Commit: UX-B: Liste, Einkaufsmodus, Liefern lassen (gepusht: ja)
