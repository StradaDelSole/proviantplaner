library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:proviantplaner/core/database/database_provider.dart';

/// Abstraktion für die Speicherung des Welcome-Screen-Status (#62).
/// Garantiert Offline-First-Betrieb ohne Netzwerkabhängigkeit.
abstract class WelcomeStorage {
  Future<bool> hasSeenWelcome();
  Future<void> setSeenWelcome();
}

/// Produktionsimplementierung über FlutterSecureStorage.
class SecureWelcomeStorage implements WelcomeStorage {
  final FlutterSecureStorage _storage;
  static const String key = 'provy_welcome_seen_v1';

  SecureWelcomeStorage([this._storage = const FlutterSecureStorage()]);

  @override
  Future<bool> hasSeenWelcome() async {
    try {
      final value = await _storage.read(key: key);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setSeenWelcome() async {
    try {
      await _storage.write(key: key, value: 'true');
    } catch (_) {
      // Speicherfehler beim Schreiben fangen, um UI-Fluss nicht zu blockieren
    }
  }
}

/// In-Memory-Implementierung für deterministische Tests.
class MemoryWelcomeStorage implements WelcomeStorage {
  bool _seen;

  MemoryWelcomeStorage({bool initialSeen = false}) : _seen = initialSeen;

  @override
  Future<bool> hasSeenWelcome() async => _seen;

  @override
  Future<void> setSeenWelcome() async {
    _seen = true;
  }
}

/// Provider für den WelcomeStorage.
final welcomeStorageProvider = Provider<WelcomeStorage>((ref) {
  return SecureWelcomeStorage();
});

/// StateNotifier für den Lade- und Abschlusszustand des Welcome-Screens.
final welcomeCompletedProvider =
    StateNotifierProvider<WelcomeCompletedNotifier, AsyncValue<bool>>((ref) {
  final storage = ref.watch(welcomeStorageProvider);
  final db = ref.watch(databaseProvider);
  return WelcomeCompletedNotifier(storage, db);
});

class WelcomeCompletedNotifier extends StateNotifier<AsyncValue<bool>> {
  final WelcomeStorage _storage;
  final dynamic _db;

  WelcomeCompletedNotifier(this._storage, [this._db]) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final seen = await _storage.hasSeenWelcome();
      if (seen) {
        state = const AsyncValue.data(true);
        return;
      }
      if (_db != null) {
        final trips = await _db.tripDao.getAllTrips();
        if (trips.isNotEmpty) {
          await _storage.setSeenWelcome();
          state = const AsyncValue.data(true);
          return;
        }
      }
      state = const AsyncValue.data(false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeWelcome() async {
    await _storage.setSeenWelcome();
    state = const AsyncValue.data(true);
  }
}

