import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/main.dart';

void main() {
  testWidgets('StartScreen zeigt Meine Törns, powered by HullQ und keine Reiterleiste (UX-A)', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allTripsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const ProviantplanerApp(locale: Locale('de')),
      ),
    );
    await tester.pumpAndSettle();

    // Titel "Meine Törns" prüfen (UX_KONZEPT 2.1: Titel: Meine Törns (nicht mehr „Proviantplaner“))
    expect(find.text('Meine Törns'), findsOneWidget);

    // "powered by HullQ" prüfen
    expect(find.text('powered by HullQ'), findsWidgets);

    // Keine Reiterleiste auf Startbildschirm gemäß UX-A
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('StartScreen auf Englisch zeigt keinen Tab-Bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allTripsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const ProviantplanerApp(locale: Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meine Törns'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}