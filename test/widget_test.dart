// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proviantplaner/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
  testWidgets('StartScreen zeigt App-Name und powered by HullQ', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ProviantplanerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    // App-Titel prüfen
    expect(find.text('Proviantplaner'), findsWidgets);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    // "powered by HullQ" prüfen
    expect(find.text('powered by HullQ'), findsWidgets);

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    // Reiternamen prüfen
    expect(find.text('Liste'), findsOneWidget);
    expect(find.text('Törn'), findsOneWidget);
    expect(find.text('Bordkasse'), findsOneWidget);
    expect(find.text('Mehr'), findsOneWidget);
  });
}

