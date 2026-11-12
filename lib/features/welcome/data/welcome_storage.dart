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
/// Behandelt Persistenzfehler wahrheitsgetreu und verschluckt keine Ausnahmen (W2).
class SecureWelcomeStorage implements WelcomeStorage {
  final FlutterSecureStorage _storage;
  static const String key = 'provy_welcome_seen_v1';

  SecureWelcomeStorage([this._storage = const FlutterSecureStorage()]);

  @override
  Future<bool> hasSeenWelcome() async {
    final value = await _storage.read(key: key);
    return value == 'true';
  }

  @override
  Future<void> setSeenWelcome() async {
    await _storage.write(key: key, value: 'true');
  }
}

/// In-Memory-Implementierung für deterministische Tests.
class MemoryWelcomeStorage implements WelcomeStorage {
  bool _seen;
  bool shouldFailWrite;
  bool shouldFailRead;
  int writeCalls = 0;
  int readCalls = 0;

  MemoryWelcomeStorage({
    bool initialSeen = false,
    this.shouldFailWrite = false,
    this.shouldFailRead = false,
  }) : _seen = initialSeen;

  @override
  Future<bool> hasSeenWelcome() async {
    readCalls++;
    if (shouldFailRead) {
      throw Exception('Simulierter Lesefehler im WelcomeStorage');
    }
    return _seen;
  }

  @override
  Future<void> setSeenWelcome() async {
    writeCalls++;
    if (shouldFailWrite) {
      throw Exception('Simulierter Schreibfehler im WelcomeStorage');
    }
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
  bool _isCompleting = false;

  WelcomeCompletedNotifier(this._storage, [this._db]) : super(const AsyncValue.loading()) {
    _load();
  }

  /// Wiederholt den Ladevorgang nach einem Fehler (W1).
  Future<void> retry() async {
    state = const AsyncValue.loading();
    await _load();
  }

  /// Erlaubt bei wiederholten/dauerhaften Speicherfehlern das Starten ohne Persistenz (W2),
  /// damit der Nutzer durch Gerätedefekte (z.B. Keystore-Defekt) nicht dauerhaft ausgesperrt wird.
  void continueWithoutPersistence() {
    state = const AsyncValue.data(true);
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
          try {
            await _storage.setSeenWelcome();
          } catch (_) {
            // Wenn bei existierenden Trips das Zwischenspeichern fehlschlägt,
            // wird der Nutzer trotzdem nicht blockiert.
          }
          state = const AsyncValue.data(true);
          return;
        }
      }
      state = const AsyncValue.data(false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Schließt das Welcome wahrheitsgetreu ab (W2).
  /// Behauptet bei fehlgeschlagener Speicherung keinen Erfolg und verhindert Concurrency.
  Future<void> completeWelcome() async {
    if (_isCompleting) return;
    _isCompleting = true;
    try {
      await _storage.setSeenWelcome();
      state = const AsyncValue.data(true);
    } finally {
      _isCompleting = false;
    }
  }
}
