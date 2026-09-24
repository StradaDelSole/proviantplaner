import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/main.dart';

void main() {
  testWidgets('StartScreen zeigt App-Name und powered by HullQ auf Deutsch', (WidgetTester tester) async {
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

    // Reiternamen auf Deutsch prüfen
    expect(find.text('Liste'), findsOneWidget);
    expect(find.text('Törn'), findsOneWidget);
    expect(find.text('Bordkasse'), findsOneWidget);
    expect(find.text('Mehr'), findsOneWidget);
  });

  testWidgets('StartScreen zeigt Navigation auf Englisch', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ProviantplanerApp(locale: Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('List'), findsOneWidget);
    expect(find.text('Trip'), findsOneWidget);
    expect(find.text('Kitty'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });
}