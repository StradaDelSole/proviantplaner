// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daos.dart';

// ignore_for_file: type=lint
mixin _$TripDaoMixin on DatabaseAccessor<AppDatabase> {
  $TripsTable get trips => attachedDatabase.trips;
  $TripDaysTable get tripDays => attachedDatabase.tripDays;
  $CrewMembersTable get crewMembers => attachedDatabase.crewMembers;
  $ShoppingStopsTable get shoppingStops => attachedDatabase.shoppingStops;
}
mixin _$ListItemDaoMixin on DatabaseAccessor<AppDatabase> {
  $TripsTable get trips => attachedDatabase.trips;
  $ListItemsTable get listItems => attachedDatabase.listItems;
  $ShoppingStopsTable get shoppingStops => attachedDatabase.shoppingStops;
  $ListItemAllocationsTable get listItemAllocations =>
      attachedDatabase.listItemAllocations;
}
mixin _$ExpenseDaoMixin on DatabaseAccessor<AppDatabase> {
  $TripsTable get trips => attachedDatabase.trips;
  $CrewMembersTable get crewMembers => attachedDatabase.crewMembers;
  $ExpensesTable get expenses => attachedDatabase.expenses;
  $KittyPaymentsTable get kittyPayments => attachedDatabase.kittyPayments;
}
