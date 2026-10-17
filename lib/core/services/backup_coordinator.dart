/// Koordinator für Datensicherung und Wiederherstellung (Slice S8).
/// Serialisiert alle SQLite-Tabellen in JSON und stellt sie transaktionssicher wieder her.
library;

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';
import 'package:proviantplaner/core/services/hullq_backup_service.dart';
import 'package:proviantplaner/core/services/receipt_file_service.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';

/// Verwaltet den Export aller lokalen Törndaten in die Cloud und den Import daraus.
class BackupCoordinator {
  final AppDatabase _db;
  final HullqBackupService _backupService;
  final HullqAuthService _authService;
  final ReceiptFileService _receiptFileService;

  BackupCoordinator({
    required AppDatabase db,
    required HullqBackupService backupService,
    required HullqAuthService authService,
    ReceiptFileService? receiptFileService,
  })  : _db = db,
        _backupService = backupService,
        _authService = authService,
        _receiptFileService = receiptFileService ?? ReceiptFileService();

  /// Prüft, ob eine Sicherung in der Cloud existiert.
  Future<bool> hasBackup() async {
    final data = await _backupService.restoreData();
    return data != null && data.isNotEmpty;
  }

  /// Erstellt eine Sicherung aller Törns.
  /// Gemäß PRD nur für angemeldete Mitglieder verfügbar.
  Future<bool> createBackup() async {
    final status = await _authService.getMembershipStatus();
    if (status == HullqMembershipStatus.trial) {
      throw StateError('Sicherung ist nur für angemeldete HullQ-Mitglieder verfügbar.');
    }

    final allTrips = await _db.tripDao.getAllTrips();
    final allBoatProfiles = await _db.boatProfileDao.getAllProfiles(includeArchived: true);
    final tripsBackupList = <Map<String, dynamic>>[];

    for (final trip in allTrips) {
      final days = await _db.tripDao.getDaysForTrip(trip.id);
      final crew = await _db.tripDao.getCrewForTrip(trip.id);
      final stops = await _db.tripDao.getShoppingStopsForTrip(trip.id);
      final items = await _db.listItemDao.getListItemsForTrip(trip.id);

      final allocations = <ListItemAllocation>[];
      for (final item in items) {
        final itemAllocations = await _db.listItemDao.getAllocationsForListItem(item.id);
        allocations.addAll(itemAllocations);
      }

      final expenses = await _db.expenseDao.getExpensesForTrip(trip.id);
      final payments = await _db.expenseDao.getKittyPaymentsForTrip(trip.id);
      final receipts = await _db.expenseDao.getReceiptsForTrip(trip.id);

      final receiptsBackup = <Map<String, dynamic>>[];
      for (final r in receipts) {
        final bytes = await _receiptFileService.readReceiptBytes(r.filePath);
        receiptsBackup.add({
          'id': r.id,
          'tripId': r.tripId,
          'expenseId': r.expenseId,
          'filePath': r.filePath,
          'fileName': r.fileName,
          'byteSize': r.byteSize,
          'sortOrder': r.sortOrder,
          'createdAt': r.createdAt.toIso8601String(),
          'imageBase64': bytes != null ? base64Encode(bytes) : null,
        });
      }


      tripsBackupList.add({
        'trip': _serializeTrip(trip),
        'days': days.map(_serializeDay).toList(),
        'crew': crew.map(_serializeCrew).toList(),
        'stops': stops.map(_serializeStop).toList(),
        'items': items.map(_serializeListItem).toList(),
        'allocations': allocations.map(_serializeAllocation).toList(),
        'expenses': expenses.map(_serializeExpense).toList(),
        'payments': payments.map(_serializePayment).toList(),
        'receipts': receiptsBackup,
      });
    }

    final backupPayload = jsonEncode({
      'version': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'boatProfiles': allBoatProfiles.map(_serializeBoatProfile).toList(),
      'trips': tripsBackupList,
    });

    return _backupService.backupData(backupPayload);
  }

