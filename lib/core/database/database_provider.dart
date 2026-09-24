import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/daos.dart';

/// Provider für die zentrale AppDatabase.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provider für TripDao.
final tripDaoProvider = Provider<TripDao>((ref) {
  return ref.watch(databaseProvider).tripDao;
});

/// Provider für ListItemDao.
final listItemDaoProvider = Provider<ListItemDao>((ref) {
  return ref.watch(databaseProvider).listItemDao;
});

/// Provider für ExpenseDao.
final expenseDaoProvider = Provider<ExpenseDao>((ref) {
  return ref.watch(databaseProvider).expenseDao;
});