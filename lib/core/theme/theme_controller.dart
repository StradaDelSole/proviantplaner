/// Controller und Provider für den Farbmodus der App (Slice S-UI).
/// Unterstützt Hell, Dunkel und den Modus "Nachtwache" (Rot auf Schwarz) gemäß Designregel 13.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Die drei unterstützten Farbmodi aus docs/design/DESIGN_BRIEF_v0.4.md.
enum AppThemeMode {
  light,
  dark,
  nightwatch;

  static AppThemeMode fromString(String? val) {
    switch (val) {
      case 'dark':
        return AppThemeMode.dark;
      case 'nightwatch':
        return AppThemeMode.nightwatch;
      case 'light':
      default:
        return AppThemeMode.light;
    }
  }
}

/// Abstraktion für die Speicherung des Farbmodus (Offline zuerst).
abstract class ThemeStorage {
  Future<String?> readTheme();
  Future<void> saveTheme(String value);
}

/// Implementierung über FlutterSecureStorage.
class SecureThemeStorage implements ThemeStorage {
  final FlutterSecureStorage _storage;
  static const _key = 'proviantplaner_theme_mode';

  SecureThemeStorage([this._storage = const FlutterSecureStorage()]);

  @override
  Future<String?> readTheme() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTheme(String value) async {
    try {
      await _storage.write(key: _key, value: value);
    } catch (_) {
      // Offline fallback: Fehler beim Speichern tolerieren
    }
  }
}

/// Verwaltet den aktuellen Farbmodus und speichert ihn lokal offline.
class ThemeController extends StateNotifier<AppThemeMode> {
  final ThemeStorage _storage;

  ThemeController(this._storage) : super(AppThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final saved = await _storage.readTheme();
    if (saved != null) {
      state = AppThemeMode.fromString(saved);
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    await _storage.saveTheme(mode.name);
  }

  Future<void> toggleNightwatch() async {
    if (state == AppThemeMode.nightwatch) {
      await setThemeMode(AppThemeMode.light);
    } else {
      await setThemeMode(AppThemeMode.nightwatch);
    }
  }
}

final themeStorageProvider = Provider<ThemeStorage>((ref) {
  return SecureThemeStorage();
});

final themeControllerProvider = StateNotifierProvider<ThemeController, AppThemeMode>((ref) {
  final storage = ref.watch(themeStorageProvider);
  return ThemeController(storage);
});