  /// Stellt alle gesicherten Törns und Bootsprofile wieder her.
  /// Gewährleistet relationale Integrität durch Neu-Verknüpfung der generierten IDs.
  Future<bool> restoreBackup() async {
    final status = await _authService.getMembershipStatus();
    if (status == HullqMembershipStatus.trial) {
      throw StateError('Wiederherstellung ist nur für angemeldete HullQ-Mitglieder verfügbar.');
    }

    final jsonStr = await _backupService.restoreData();
    if (jsonStr == null || jsonStr.isEmpty) {
      return false;
    }

    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    final rawProfiles = decoded['boatProfiles'] as List<dynamic>? ?? [];
    final tripsList = decoded['trips'] as List<dynamic>? ?? [];

    await _db.transaction(() async {
      // Vorhandene Daten bereinigen
      await _db.customStatement('PRAGMA foreign_keys = OFF');
      try {
        await _db.delete(_db.expenseReceipts).go();
        await _db.delete(_db.kittyPayments).go();
        await _db.delete(_db.expenses).go();
        await _db.delete(_db.listItemAllocations).go();
        await _db.delete(_db.listItems).go();
        await _db.delete(_db.shoppingStops).go();
        await _db.delete(_db.crewMembers).go();
        await _db.delete(_db.tripDays).go();
        await _db.delete(_db.trips).go();
        await _db.delete(_db.boatProfiles).go();


        // 0. Bootsprofile einfügen (falls in Backup vorhanden)
        final profileIdMap = <int, int>{};
        for (final rawProfile in rawProfiles) {
          final pMap = rawProfile as Map<String, dynamic>;
          final oldProfileId = pMap['id'] as int;
          final newProfileId = await _db.into(_db.boatProfiles).insert(
            BoatProfilesCompanion.insert(
              name: pMap['name'] as String,
              manufacturer: Value(pMap['manufacturer'] as String?),
              model: Value(pMap['model'] as String?),
              fridgeCapacity: Value(pMap['fridgeCapacity'] as int? ?? 100),
              hasFreezer: Value(pMap['hasFreezer'] as bool? ?? false),
              freezerCapacity: Value(pMap['freezerCapacity'] as int? ?? 0),
              waterTankLiters: Value(pMap['waterTankLiters'] as int? ?? 0),
              isWaterTankDrinkable: Value(pMap['isWaterTankDrinkable'] as bool? ?? false),
              hasWatermaker: Value(pMap['hasWatermaker'] as bool? ?? false),
              isArchived: Value(pMap['isArchived'] as bool? ?? false),
              createdAt: pMap['createdAt'] != null
                  ? Value(DateTime.parse(pMap['createdAt'] as String))
                  : const Value.absent(),
            ),
          );
          profileIdMap[oldProfileId] = newProfileId;
        }

        for (final rawTripData in tripsList) {
          final tripData = rawTripData as Map<String, dynamic>;
          final tMap = tripData['trip'] as Map<String, dynamic>;

          // 1. Trip einfügen
          final oldBoatProfileId = tMap['boatProfileId'] as int?;
          final newBoatProfileId = oldBoatProfileId != null ? profileIdMap[oldBoatProfileId] : null;

          final newTripId = await _db.into(_db.trips).insert(
            TripsCompanion.insert(
              name: tMap['name'] as String,
              startDate: DateTime.parse(tMap['startDate'] as String),
              region: Value(tMap['region'] as String? ?? 'warm'),
              climate: Value(tMap['climate'] as String? ??
                  (tMap['region'] == 'temperate'
                      ? 'cool'
                      : (tMap['region'] == 'hot_or_remote' ? 'hot' : 'warm'))),
              isCharter: Value(tMap['isCharter'] as bool? ?? true),
              boatProfileId: Value(newBoatProfileId),
              boatName: Value(tMap['boatName'] as String?),
              boatManufacturer: Value(tMap['boatManufacturer'] as String?),
              boatModel: Value(tMap['boatModel'] as String?),
              boatType: Value(tMap['boatType'] as String? ?? 'mono'),
              fridgeCapacity: Value(tMap['fridgeCapacity'] as int? ?? 100),
              appetite: tMap['appetite'] != null
                  ? Value(CrewAppetite.fromString(tMap['appetite'] as String))
                  : const Value.absent(),
              reserveDays: Value(tMap['reserveDays'] as String? ?? 'few_days'),
              drinkingHabit: tMap['drinkingHabit'] != null
                  ? Value(CrewDrinking.fromString(tMap['drinkingHabit'] as String))
                  : const Value.absent(),
              hasStorageChecklist: Value(tMap['hasStorageChecklist'] as bool? ?? true),
              phase: tMap['phase'] != null
                  ? Value(TripPhase.fromString(tMap['phase'] as String))
                  : const Value.absent(),
              isArchived: Value(tMap['isArchived'] as bool? ?? false),
              currency: Value(tMap['currency'] as String? ?? 'EUR'),
              kittyModel: tMap['kittyModel'] != null
                  ? Value(KittyModel.fromString(tMap['kittyModel'] as String))
                  : const Value.absent(),
              hasFreezer: Value(tMap['hasFreezer'] as bool? ?? false),
              freezerCapacity: Value(tMap['freezerCapacity'] as int? ?? 0),
              waterTankLiters: Value(tMap['waterTankLiters'] as int? ?? 0),
              isWaterTankDrinkable: Value(tMap['isWaterTankDrinkable'] as bool? ?? false),
              hasWatermaker: Value(tMap['hasWatermaker'] as bool? ?? false),
              createdAt: tMap['createdAt'] != null
                  ? Value(DateTime.parse(tMap['createdAt'] as String))
                  : const Value.absent(),
            ),
          );

          final stopIdMap = <int, int>{};
          final crewIdMap = <int, int>{};
          final listItemIdMap = <int, int>{};

          // 2. ShoppingStops einfügen
          final stops = tripData['stops'] as List<dynamic>? ?? [];
          for (final s in stops) {
            final sMap = s as Map<String, dynamic>;
            final oldStopId = sMap['id'] as int;
            final newStopId = await _db.into(_db.shoppingStops).insert(
              ShoppingStopsCompanion.insert(
                tripId: newTripId,
                name: sMap['name'] as String,
                dayNumber: Value(sMap['dayNumber'] as int? ?? 1),
                isInitial: Value(sMap['isInitial'] as bool? ?? false),
              ),
            );
            stopIdMap[oldStopId] = newStopId;
          }

          // 3. TripDays einfügen
          final days = tripData['days'] as List<dynamic>? ?? [];
          for (final d in days) {
            final dMap = d as Map<String, dynamic>;
            await _db.into(_db.tripDays).insert(
              TripDaysCompanion.insert(
                tripId: newTripId,
                dayNumber: dMap['dayNumber'] as int,
                lunchRestaurant: Value(dMap['lunchRestaurant'] as bool? ?? false),
                dinnerRestaurant: Value(dMap['dinnerRestaurant'] as bool? ?? false),
                dayType: Value(dMap['dayType'] as String?),
                portName: Value(dMap['portName'] as String?),
              ),
            );
          }

          // 4. CrewMembers einfügen
          final crew = tripData['crew'] as List<dynamic>? ?? [];
          for (final c in crew) {
            final cMap = c as Map<String, dynamic>;
            final oldCrewId = cMap['id'] as int;
            final newCrewId = await _db.into(_db.crewMembers).insert(
              CrewMembersCompanion.insert(
                tripId: newTripId,
                name: cMap['name'] as String,
                isChild: Value(cMap['isChild'] as bool? ?? false),
                isVegetarian: Value(cMap['isVegetarian'] as bool? ?? false),
                isNonDrinker: Value(cMap['isNonDrinker'] as bool? ?? false),
                customEatLevel: Value(cMap['customEatLevel'] as String?),
                customDrinkLevel: Value(cMap['customDrinkLevel'] as String?),
                categoryParticipation: Value(cMap['categoryParticipation'] as String? ?? '{"all": true}'),
                isSkipperFree: Value(cMap['isSkipperFree'] as bool? ?? false),
                skipperFreeScope: Value(cMap['skipperFreeScope'] as String?),
              ),
            );
            crewIdMap[oldCrewId] = newCrewId;
          }

          // Falls treasurerMemberId vorhanden, jetzt über crewIdMap aktualisieren
          if (tMap['treasurerMemberId'] != null) {
            final oldTreasurerId = tMap['treasurerMemberId'] as int;
            final newTreasurerId = crewIdMap[oldTreasurerId];
            if (newTreasurerId != null) {
              await (_db.update(_db.trips)..where((t) => t.id.equals(newTripId))).write(
                TripsCompanion(treasurerMemberId: Value(newTreasurerId)),
              );
            }
          }

          // 5. ListItems einfügen
          final items = tripData['items'] as List<dynamic>? ?? [];
          for (final i in items) {
            final iMap = i as Map<String, dynamic>;
            final oldItemId = iMap['id'] as int;
            final newItemId = await _db.into(_db.listItems).insert(
              ListItemsCompanion.insert(
                tripId: newTripId,
                catalogId: iMap['catalogId'] as String,
                isCustom: Value(iMap['isCustom'] as bool? ?? false),
                customName: Value(iMap['customName'] as String?),
                customUnit: Value(iMap['customUnit'] as String?),
                customDepartment: Value(iMap['customDepartment'] as String?),
                selected: Value(iMap['selected'] as bool? ?? true),
                share: Value(iMap['share'] as double? ?? 1.0),
                calculatedQuantity: Value(iMap['calculatedQuantity'] as double? ?? 0.0),
                calculatedPackages: Value(iMap['calculatedPackages'] as int? ?? 1),
                overriddenPackages: Value(iMap['overriddenPackages'] as int?),
                customPackageSize: Value(iMap['customPackageSize'] as double?),
              ),
            );
            listItemIdMap[oldItemId] = newItemId;
          }

          // 6. ListItemAllocations einfügen
          final allocations = tripData['allocations'] as List<dynamic>? ?? [];
          for (final a in allocations) {
            final aMap = a as Map<String, dynamic>;
            final oldItemId = aMap['listItemId'] as int;
            final oldStopId = aMap['shoppingStopId'] as int;
            final newItemId = listItemIdMap[oldItemId];
            final newStopId = stopIdMap[oldStopId];
            if (newItemId != null && newStopId != null) {
              await _db.into(_db.listItemAllocations).insert(
                ListItemAllocationsCompanion.insert(
                  tripId: newTripId,
                  listItemId: newItemId,
                  shoppingStopId: newStopId,
                  allocatedPackages: aMap['allocatedPackages'] as int,
                  isBought: Value(aMap['isBought'] as bool? ?? false),
                  isStored: Value(aMap['isStored'] as bool? ?? false),
                ),
              );
            }
          }

          // 7. Expenses einfügen
          final expenseIdMap = <int, int>{};
          final expenses = tripData['expenses'] as List<dynamic>? ?? [];
          for (final e in expenses) {
            final eMap = e as Map<String, dynamic>;
            final oldExpenseId = eMap['id'] as int;
            final oldPayerId = eMap['paidByCrewMemberId'] as int?;
            if (oldPayerId != null && !crewIdMap.containsKey(oldPayerId)) {
              throw StateError(
                'Cannot restore expense: payer ID $oldPayerId could not be mapped to restored crew.',
              );
            }
            final newPayerId = oldPayerId != null ? crewIdMap[oldPayerId] : null;

            String? remappedCustomSplit;
            final rawSplit = eMap['customSplit'] as String?;
            if (rawSplit != null && rawSplit.isNotEmpty) {
              final dynamic decoded = jsonDecode(rawSplit);
              if (decoded is Map) {
                final remappedMap = <String, dynamic>{};
                for (final entry in decoded.entries) {
                  final oldId = int.tryParse(entry.key.toString());
                  if (oldId == null || !crewIdMap.containsKey(oldId)) {
                    throw StateError(
                      'Cannot restore custom split: member ID ${entry.key} could not be mapped to restored crew.',
                    );
                  }
                  final newId = crewIdMap[oldId]!;
                  remappedMap[newId.toString()] = entry.value;
                }
                remappedCustomSplit = jsonEncode(remappedMap);
              } else {
                remappedCustomSplit = rawSplit;
              }
            }

            final newExpenseId = await _db.into(_db.expenses).insert(
              ExpensesCompanion.insert(
                tripId: newTripId,
                amount: eMap['amount'] as double,
                currency: Value(eMap['currency'] as String? ?? 'EUR'),
                category: ExpenseCategory.fromString(eMap['category'] as String),
                paidByCrewMemberId: Value(newPayerId),
                isPaidFromKitty: Value(eMap['isPaidFromKitty'] as bool? ?? false),
                customSplit: Value(remappedCustomSplit),
                note: Value(eMap['note'] as String?),
                createdAt: eMap['createdAt'] != null
                    ? Value(DateTime.parse(eMap['createdAt'] as String))
                    : const Value.absent(),
              ),
            );
            expenseIdMap[oldExpenseId] = newExpenseId;
          }

          // 8. KittyPayments einfügen
          final payments = tripData['payments'] as List<dynamic>? ?? [];
          for (final p in payments) {
            final pMap = p as Map<String, dynamic>;
            final oldMemberId = pMap['crewMemberId'] as int;
            if (!crewIdMap.containsKey(oldMemberId)) {
              throw StateError(
                'Cannot restore kitty payment: member ID $oldMemberId could not be mapped to restored crew.',
              );
            }
            final newMemberId = crewIdMap[oldMemberId]!;
            await _db.into(_db.kittyPayments).insert(
              KittyPaymentsCompanion.insert(
                tripId: newTripId,
                crewMemberId: newMemberId,
                amount: pMap['amount'] as double,
                paidAt: pMap['paidAt'] != null
                    ? Value(DateTime.parse(pMap['paidAt'] as String))
                    : const Value.absent(),
              ),
            );
          }

          // 9. Receipts einfügen (RECEIPT1)
          final receipts = tripData['receipts'] as List<dynamic>? ?? [];
          for (final r in receipts) {
            final rMap = r as Map<String, dynamic>;
            final oldExpenseId = rMap['expenseId'] as int;
            final newExpenseId = expenseIdMap[oldExpenseId];
            if (newExpenseId != null) {
              final base64Image = rMap['imageBase64'] as String?;
              final fileName = rMap['fileName'] as String? ?? 'receipt.jpg';
              String filePath = rMap['filePath'] as String? ?? rMap['relativePath'] as String? ?? '';
              int byteSize = rMap['byteSize'] as int? ?? rMap['fileSize'] as int? ?? 0;

              if (base64Image != null && base64Image.isNotEmpty) {
                final imageBytes = base64Decode(base64Image);
                byteSize = imageBytes.length;
                final processed = await _receiptFileService.saveRawReceiptBytes(
                  tripId: newTripId,
                  expenseId: newExpenseId,
                  bytes: imageBytes,
                  fileName: fileName,
                );
                filePath = processed.filePath;
              }

              await _db.into(_db.expenseReceipts).insert(
                ExpenseReceiptsCompanion.insert(
                  tripId: newTripId,
                  expenseId: newExpenseId,
                  filePath: filePath,
                  fileName: fileName,
                  byteSize: Value(byteSize),
                  sortOrder: Value(rMap['sortOrder'] as int? ?? 0),
                  createdAt: rMap['createdAt'] != null
                      ? Value(DateTime.parse(rMap['createdAt'] as String))
                      : const Value.absent(),
                ),
              );

            }
          }

        }
      } finally {
        await _db.customStatement('PRAGMA foreign_keys = ON');
      }
    });

    return true;
  }

