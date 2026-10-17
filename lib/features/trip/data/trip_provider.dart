/// Riverpod-Provider für Törn-Verwaltung, Service und reaktiven Status (Slice S3).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'boat_profile_service.dart';
import 'trip_service.dart';

/// Singleton Provider für das CatalogRepository.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final repo = CatalogRepository();
  repo.loadFromBundle();
  return repo;
});

/// Provider für den TripService.
final tripServiceProvider = Provider<TripService>((ref) {
  return TripService(
    tripDao: ref.watch(tripDaoProvider),
    listItemDao: ref.watch(listItemDaoProvider),
    catalogRepository: ref.watch(catalogRepositoryProvider),
    boatProfileDao: ref.watch(boatProfileDaoProvider),
    expenseDao: ref.watch(expenseDaoProvider),
  );
});

/// Provider für den BoatProfileService (PIVOT3-A).
final boatProfileServiceProvider = Provider<BoatProfileService>((ref) {
  return BoatProfileService(
    boatProfileDao: ref.watch(boatProfileDaoProvider),
  );
});

/// Provider für alle aktiven Bootsprofile.
final activeBoatProfilesProvider = FutureProvider<List<BoatProfile>>((ref) async {
  final service = ref.watch(boatProfileServiceProvider);
  return service.getActiveProfiles();
});

/// Aktuell ausgewählte Trip-ID (Standard: erster vorhandener Trip oder null).
final activeTripIdProvider = StateProvider<int?>((ref) => null);

/// Provider für alle Törns.
final allTripsProvider = FutureProvider<List<Trip>>((ref) async {
  final dao = ref.watch(tripDaoProvider);
  return dao.getAllTrips();
});

/// Provider für den aktuell aktiven Törn.
final activeTripProvider = FutureProvider<Trip?>((ref) async {
  final tripId = ref.watch(activeTripIdProvider);
  if (tripId == null) {
    final all = await ref.watch(allTripsProvider.future);
    return all.firstOrNull;
  }
  final dao = ref.watch(tripDaoProvider);
  return dao.getTripById(tripId);
});

/// Provider für die Tage des aktuell aktiven Törns.
final activeTripDaysProvider = FutureProvider<List<TripDay>>((ref) async {
  final activeTrip = await ref.watch(activeTripProvider.future);
  if (activeTrip == null) return [];
  final dao = ref.watch(tripDaoProvider);
  return dao.getDaysForTrip(activeTrip.id);
});

/// Provider für die Einkaufsstopps des aktuell aktiven Törns.
final activeTripStopsProvider = FutureProvider<List<ShoppingStop>>((ref) async {
  final activeTrip = await ref.watch(activeTripProvider.future);
  if (activeTrip == null) return [];
  final dao = ref.watch(tripDaoProvider);
  return dao.getShoppingStopsForTrip(activeTrip.id);
});

/// Provider für die Crew des aktuell aktiven Törns.
final activeTripCrewProvider = FutureProvider<List<CrewMember>>((ref) async {
  final activeTrip = await ref.watch(activeTripProvider.future);
  if (activeTrip == null) return [];
  final dao = ref.watch(tripDaoProvider);
  return dao.getCrewForTrip(activeTrip.id);
});

/// Provider für einen Törn nach ID (FB2-B).
final tripByIdProvider = FutureProvider.family<Trip?, int>((ref, tripId) async {
  final dao = ref.watch(tripDaoProvider);
  return dao.getTripById(tripId);
});

/// Provider für die Tage eines Törns nach ID (FB2-B).
final tripDaysByIdProvider = FutureProvider.family<List<TripDay>, int>((ref, tripId) async {
  final dao = ref.watch(tripDaoProvider);
  return dao.getDaysForTrip(tripId);
});

/// Provider für die Einkaufsstopps eines Törns nach ID (FB2-B).
final tripStopsByIdProvider = FutureProvider.family<List<ShoppingStop>, int>((ref, tripId) async {
  final dao = ref.watch(tripDaoProvider);
  return dao.getShoppingStopsForTrip(tripId);
});

/// Provider für die Crew eines Törns nach ID (PIVOT2).
final tripCrewByIdProvider = FutureProvider.family<List<CrewMember>, int>((ref, tripId) async {
  final dao = ref.watch(tripDaoProvider);
  return dao.getCrewForTrip(tripId);
});
