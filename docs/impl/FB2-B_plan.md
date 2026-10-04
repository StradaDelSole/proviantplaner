# Implementierungsplan FB2-B: Oberfläche – Setup, Hinweise, Bedienung, Überlauf

## 1. Ausgangslage & Zielsetzung
Nach der Umsetzung der Rechenlogik in FB2-A (Haltbarkeit, Tiefkühlfach, Bordtank, Gewichts-/Volumenberechnung) verbindet FB2-B die Berechnungen mit der Flutter-Benutzeroberfläche und behebt bestehende UI- und Router-Mängel gemäß `docs/SLICES_v0.19.md` und `docs/impl/FEEDBACK_R2_v0.3.md`.

## 2. Betroffene Komponenten & Dateien
- **Datenbank & Migration (Schema v6)**:
  - `lib/core/database/tables.dart`, `lib/core/database/app_database.dart`, `lib/core/database/app_database.g.dart`: Spalten `hasFreezer`, `freezerCapacity`, `waterTankLiters`, `isWaterTankDrinkable` in Trips-Tabelle und Schema-Migration.
- **Routing & NotFoundScreen**:
  - `lib/core/routing/not_found_screen.dart`: Neuer NotFoundScreen für ungültige oder nicht gefundene Routen.
  - `lib/core/routing/app_router.dart`: Entfernen des `?? 1`-Fallbacks, Weiterleitung ungültiger Pfade auf `NotFoundScreen`.
  - `lib/features/trip/data/trip_provider.dart`: `tripByIdProvider`, `tripDaysByIdProvider`, `tripStopsByIdProvider` zur Validierung existierender IDs.
  - Screen-Ebene (`TripOverviewScreen`, `TripTimelineScreen`, `ShoppingListScreen`, `ShoppingModeScreen`, `StorageChecklistScreen`, `KittyScreen`, `SettlementScreen`, `MoreScreen`): Kontrollierte Anzeige von `NotFoundScreen` bei nicht existierenden numerischen Entitäts-IDs.
- **Törn-Setup UI (Dauer, Tiefkühlfach, Wassertank)**:
  - `lib/features/trip/ui/trip_wizard_screen.dart`:
    - Törndauer mit Schnellchips (3, 7, 10, 14 Tage) und modalem BottomSheet mit CupertinoPicker ("Wählrad...").
    - Schalter für "Tiefkühlfach vorhanden" und Stepper/Direkteingabe für Volumen in Litern.
    - Stepper/Direkteingabe für "Wassertank an Bord (l)" und Schalter "Tankwasser ist trinkbar".
- **Vorratsliste, Hinweise & Gesamtgewicht/-volumen**:
  - `lib/features/shopping_list/data/shopping_list_service.dart`: Übergabe der Setup-Werte an die `QuantityEngine` und Integration von Lagerhinweisen (`storageNotice`) und Resthinweisen (`remainderNotice`) in `ShoppingListItemView`.
  - `lib/features/shopping_list/ui/widgets/item_row_widget.dart`: Darstellung der Lagerhinweise ("braucht Kühlung", "gleich einfrieren") und Resthinweise ("Rest ca. X..."); Überlaufschutz durch flexibles `Wrap`-Layout.
  - `lib/features/shopping_list/ui/widgets/planning_view.dart`: Banner über der Vorratsliste mit aggregiertem Gesamtgewicht (kg) und Gesamtvolumen (l).
- **Lieferbestellungen teilen**:
  - `lib/features/shopping_list/ui/widgets/order_preview_sheet.dart`: WhatsApp als primäre/oberste Option beim Teilen.

## 3. Abnahmekriterien & Teststrategie
1. **Layout-Überlauf**: Zeilenlayout überläuft nicht bei langem Produktnamen, großer Menge und textScale 2.0 (in Hell, Dunkel und Nachtwache).
   - *Test*: `fb2_b_ui_test.dart: FB2-B 1: Zeilenlayout überläuft nicht bei langem Produktnamen, großer Menge und textScale 2.0 (Hell, Dunkel, Nachtwache)`
2. **Router & NotFoundScreen**:
   - Syntaktisch ungültige Route (`/trips/abc`): `fb2_b_ui_test.dart: FB2-B 2: Router zeigt NotFoundScreen bei fehlerhafter Route /trips/abc`
   - Unbekannte numerische Trip-ID (`/trips/99999`): `fb2_b_ui_test.dart: FB2-B 3: Router zeigt NotFoundScreen bei unbekannter numerischer Trip-ID (/trips/99999)`
   - Unbekannter Shopping-Stopp (`/trips/1/shop/99999`): `fb2_b_ui_test.dart: FB2-B 4: Router zeigt NotFoundScreen bei unbekanntem Shopping-Stopp (/trips/1/shop/99999)`
   - Unbekannte Timeline (`/trips/99999/timeline`): `fb2_b_ui_test.dart: FB2-B 5: Router zeigt NotFoundScreen bei unbekannter Timeline (/trips/99999/timeline)`
3. **Setup-Bedienung & Wählrad**: Törndauer per Schnellchips und Cupertino-Wählrad im modalen Sheet.
   - *Test*: `fb2_b_ui_test.dart: FB2-B 6: Törndauer Schnellchips und Wählrad funktionieren wie gefordert`
4. **Setup-Felder Tiefkühlfach & Wassertank**: Persistierung in DB und Weiterleitung an Rechenlogik.
   - *Test*: `fb2_b_ui_test.dart: FB2-B 7: Tiefkühlfach- und Wassertank-Setup persistiert in DB und erreicht Rechenlogik`
5. **Hinweise in der Vorratsliste**: Lagerhinweise ("gleich einfrieren", "braucht Kühlung") und Resthinweise ("Rest ca. X...") erscheinen an den Positionen.
   - *Test*: `fb2_b_ui_test.dart: FB2-B 8: Lagerhinweise und Resthinweise werden in Vorratsliste dargestellt`
6. **Gesamtgewicht & -volumen**: Sichtbare Banner-Anzeige über der Planungsliste.
   - *Test*: `fb2_b_ui_test.dart: FB2-B 9: Gesamtgewicht und -volumen werden über der Planungsliste angezeigt`
7. **WhatsApp Sharing**: WhatsApp als erste Option im Liefer-Sharing-Sheet.
   - *Test*: `fb2_b_ui_test.dart: FB2-B 10: WhatsApp ist die erste Option beim Teilen von Lieferbestellungen`
