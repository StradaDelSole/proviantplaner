/// Riverpod-Provider für Törn-Verwaltung, Service und reaktiven Status (Slice S3).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/daos.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/services/backup_coordinator.dart';
import 'package:proviantplaner/core/services/backup_providers.dart';
import 'package:proviantplaner/features/kitty/data/kitty_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'boat_profile_service.dart';
import 'trip_service.dart';

Future<T> _runGuardedTripRead<T>(
  Ref ref,
  String operationName,
  Future<T> Function(TripDao dao) action,
) {
  final dao = ref.watch(tripDaoProvider);
  final receiptFileService = ref.watch(receiptFileServiceProvider);
  return BackupCoordinator.runSynchronizedStorageOperation(
    db: dao.attachedDatabase,
    receiptFileService: receiptFileService,
    operationName: operationName,
    action: () => action(dao),
  );
}

/// Versionierung für Törn-Daten zur reaktiven Invalidierung ohne zirkuläre Abhängigkeiten.
final tripDataVersionProvider = StateProvider.family<int, int>((ref, tripId) => 0);

/// Singleton Provider für das CatalogRepository.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final repo = CatalogRepository();
  repo.loadFromBundle();
  return repo;
});

/// Provider für den TripService.
final tripServiceProvider = Provider<TripService>((ref) {
  final service = TripService(
    tripDao: ref.watch(tripDaoProvider),
    listItemDao: ref.watch(listItemDaoProvider),
    catalogRepository: ref.watch(catalogRepositoryProvider),
    boatProfileDao: ref.watch(boatProfileDaoProvider),
    expenseDao: ref.watch(expenseDaoProvider),
    receiptFileService: ref.watch(receiptFileServiceProvider),
  );
  service.onTripDataChanged = (tripId) {
    ref.invalidate(tripCrewByIdProvider(tripId));
    ref.invalidate(tripDaysByIdProvider(tripId));
    ref.invalidate(tripStopsByIdProvider(tripId));
    ref.invalidate(tripByIdProvider(tripId));
    ref.read(tripDataVersionProvider(tripId).notifier).update((v) => v + 1);
  };
  return service;
});

/// Provider für den BoatProfileService (PIVOT3-A).
final boatProfileServiceProvider = Provider<BoatProfileService>((ref) {
  return BoatProfileService(
    boatProfileDao: ref.watch(boatProfileDaoProvider),
    receiptFileService: ref.watch(receiptFileServiceProvider),
  );
});

/// Provider für alle aktiven Bootsprofile.
final activeBoatProfilesProvider = FutureProvider<List<BoatProfile>>((ref) async {
  await ref.watch(appStartupRecoveryProvider.future);
  final service = ref.watch(boatProfileServiceProvider);
  return service.getActiveProfiles();
});

/// Aktuell ausgewählte Trip-ID (Standard: erster vorhandener Trip oder null).
final activeTripIdProvider = StateProvider<int?>((ref) => null);

/// Provider für alle Törns.
final allTripsProvider = FutureProvider<List<Trip>>((ref) async {
  await ref.watch(appStartupRecoveryProvider.future);
  return _runGuardedTripRead(ref, 'allTripsProvider', (dao) => dao.getAllTrips());
});

/// Provider für den aktuell aktiven Törn.
final activeTripProvider = FutureProvider<Trip?>((ref) async {
  await ref.watch(appStartupRecoveryProvider.future);
  final tripId = ref.watch(activeTripIdProvider);
  if (tripId == null) {
    final all = await ref.watch(allTripsProvider.future);
    return all.firstOrNull;
  }
  return _runGuardedTripRead(ref, 'activeTripProvider', (dao) => dao.getTripById(tripId));
});

/// Provider für die Tage des aktuell aktiven Törns.
final activeTripDaysProvider = FutureProvider<List<TripDay>>((ref) async {
  final activeTrip = await ref.watch(activeTripProvider.future);
  if (activeTrip == null) return [];
  return _runGuardedTripRead(
    ref,
    'activeTripDaysProvider',
    (dao) => dao.getDaysForTrip(activeTrip.id),
  );
});

/// Provider für die Einkaufsstopps des aktuell aktiven Törns.
final activeTripStopsProvider = FutureProvider<List<ShoppingStop>>((ref) async {
  final activeTrip = await ref.watch(activeTripProvider.future);
  if (activeTrip == null) return [];
  return _runGuardedTripRead(
    ref,
    'activeTripStopsProvider',
    (dao) => dao.getShoppingStopsForTrip(activeTrip.id),
  );
});

/// Provider für die Crew des aktuell aktiven Törns.
final activeTripCrewProvider = FutureProvider<List<CrewMember>>((ref) async {
  final activeTrip = await ref.watch(activeTripProvider.future);
  if (activeTrip == null) return [];
  return _runGuardedTripRead(
    ref,
    'activeTripCrewProvider',
    (dao) => dao.getCrewForTrip(activeTrip.id),
  );
});

/// Provider für einen Törn nach ID (FB2-B).
final tripByIdProvider = FutureProvider.family<Trip?, int>((ref, tripId) async {
  await ref.watch(appStartupRecoveryProvider.future);
  return _runGuardedTripRead(ref, 'tripByIdProvider', (dao) => dao.getTripById(tripId));
});

/// Provider für die Tage eines Törns nach ID (FB2-B).
final tripDaysByIdProvider = FutureProvider.family<List<TripDay>, int>((ref, tripId) async {
  await ref.watch(appStartupRecoveryProvider.future);
  return _runGuardedTripRead(
    ref,
    'tripDaysByIdProvider',
    (dao) => dao.getDaysForTrip(tripId),
  );
});

/// Provider für die Einkaufsstopps eines Törns nach ID (FB2-B).
final tripStopsByIdProvider = FutureProvider.family<List<ShoppingStop>, int>((ref, tripId) async {
  await ref.watch(appStartupRecoveryProvider.future);
  return _runGuardedTripRead(
    ref,
    'tripStopsByIdProvider',
    (dao) => dao.getShoppingStopsForTrip(tripId),
  );
});

/// Provider für die Crew eines Törns nach ID (PIVOT2).
final tripCrewByIdProvider = FutureProvider.family<List<CrewMember>, int>((ref, tripId) async {
  await ref.watch(appStartupRecoveryProvider.future);
  return _runGuardedTripRead(
    ref,
    'tripCrewByIdProvider',
    (dao) => dao.getCrewForTrip(tripId),
  );
});
