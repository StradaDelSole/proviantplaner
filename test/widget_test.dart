import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/main.dart';

void main() {
  testWidgets('StartScreen zeigt App-Name, powered by HullQ und keine Reiterleiste (FEEDBACK_R1 Punkt 4)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ProviantplanerApp(locale: Locale('de')),
      ),
    );
    await tester.pumpAndSettle();

    // App-Titel prüfen
    expect(find.text('Proviantplaner'), findsWidgets);

    // "powered by HullQ" prüfen
    expect(find.text('powered by HullQ'), findsWidgets);

    // Keine Reiterleiste auf Startbildschirm gemäß FEEDBACK_R1 Punkt 4
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('StartScreen auf Englisch zeigt keinen Tab-Bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ProviantplanerApp(locale: Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Proviantplaner'), findsWidgets);
    expect(find.byType(NavigationBar), findsNothing);
  });
}