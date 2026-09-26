import 'package:drift/drift.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/tables.dart';

part 'daos.g.dart';

/// Exception, wenn die Summe der Zuordnungen eines ListItems dessen Gesamtmenge überschreitet.
class AllocationExceededException implements Exception {
  final int listItemId;
  final int totalAvailable;
  final int attemptedTotal;

  AllocationExceededException({
    required this.listItemId,
    required this.totalAvailable,
    required this.attemptedTotal,
  });

  @override
  String toString() =>
      'AllocationExceededException: Summe der Zuordnungen ($attemptedTotal) übersteigt Gesamtmenge ($totalAvailable) für ListItem $listItemId';
}

/// DAO für Törns, Tage, Crew und Einkaufsstopps.
@DriftAccessor(tables: [Trips, TripDays, CrewMembers, ShoppingStops])
class TripDao extends DatabaseAccessor<AppDatabase> with _$TripDaoMixin {
  TripDao(super.db);

  /// Legt einen neuen Törn an und generiert automatisch:
  /// - Den ersten Einkaufsstopp (Tag 1, "Ersteinkauf")
  /// - Die TripDays für 1..daysCount
  Future<int> createTrip(TripsCompanion trip, {String initialStopName = 'Ersteinkauf Basis'}) {
    return transaction(() async {
      final tripId = await into(trips).insert(trip);

      // 1. Automatisch ersten Einkaufsstopp anlegen
      await into(shoppingStops).insert(
        ShoppingStopsCompanion.insert(
          tripId: tripId,
          dayNumber: const Value(1),
          name: initialStopName,
          isInitial: const Value(true),
        ),
      );

      // 2. TripDays initialisieren
      final days = trip.daysCount.present ? trip.daysCount.value : 7;
      for (int i = 1; i <= days; i++) {
        await into(tripDays).insert(
          TripDaysCompanion.insert(
            tripId: tripId,
            dayNumber: i,
          ),
        );
      }

      return tripId;
    });
  }

