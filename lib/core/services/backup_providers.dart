/// Riverpod Provider für Datensicherung und Wiederherstellung (Slice S8).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/features/entitlements/data/entitlements_providers.dart';
import 'package:proviantplaner/features/kitty/data/kitty_providers.dart';
import 'backup_coordinator.dart';
import 'hullq_backup_service.dart';


/// Provider für den [HullqBackupService] (Slice B2: HttpHullqBackupService).
final hullqBackupServiceProvider = Provider<HullqBackupService>((ref) {
  final apiClient = ref.watch(hullqApiClientProvider);
  final authService = ref.watch(hullqAuthServiceProvider);
  return HttpHullqBackupService(
    apiClient: apiClient,
    authService: authService,
  );
});

/// Provider für den [BackupCoordinator].
final backupCoordinatorProvider = Provider<BackupCoordinator>((ref) {
  final db = ref.watch(databaseProvider);
  final backupService = ref.watch(hullqBackupServiceProvider);
  final authService = ref.watch(hullqAuthServiceProvider);
  final receiptFileService = ref.watch(receiptFileServiceProvider);
  return BackupCoordinator(
    db: db,
    backupService: backupService,
    authService: authService,
    receiptFileService: receiptFileService,
  );
});


/// Provider für den Zeitstempel der letzten Sicherung.
final lastBackupTimestampProvider = FutureProvider<DateTime?>((ref) async {
  final service = ref.watch(hullqBackupServiceProvider);
  return service.getLastBackupTimestamp();
});
