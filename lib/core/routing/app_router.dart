import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proviantplaner/features/home/ui/start_screen.dart';

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
    ],
  );
});