  Future<Trip?> getTripById(int id) =>
      (select(trips)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<List<Trip>> getAllTrips() => select(trips).get();

  Future<bool> updateTrip(Trip trip) => update(trips).replace(trip);

  Future<int> deleteTrip(int id) =>
      (delete(trips)..where((tbl) => tbl.id.equals(id))).go();

  // TripDays
  Future<List<TripDay>> getDaysForTrip(int tripId) =>
      (select(tripDays)..where((tbl) => tbl.tripId.equals(tripId))..orderBy([(t) => OrderingTerm.asc(t.dayNumber)])).get();

  Future<bool> updateTripDay(TripDay day) => update(tripDays).replace(day);

  // CrewMembers
  Future<int> addCrewMember(CrewMembersCompanion member) =>
      into(crewMembers).insert(member);

  Future<List<CrewMember>> getCrewForTrip(int tripId) =>
      (select(crewMembers)..where((tbl) => tbl.tripId.equals(tripId))).get();

  Future<bool> updateCrewMember(CrewMember member) =>
      update(crewMembers).replace(member);

  /// Aktualisiert die Zahlungsdaten eines Crew-Mitglieds.
  Future<bool> updateCrewMemberPaymentDetails({
    required int memberId,
    String? iban,
    String? paypalLink,
    String? revolutLink,
  }) async {
    final member = await (select(crewMembers)..where((m) => m.id.equals(memberId))).getSingleOrNull();
    if (member == null) return false;
    return updateCrewMember(member.copyWith(
      iban: Value(iban),
      paypalLink: Value(paypalLink),
      revolutLink: Value(revolutLink),
    ));
  }

  Future<int> deleteCrewMember(int id) =>
      (delete(crewMembers)..where((tbl) => tbl.id.equals(id))).go();

  // ShoppingStops
  Future<int> addShoppingStop(ShoppingStopsCompanion stop) =>
      into(shoppingStops).insert(stop);

  Future<List<ShoppingStop>> getShoppingStopsForTrip(int tripId) =>
      (select(shoppingStops)..where((tbl) => tbl.tripId.equals(tripId))..orderBy([(t) => OrderingTerm.asc(t.dayNumber)])).get();

  Future<bool> updateShoppingStop(ShoppingStop stop) =>
      update(shoppingStops).replace(stop);

  /// Löscht einen Stopp. Der erste/initiale Stopp darf nicht gelöscht werden.
  Future<bool> deleteShoppingStop(int id) async {
    final stop = await (select(shoppingStops)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (stop == null || stop.isInitial) {
      return false; // Erster Stopp bleibt bestehen
    }
    await (delete(shoppingStops)..where((tbl) => tbl.id.equals(id))).go();
    return true;
  }
}

/// DAO für Vorratsliste und Stopp-Zuordnungen mit strenger Constraint-Prüfung.
@DriftAccessor(tables: [ListItems, ListItemAllocations, ShoppingStops])
class ListItemDao extends DatabaseAccessor<AppDatabase> with _$ListItemDaoMixin {
  ListItemDao(super.db);

  Future<int> addListItem(ListItemsCompanion item) =>
      into(listItems).insert(item);

  Future<ListItem?> getListItemById(int id) =>
      (select(listItems)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<List<ListItem>> getListItemsForTrip(int tripId) =>
      (select(listItems)..where((tbl) => tbl.tripId.equals(tripId))).get();

  Future<bool> updateListItem(ListItem item) =>
      update(listItems).replace(item);

  Future<int> deleteListItem(int id) =>
      (delete(listItems)..where((tbl) => tbl.id.equals(id))).go();

  // Allocations & Constraint-Prüfung
  Future<List<ListItemAllocation>> getAllocationsForListItem(int listItemId) =>
      (select(listItemAllocations)..where((tbl) => tbl.listItemId.equals(listItemId))).get();

  Future<List<ListItemAllocation>> getAllocationsForStop(int shoppingStopId) =>
      (select(listItemAllocations)..where((tbl) => tbl.shoppingStopId.equals(shoppingStopId))).get();

  /// Ermittelt die effektive Gesamtpackungszahl eines ListItems (überschrieben oder berechnet).
  int getEffectivePackages(ListItem item) {
    return item.overriddenPackages ?? item.calculatedPackages;
  }

  /// Prüft und setzt die Zuordnung einer Packungsanzahl zu einem Einkaufsstopp.
  /// Gewährleistet das Abnahmekriterium:
  /// Die Summe aller Zuordnungen darf die Gesamtmenge (effektive Packungszahl) nicht überschreiten.
  Future<int> setAllocation({
    required int tripId,
    required int listItemId,
    required int shoppingStopId,
    required int packages,
  }) {
    return transaction(() async {
      final item = await (select(listItems)..where((tbl) => tbl.id.equals(listItemId))).getSingleOrNull();
      if (item == null) {
        throw ArgumentError('ListItem mit ID $listItemId existiert nicht.');
      }

      final totalAvailable = getEffectivePackages(item);

      // Bestehende Allokationen ermitteln
      final existingAllocations = await getAllocationsForListItem(listItemId);
      final otherAllocated = existingAllocations
          .where((a) => a.shoppingStopId != shoppingStopId)
          .fold<int>(0, (sum, a) => sum + a.allocatedPackages);

      final attemptedTotal = otherAllocated + packages;

      if (attemptedTotal > totalAvailable) {
        throw AllocationExceededException(
          listItemId: listItemId,
          totalAvailable: totalAvailable,
          attemptedTotal: attemptedTotal,
        );
      }

      // Bestehende Zuordnung für diesen Stopp suchen
      final currentStopAllocation = existingAllocations
          .where((a) => a.shoppingStopId == shoppingStopId)
          .firstOrNull;

      if (currentStopAllocation != null) {
        if (packages <= 0) {
          await (delete(listItemAllocations)..where((tbl) => tbl.id.equals(currentStopAllocation.id))).go();
          return 0;
        } else {
          await update(listItemAllocations).replace(
            currentStopAllocation.copyWith(allocatedPackages: packages),
          );
          return currentStopAllocation.id;
        }
      } else {
        if (packages > 0) {
          return into(listItemAllocations).insert(
            ListItemAllocationsCompanion.insert(
              tripId: tripId,
              listItemId: listItemId,
              shoppingStopId: shoppingStopId,
              allocatedPackages: packages,
            ),
          );
        }
        return 0;
      }
    });
  }

  /// Berechnet die nicht-zugeordnete Restmenge.
  /// Gemäß Leitplanken: Nicht zugeordnete Mengen gehören automatisch zum ersten Stopp.
  Future<int> getUnallocatedPackages(int listItemId) async {
    final item = await getListItemById(listItemId);
    if (item == null) return 0;
    final total = getEffectivePackages(item);
    final allocations = await getAllocationsForListItem(listItemId);
    final allocated = allocations.fold<int>(0, (sum, a) => sum + a.allocatedPackages);
    final remaining = total - allocated;
    return remaining < 0 ? 0 : remaining;
  }

  /// Überschreibt die Packungsanzahl für ein ListItem oder setzt sie bei null zurück.
  Future<bool> setOverriddenPackages(int listItemId, int? packages) async {
    final item = await getListItemById(listItemId);
    if (item == null) return false;
    return updateListItem(item.copyWith(overriddenPackages: Value(packages)));
  }

  /// Ändert und merkt eine individuelle Packungsgröße für das ListItem.
  Future<bool> setCustomPackageSize(int listItemId, double? packSize) async {
    final item = await getListItemById(listItemId);
    if (item == null) return false;
    return updateListItem(item.copyWith(customPackageSize: Value(packSize)));
  }

  /// Setzt den Auswahlstatus einer Variante (an- oder abgewählt).
  Future<bool> setSelected(int listItemId, bool isSelected) async {
    final item = await getListItemById(listItemId);
    if (item == null) return false;
    return updateListItem(item.copyWith(selected: isSelected));
  }

  /// Setzt den Prüfstatus einer Position (vorhanden / fehlt / nachkaufen).
  Future<bool> setCheckState(int listItemId, CheckItemState state) async {
    final item = await getListItemById(listItemId);
    if (item == null) return false;
    final isSelected = (state == CheckItemState.restock);
    return updateListItem(item.copyWith(
      checkState: state,
      selected: isSelected,
      overriddenPackages: isSelected ? const Value(1) : Value(item.overriddenPackages),
    ));
  }

  /// Setzt den Prozent-Anteil einer Variante innerhalb ihrer Bedarfsgruppe (0.0 bis 1.0).
  Future<bool> setShare(int listItemId, double share) async {
    final item = await getListItemById(listItemId);
    if (item == null) return false;
    return updateListItem(item.copyWith(share: share));
  }

  /// Schaltet den Gekauft-Status (Häkchen) für einen bestimmten Einkaufsstopp um.
  Future<bool> toggleBought({
    required int tripId,
    required int listItemId,
    required int shoppingStopId,
    required bool isBought,
  }) async {
    final allocations = await getAllocationsForListItem(listItemId);
    final stopAlloc = allocations.where((a) => a.shoppingStopId == shoppingStopId).firstOrNull;

    if (stopAlloc != null) {
      return update(listItemAllocations).replace(stopAlloc.copyWith(isBought: isBought));
    } else {
      // Wenn noch keine explizite Teilmenge existiert (z. B. am Ersteinkauf Basis),
      // Allokation mit unallocated Packages anlegen
      final remaining = await getUnallocatedPackages(listItemId);
      final packages = remaining > 0 ? remaining : 1;
      await into(listItemAllocations).insert(
        ListItemAllocationsCompanion.insert(
          tripId: tripId,
          listItemId: listItemId,
          shoppingStopId: shoppingStopId,
          allocatedPackages: packages,
          isBought: Value(isBought),
        ),
      );
      return true;
    }
  }

  /// Schaltet den Eingelagert-Status eines ListItems um.
  Future<void> setStored(int listItemId, bool isStored) async {
    final allocations = await getAllocationsForListItem(listItemId);
    if (allocations.isNotEmpty) {
      for (final a in allocations) {
        await update(listItemAllocations).replace(a.copyWith(isStored: isStored));
      }
    } else {
      final item = await getListItemById(listItemId);
      if (item != null) {
        final stops = await (select(shoppingStops)..where((s) => s.tripId.equals(item.tripId))).get();
        final firstStop = stops.where((s) => s.isInitial).firstOrNull ?? stops.firstOrNull;
        if (firstStop != null) {
          final effective = getEffectivePackages(item);
          await into(listItemAllocations).insert(
            ListItemAllocationsCompanion.insert(
              tripId: item.tripId,
              listItemId: listItemId,
              shoppingStopId: firstStop.id,
              allocatedPackages: effective,
              isStored: Value(isStored),
            ),
          );
        }
      }
    }
  }

  /// Fügt eine benutzerdefinierte Position (SC-LST-05) hinzu.
  Future<int> addCustomItem({
    required int tripId,
    required String name,
    required double quantity,
    required String unit,
    required String department,
    String? categoryId,
    int? shoppingStopId,
  }) async {
    final packages = quantity.ceil();
    final listItemId = await into(listItems).insert(
      ListItemsCompanion.insert(
        tripId: tripId,
        catalogId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        isCustom: const Value(true),
        customName: Value(name),
        customUnit: Value(unit),
        customDepartment: Value(department),
        selected: const Value(true),
        calculatedQuantity: Value(quantity),
        calculatedPackages: Value(packages),
        overriddenPackages: Value(packages),
      ),
    );

    if (shoppingStopId != null) {
      await setAllocation(
        tripId: tripId,
        listItemId: listItemId,
        shoppingStopId: shoppingStopId,
        packages: packages,
      );
    }

    return listItemId;
  }
}

/// DAO für Bordkassenausgaben und Einzahlungen.
@DriftAccessor(tables: [Expenses, KittyPayments])
class ExpenseDao extends DatabaseAccessor<AppDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(super.db);

  Future<int> addExpense(ExpensesCompanion expense) =>
      into(expenses).insert(expense);

  Future<List<Expense>> getExpensesForTrip(int tripId) =>
      (select(expenses)..where((tbl) => tbl.tripId.equals(tripId))).get();

  Future<bool> updateExpense(Expense expense) =>
      update(expenses).replace(expense);

  Future<int> deleteExpense(int id) =>
      (delete(expenses)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> addKittyPayment(KittyPaymentsCompanion payment) =>
      into(kittyPayments).insert(payment);

  Future<List<KittyPayment>> getKittyPaymentsForTrip(int tripId) =>
      (select(kittyPayments)..where((tbl) => tbl.tripId.equals(tripId))).get();

  Future<int> deleteKittyPayment(int id) =>
      (delete(kittyPayments)..where((tbl) => tbl.id.equals(id))).go();

  /// Berechnet die Summe aller getätigten Einzahlungen für einen Törn.
  Future<double> getTotalKittyPayments(int tripId) async {
    final payments = await getKittyPaymentsForTrip(tripId);
    return payments.fold<double>(0.0, (sum, p) => sum + p.amount);
  }

  /// Berechnet die Summe aller Ausgaben aus der gemeinsamen Kasse.
  Future<double> getTotalKittyExpenses(int tripId) async {
    final allExpenses = await getExpensesForTrip(tripId);
    return allExpenses
        .where((e) => e.isPaidFromKitty)
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  }
}