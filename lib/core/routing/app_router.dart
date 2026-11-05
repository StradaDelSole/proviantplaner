import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proviantplaner/core/config/app_config.dart';
import 'package:proviantplaner/core/routing/not_found_screen.dart';
import 'package:proviantplaner/features/welcome/data/welcome_storage.dart';
import 'package:proviantplaner/features/welcome/ui/welcome_screen.dart';
import 'package:proviantplaner/features/home/ui/start_screen.dart';
import 'package:proviantplaner/features/shopping_list/ui/shopping_list_screen.dart';
import 'package:proviantplaner/features/shopping_list/ui/shopping_mode_screen.dart';
import 'package:proviantplaner/features/shopping_list/ui/storage_checklist_screen.dart';
import 'package:proviantplaner/features/kitty/ui/kitty_screen.dart';
import 'package:proviantplaner/features/kitty/ui/settlement_screen.dart';
import 'package:proviantplaner/features/trip/ui/trip_wizard_screen.dart';
import 'package:proviantplaner/features/trip/ui/trip_overview_screen.dart';
import 'package:proviantplaner/features/trip/ui/trip_timeline_screen.dart';
import 'package:proviantplaner/features/more/ui/more_screen.dart';

/// Notifier für GoRouter-Reaktivität ohne Re-Erzeugung der Router-Instanz (W1).
class AppRouterRefreshNotifier extends ChangeNotifier {
  AppRouterRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<bool>>(welcomeCompletedProvider, (_, __) {
      notifyListeners();
    });
  }
}

final appRouterRefreshNotifierProvider = Provider<AppRouterRefreshNotifier>((ref) {
  return AppRouterRefreshNotifier(ref);
});

/// Ermöglicht Tests das Überschreiben der initialen Route (z.B. für Deep-Link-Prüfungen).
final appRouterInitialLocationProvider = Provider<String>((ref) => '/');