  Map<String, dynamic> _serializeTrip(Trip t) => {
        'id': t.id,
        'name': t.name,
        'startDate': t.startDate.toIso8601String(),
        'daysCount': t.daysCount,
        'region': t.region,
        'climate': t.climate,
        'isCharter': t.isCharter,
        'boatProfileId': t.boatProfileId,
        'boatName': t.boatName,
        'boatManufacturer': t.boatManufacturer,
        'boatModel': t.boatModel,
        'boatType': t.boatType,
        'fridgeCapacity': t.fridgeCapacity,
        'hasFreezer': t.hasFreezer,
        'freezerCapacity': t.freezerCapacity,
        'waterTankLiters': t.waterTankLiters,
        'isWaterTankDrinkable': t.isWaterTankDrinkable,
        'hasWatermaker': t.hasWatermaker,
        'appetite': t.appetite.rawValue,
        'reserveDays': t.reserveDays,
        'drinkingHabit': t.drinkingHabit.rawValue,
        'hasStorageChecklist': t.hasStorageChecklist,
        'phase': t.phase.rawValue,
        'isArchived': t.isArchived,
        'currency': t.currency,
        'kittyModel': t.kittyModel.rawValue,
        'treasurerMemberId': t.treasurerMemberId,
        'createdAt': t.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _serializeBoatProfile(BoatProfile p) => {
        'id': p.id,
        'name': p.name,
        'manufacturer': p.manufacturer,
        'model': p.model,
        'fridgeCapacity': p.fridgeCapacity,
        'hasFreezer': p.hasFreezer,
        'freezerCapacity': p.freezerCapacity,
        'waterTankLiters': p.waterTankLiters,
        'isWaterTankDrinkable': p.isWaterTankDrinkable,
        'hasWatermaker': p.hasWatermaker,
        'isArchived': p.isArchived,
        'createdAt': p.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _serializeDay(TripDay d) => {
        'id': d.id,
        'tripId': d.tripId,
        'dayNumber': d.dayNumber,
        'lunchRestaurant': d.lunchRestaurant,
        'dinnerRestaurant': d.dinnerRestaurant,
        'dayType': d.dayType,
        'portName': d.portName,
      };

  Map<String, dynamic> _serializeStop(ShoppingStop s) => {
        'id': s.id,
        'tripId': s.tripId,
        'dayNumber': s.dayNumber,
        'name': s.name,
        'isInitial': s.isInitial,
      };

  Map<String, dynamic> _serializeCrew(CrewMember c) => {
        'id': c.id,
        'tripId': c.tripId,
        'name': c.name,
        'isChild': c.isChild,
        'isVegetarian': c.isVegetarian,
        'isNonDrinker': c.isNonDrinker,
        'customEatLevel': c.customEatLevel,
        'customDrinkLevel': c.customDrinkLevel,
        'categoryParticipation': c.categoryParticipation,
        'isSkipperFree': c.isSkipperFree,
        'skipperFreeScope': c.skipperFreeScope,
      };

  Map<String, dynamic> _serializeListItem(ListItem i) => {
        'id': i.id,
        'tripId': i.tripId,
        'catalogId': i.catalogId,
        'isCustom': i.isCustom,
        'customName': i.customName,
        'customUnit': i.customUnit,
        'customDepartment': i.customDepartment,
        'selected': i.selected,
        'share': i.share,
        'calculatedQuantity': i.calculatedQuantity,
        'calculatedPackages': i.calculatedPackages,
        'overriddenPackages': i.overriddenPackages,
        'customPackageSize': i.customPackageSize,
      };

  Map<String, dynamic> _serializeAllocation(ListItemAllocation a) => {
        'id': a.id,
        'tripId': a.tripId,
        'listItemId': a.listItemId,
        'shoppingStopId': a.shoppingStopId,
        'allocatedPackages': a.allocatedPackages,
        'isBought': a.isBought,
        'isStored': a.isStored,
      };

  Map<String, dynamic> _serializeExpense(Expense e) => {
        'id': e.id,
        'tripId': e.tripId,
        'amount': e.amount,
        'currency': e.currency,
        'category': e.category.rawValue,
        'paidByCrewMemberId': e.paidByCrewMemberId,
        'isPaidFromKitty': e.isPaidFromKitty,
        'customSplit': e.customSplit,
        'note': e.note,
        'createdAt': e.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _serializePayment(KittyPayment p) => {
        'id': p.id,
        'tripId': p.tripId,
        'crewMemberId': p.crewMemberId,
        'amount': p.amount,
        'paidAt': p.paidAt.toIso8601String(),
      };
}
