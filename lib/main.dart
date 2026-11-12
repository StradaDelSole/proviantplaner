import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proviantplaner/core/config/app_config.dart';
import 'package:proviantplaner/core/routing/app_router.dart';
import 'package:proviantplaner/core/services/backup_coordinator.dart';
import 'package:proviantplaner/core/services/backup_providers.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/core/theme/theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ProviantplanerApp(),
    ),
  );
}

/// Haupt-App-Widget des Proviantplaners.
/// Fungiert zugleich als verbindliches zentrales Bootstrap-/Recovery-Gate (RECEIPT1 Amendment 4 Finding F):
/// Bevor der Router aufgebaut wird oder Datenmutationen über die Oberfläche möglich sind,
/// muss [appStartupRecoveryProvider] erfolgreich abgeschlossen sein.
class ProviantplanerApp extends ConsumerStatefulWidget {
  final Locale? locale;

  const ProviantplanerApp({super.key, this.locale});

  @override
  ConsumerState<ProviantplanerApp> createState() => _ProviantplanerAppState();
}

class _ProviantplanerAppState extends ConsumerState<ProviantplanerApp> {
  static const Duration _minLaunchHoldDuration = Duration(milliseconds: 2000);

  bool _minLaunchHoldElapsed = false;
  Timer? _minLaunchTimer;

  @override
  void initState() {
    super.initState();
    _minLaunchTimer = Timer(_minLaunchHoldDuration, () {
      if (!mounted) return;
      setState(() {
        _minLaunchHoldElapsed = true;
      });
    });
  }

  @override
  void dispose() {
    _minLaunchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recoveryState = ref.watch(appStartupRecoveryProvider);
    final appThemeMode = ref.watch(themeControllerProvider);

    final ThemeData currentTheme;
    final ThemeMode mode;

    switch (appThemeMode) {
      case AppThemeMode.nightwatch:
        currentTheme = AppTheme.nightwatchTheme;
        mode = ThemeMode.dark;
        break;
      case AppThemeMode.dark:
        currentTheme = AppTheme.darkTheme;
        mode = ThemeMode.dark;
        break;
      case AppThemeMode.light:
        currentTheme = AppTheme.lightTheme;
        mode = ThemeMode.light;
        break;
    }

    final darkTheme = appThemeMode == AppThemeMode.nightwatch
        ? AppTheme.nightwatchTheme
        : AppTheme.darkTheme;

    if (recoveryState.hasError) {
      return MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: currentTheme,
        darkTheme: darkTheme,
        themeMode: mode,
        locale: widget.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppStartupRecoveryErrorScreen(
          error: recoveryState.error!,
          onRetry: () => ref.invalidate(appStartupRecoveryProvider),
        ),
      );
    }

    if (!_minLaunchHoldElapsed || recoveryState.isLoading) {
      return MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: currentTheme,
        darkTheme: darkTheme,
        themeMode: mode,
        locale: widget.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AppStartupRecoveryLoadingScreen(),
      );
    }

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: currentTheme,
      darkTheme: darkTheme,
      themeMode: mode,
      locale: widget.locale,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

/// Eindeutiger Initialisierungszustand während der laufenden App-Start-Recovery (Finding F).
class AppStartupRecoveryLoadingScreen extends StatelessWidget {
  const AppStartupRecoveryLoadingScreen({
    super.key = const Key('app_startup_recovery_loading'),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNightwatch = theme.scaffoldBackgroundColor == const Color(0xFF000000);
    final primaryColor = isNightwatch
        ? const Color(0xFFFF3B30)
        : theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppConfig.appName.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6.0,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nicht-destruktiver Fehlerzustand bei fehlgeschlagener App-Start-Recovery (z. B. [RestoreRecoveryException], Finding F).
/// Führt niemals eine automatische Neuinitialisierung oder Datenbanklöschung durch.
class AppStartupRecoveryErrorScreen extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const AppStartupRecoveryErrorScreen({
    super.key = const Key('app_startup_recovery_error'),
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final detail = error is RestoreRecoveryException
        ? (error as RestoreRecoveryException).message
        : error.toString();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.technicalErrorTitle ?? AppConfig.appName,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n != null ? l10n.accountRestoreError(detail) : detail,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('app_startup_recovery_retry_button'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n?.retry ?? ''),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
