import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/daos.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('S1 Abnahmekriterium: Summe der Zuordnungen eines ListItem kann Gesamtmenge nicht überschreiten', () {
    test('Erfolgreiche Allokation innerhalb der Gesamtmenge und Sperre bei Überschreitung', () async {
      // 1. Törn anlegen
      final tripId = await db.tripDao.createTrip(
        TripsCompanion.insert(
          name: 'Allokation Törn',
          startDate: DateTime(2026, 9, 1),
          daysCount: const Value(7),
        ),
      );

      // Stopps ermitteln (Initialer Stopp 1 existiert)
      final stops = await db.tripDao.getShoppingStopsForTrip(tripId);
      final stop1 = stops.first;

      // Stopp 2 an Tag 4 anlegen
      final stop2Id = await db.tripDao.addShoppingStop(
        ShoppingStopsCompanion.insert(
          tripId: tripId,
          dayNumber: const Value(4),
          name: 'Hvar Nachkauf',
        ),
      );

      // 2. ListItem mit 5 Packungen anlegen
      final itemId = await db.listItemDao.addListItem(
        ListItemsCompanion.insert(
          tripId: tripId,
          catalogId: 'bread_baguette',
          calculatedQuantity: const Value(5.0),
          calculatedPackages: const Value(5),
        ),
      );

      // Anfangs: 5 unzugeordnete Packungen (gehören automatisch zum ersten Stopp)
      expect(await db.listItemDao.getUnallocatedPackages(itemId), 5);

      // 3. 2 Packungen zu Stop 2 zuordnen (z. B. 2 Baguettes an Tag 4)
      await db.listItemDao.setAllocation(
        tripId: tripId,
        listItemId: itemId,
        shoppingStopId: stop2Id,
        packages: 2,
      );

      // Restmenge für Stop 1 beträgt nun 3
      expect(await db.listItemDao.getUnallocatedPackages(itemId), 3);

      // 4. Weiteren Stopp 3 an Tag 6 anlegen
      final stop3Id = await db.tripDao.addShoppingStop(
        ShoppingStopsCompanion.insert(
          tripId: tripId,
          dayNumber: const Value(6),
          name: 'Vis Bäckerei',
        ),
      );

      // 3 Packungen zu Stop 3 zuordnen -> Summe = 2 + 3 = 5 (genau die Gesamtmenge)
      await db.listItemDao.setAllocation(
        tripId: tripId,
        listItemId: itemId,
        shoppingStopId: stop3Id,
        packages: 3,
      );

      expect(await db.listItemDao.getUnallocatedPackages(itemId), 0);

      // 5. Versuch: 1 weitere Packung zu Stop 1 zuordnen -> Summe wäre 2 + 3 + 1 = 6 > 5
      // Muss fehlschlagen mit AllocationExceededException!
      expect(
        () => db.listItemDao.setAllocation(
          tripId: tripId,
          listItemId: itemId,
          shoppingStopId: stop1.id,
          packages: 1,
        ),
        throwsA(isA<AllocationExceededException>()),
      );

      // 6. Wenn der Nutzer die Gesamtmenge manuell auf 8 überschreibt:
      final item = await db.listItemDao.getListItemById(itemId);
      await db.listItemDao.updateListItem(
        item!.copyWith(overriddenPackages: const Value(8)),
      );

      // Nun sind 8 verfügbar, 5 allokiert -> Zuordnung von 2 weiteren Packungen (Summe = 7 <= 8) muss gelingen
      await db.listItemDao.setAllocation(
        tripId: tripId,
        listItemId: itemId,
        shoppingStopId: stop1.id,
        packages: 2,
      );

      expect(await db.listItemDao.getUnallocatedPackages(itemId), 1);

      // Überschreitung über 8 (z.B. Versuch, Stop 1 auf 4 zu setzen, Summe = 2 + 3 + 4 = 9 > 8) muss scheitern
      expect(
        () => db.listItemDao.setAllocation(
          tripId: tripId,
          listItemId: itemId,
          shoppingStopId: stop1.id,
          packages: 4,
        ),
        throwsA(isA<AllocationExceededException>()),
      );
    });
  });
}