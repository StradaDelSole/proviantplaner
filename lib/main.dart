import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proviantplaner/core/config/app_config.dart';
import 'package:proviantplaner/core/routing/app_router.dart';
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
class ProviantplanerApp extends ConsumerWidget {
  final Locale? locale;

  const ProviantplanerApp({super.key, this.locale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
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

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: currentTheme,
      darkTheme: appThemeMode == AppThemeMode.nightwatch
          ? AppTheme.nightwatchTheme
          : AppTheme.darkTheme,
      themeMode: mode,
      locale: locale,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}