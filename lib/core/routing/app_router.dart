import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proviantplaner/features/home/ui/start_screen.dart';
import 'package:proviantplaner/features/trip/ui/trip_wizard_screen.dart';
import 'package:proviantplaner/features/trip/ui/trip_timeline_screen.dart';

/// Provider für den GoRouter der Anwendung.
/// Ermöglicht deklarative Navigation gemäß den technischen Leitplanken.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
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
        path: '/trips/:id/timeline',
        name: 'trip_timeline',
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final tripId = int.tryParse(idStr ?? '') ?? 1;
          return TripTimelineScreen(tripId: tripId);
        },
      ),
    ],
  );
});