/// Expliziter Ladebildschirm während des initialen Welcome-Checks (W1).
class WelcomeGateLoadingScreen extends StatelessWidget {
  const WelcomeGateLoadingScreen({
    super.key = const Key('welcome_gate_loading'),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNightwatch = theme.scaffoldBackgroundColor == const Color(0xFF000000);
    final primaryColor = isNightwatch
        ? const Color(0xFFFF3B30)
        : theme.colorScheme.primary;

    return Scaffold(
      key: const Key('welcome_gate_loading_scaffold'),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConfig.appName.toUpperCase(),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expliziter, wiederholbarer Fehlerbildschirm mit Retry- und Notfall-Pfad (W1, W2).
class WelcomeGateErrorScreen extends ConsumerWidget {
  const WelcomeGateErrorScreen({
    super.key = const Key('welcome_gate_error'),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isNightwatch = theme.scaffoldBackgroundColor == const Color(0xFF000000);
    final primaryColor = isNightwatch
        ? const Color(0xFFFF3B30)
        : theme.colorScheme.primary;

    return Scaffold(
      key: const Key('welcome_gate_error_scaffold'),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: primaryColor),
              const SizedBox(height: 16),
              Text(
                l10n.technicalErrorTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isNightwatch ? const Color(0xFFFF3B30) : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.technicalErrorMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isNightwatch
                      ? const Color(0xFFFF3B30).withOpacity(0.8)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('welcome_gate_retry_button'),
                onPressed: () => ref.read(welcomeCompletedProvider.notifier).retry(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isNightwatch ? Colors.black : Colors.white,
                ),
                child: Text(l10n.retry),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('welcome_gate_skip_button'),
                onPressed: () => ref.read(welcomeCompletedProvider.notifier).continueWithoutPersistence(),
                child: Text(
                  l10n.welcomeContinueAnyway,
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Provider für den GoRouter der Anwendung.
/// Ermöglicht deklarative Navigation gemäß den technischen Leitplanken.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(appRouterRefreshNotifierProvider);
  final initialLocation = ref.watch(appRouterInitialLocationProvider);

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refreshNotifier,
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) {
      final welcomeState = ref.read(welcomeCompletedProvider);
      final location = state.matchedLocation;

      // 1. Ladezustand: Home- und Törnrouten sperren, Ladebildschirm anzeigen (W1)
      if (welcomeState.isLoading) {
        if (location == '/welcome-loading') return null;
        final fromParam = location != '/' ? '?from=${Uri.encodeComponent(location)}' : '';
        return '/welcome-loading$fromParam';
      }

      // 2. Fehlerzustand: Expliziter Fehlerbildschirm mit Retry-Möglichkeit (W1)
      if (welcomeState.hasError) {
        if (location == '/welcome-error') return null;
        return '/welcome-error';
      }

      final hasSeen = welcomeState.value ?? false;

      // 3. Erstnutzung noch nicht abgeschlossen: Alle Einstiege (inkl. Deep-Links) auf /welcome leiten (W1)
      if (!hasSeen) {
        if (location == '/welcome') return null;
        return '/welcome';
      }

      // 4. Welcome abgeschlossen:
      // Befindet sich die Navigation noch auf einer Gate-Route, zur Zielroute oder Startseite navigieren.
      if (location == '/welcome' || location == '/welcome-loading' || location == '/welcome-error') {
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty && from != '/welcome') {
          return from;
        }
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome-loading',
        name: 'welcome_loading',
        builder: (context, state) => const WelcomeGateLoadingScreen(),
      ),
      GoRoute(
        path: '/welcome-error',
        name: 'welcome_error',
        builder: (context, state) => const WelcomeGateErrorScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'start',
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: '/trips/new',
        name: 'new_trip',
        builder: (context, state) => const TripWizardScreen(),
      ),
      GoRoute(
        path: '/trips/:id',
        name: 'trip_overview',
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final tripId = int.tryParse(idStr ?? '');
          if (tripId == null) {
            final l10n = AppLocalizations.of(context);
            return NotFoundScreen(message: l10n?.tripNotFound);
          }
          return TripOverviewScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/trips/:id/timeline',
        name: 'trip_timeline',
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final tripId = int.tryParse(idStr ?? '');
          if (tripId == null) {
            final l10n = AppLocalizations.of(context);
            return NotFoundScreen(message: l10n?.tripNotFound);
          }
          return TripTimelineScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/trips/:id/shopping-list',
        name: 'trip_shopping_list',
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final tripId = int.tryParse(idStr ?? '');
          if (tripId == null) {
            final l10n = AppLocalizations.of(context);
            return NotFoundScreen(message: l10n?.tripNotFound);
          }
          return ShoppingListScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/trips/:id/shop/:stopId',
        name: 'trip_shop_mode',
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final stopStr = state.pathParameters['stopId'];
          final tripId = int.tryParse(idStr ?? '');
          final stopId = int.tryParse(stopStr ?? '');
          final l10n = AppLocalizations.of(context);
          if (tripId == null) {
            return NotFoundScreen(message: l10n?.tripNotFound);
          }
          if (stopId == null) {
            return NotFoundScreen(message: l10n?.shoppingStopNotFound);
          }
          return ShoppingModeScreen(tripId: tripId, stopId: stopId);
        },
      ),
      GoRoute(
        path: '/trips/:id/storage',
        name: 'trip_storage',
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final tripId = int.tryParse(idStr ?? '');
          if (tripId == null) {
            final l10n = AppLocalizations.of(context);
            return NotFoundScreen(message: l10n?.tripNotFound);
          }
          return StorageChecklistScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/trips/:id/kitty',
        name: 'trip_kitty',
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final tripId = int.tryParse(idStr ?? '');
          if (tripId == null) {
            final l10n = AppLocalizations.of(context);
            return NotFoundScreen(message: l10n?.tripNotFound);
          }
          return KittyScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/trips/:id/kitty/settlement',
        name: 'trip_kitty_settlement',
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final tripId = int.tryParse(idStr ?? '');
          if (tripId == null) {
            final l10n = AppLocalizations.of(context);
            return NotFoundScreen(message: l10n?.tripNotFound);
          }
          return SettlementScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/more',
        name: 'more',
        builder: (context, state) => const MoreScreen(),
      ),
      GoRoute(
        path: '/trips/:id/more',
        name: 'trip_more',
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final tripId = int.tryParse(idStr ?? '');
          if (tripId == null) {
            final l10n = AppLocalizations.of(context);
            return NotFoundScreen(message: l10n?.tripNotFound);
          }
          return MoreScreen(tripId: tripId);
        },
      ),
    ],
  );
});
