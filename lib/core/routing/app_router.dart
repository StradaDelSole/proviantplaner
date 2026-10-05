import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proviantplaner/core/routing/not_found_screen.dart';
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

/// Provider für den GoRouter der Anwendung.
/// Ermöglicht deklarative Navigation gemäß den technischen Leitplanken.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
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
            return NotFoundScreen(message: l10n?.tripNotFound ?? 'Törn nicht gefunden');
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
            return NotFoundScreen(message: l10n?.tripNotFound ?? 'Törn nicht gefunden');
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
            return NotFoundScreen(message: l10n?.tripNotFound ?? 'Törn nicht gefunden');
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
            return NotFoundScreen(message: l10n?.tripNotFound ?? 'Törn nicht gefunden');
          }
          if (stopId == null) {
            return NotFoundScreen(message: l10n?.shoppingStopNotFound ?? 'Einkaufsstopp nicht gefunden');
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
            return NotFoundScreen(message: l10n?.tripNotFound ?? 'Törn nicht gefunden');
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
            return NotFoundScreen(message: l10n?.tripNotFound ?? 'Törn nicht gefunden');
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
            return NotFoundScreen(message: l10n?.tripNotFound ?? 'Törn nicht gefunden');
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
            return NotFoundScreen(message: l10n?.tripNotFound ?? 'Törn nicht gefunden');
          }
          return MoreScreen(tripId: tripId);
        },
      ),
    ],
  );
});