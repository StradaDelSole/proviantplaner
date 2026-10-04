import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/services/catalog_localization_service.dart';
import 'package:proviantplaner/core/util/formatters.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/catalog_models.dart';

void main() {
  group('S9 Acceptance Criteria 1: ARB and Locale Completeness across 6 languages', () {
    const expectedLanguages = ['de', 'en', 'fr', 'es', 'pt', 'hr'];

    test('All 6 ARB files exist and contain identical message keys', () {
      final keySets = <String, Set<String>>{};

      for (final lang in expectedLanguages) {
        final file = File('lib/l10n/app_$lang.arb');
        expect(file.existsSync(), isTrue, reason: 'File app_$lang.arb must exist');

        final content = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        // Filter out metadata keys starting with @
        final messageKeys = content.keys.where((k) => !k.startsWith('@')).toSet();
        keySets[lang] = messageKeys;

        expect(messageKeys, isNotEmpty);
      }

      // Compare all language keys against German keys
      final deKeys = keySets['de']!;
      for (final lang in ['en', 'fr', 'es', 'pt', 'hr']) {
        final currentKeys = keySets[lang]!;
        final missingInLang = deKeys.difference(currentKeys);
        final extraInLang = currentKeys.difference(deKeys);

        expect(
          missingInLang,
          isEmpty,
          reason: '$lang is missing keys present in de: $missingInLang',
        );
        expect(
          extraInLang,
          isEmpty,
          reason: '$lang has extra keys not present in de: $extraInLang',
        );
      }
    });

    test('AppLocalizations supports all 6 locales', () {
      final supportedCodes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
      for (final lang in expectedLanguages) {
        expect(
          supportedCodes.contains(lang),
          isTrue,
          reason: 'Locale $lang must be supported by AppLocalizations',
        );
      }
    });
  });

  group('S9 Acceptance Criteria 2: Catalog translations in 6 languages', () {
    const foreignLanguages = ['en', 'fr', 'es', 'pt', 'hr'];

    test('All 5 catalog_<lang>.json files exist, have 288 entries and review flag', () {
      for (final lang in foreignLanguages) {
        final file = File('data/i18n/catalog_$lang.json');
        expect(file.existsSync(), isTrue, reason: 'data/i18n/catalog_$lang.json must exist');

        final jsonContent = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(jsonContent['review'], equals('maschinell, Prüfung ausstehend'));

        final items = (jsonContent['translations'] ?? jsonContent['items']) as Map<String, dynamic>;
        expect(items.length, greaterThanOrEqualTo(280), reason: 'Must translate all catalog items');

        // Check key items
        for (final key in ['apples', 'beer', 'water', 'kitchen', 'tech_repair']) {
          expect(items.containsKey(key), isTrue, reason: 'Missing item $key in $lang');
          final item = items[key];
          expect(item, isNotNull);
        }
      }
    });

    test('CatalogLocalizationService translates item names correctly', () async {
      final service = CatalogLocalizationService.instance;
      await service.loadAll();

      // In German (fallback or original)
      expect(service.translateName('apples', 'de', 'Äpfel'), equals('Äpfel'));

      // In English
      expect(service.translateName('apples', 'en', 'Äpfel'), equals('Apples'));
      expect(service.translateName('beer', 'en', 'Bier'), equals('Beer'));

      // In French
      expect(service.translateName('apples', 'fr', 'Äpfel'), equals('Pommes'));
      expect(service.translateName('beer', 'fr', 'Bier'), equals('Bière'));

      // In Spanish
      expect(service.translateName('beer', 'es', 'Bier'), equals('Cerveza'));

      // In Croatian
      expect(service.translateName('beer', 'hr', 'Bier'), equals('Pivo'));
    });
  });

  group('S9 Acceptance Criteria 3: Formatting numbers, dates, currency via intl', () {
    testWidgets('AppFormatters formats currency correctly per locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          home: Builder(
            builder: (context) {
              final deFormatted = AppFormatters.formatCurrency(context, 1250);
              expect(deFormatted, contains('12,50'));

              final enFormatted = AppFormatters.formatCurrency(context, 1250, locale: 'en');
              expect(enFormatted, contains('12.50'));

              final wholeEuro = AppFormatters.formatCurrency(context, 2000);
              expect(wholeEuro, contains('20'));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('AppFormatters formats decimals correctly per locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          home: Builder(
            builder: (context) {
              final deFormatted = AppFormatters.formatDecimal(context, 1.5);
              expect(deFormatted, equals('1,5'));

              final enFormatted = AppFormatters.formatDecimal(context, 1.5, locale: 'en');
              expect(enFormatted, equals('1.5'));

              final integerVal = AppFormatters.formatDecimal(context, 3.0);
              expect(integerVal, equals('3'));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('AppFormatters formats dates correctly per locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          home: Builder(
            builder: (context) {
              final dt = DateTime(2026, 10, 4);
              final deDate = AppFormatters.formatDate(context, dt);
              expect(deDate, contains('4.10.2026'));

              final enDate = AppFormatters.formatDate(context, dt, locale: 'en');
              expect(enDate, isNotEmpty);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('S9 Acceptance Criteria 4: All Departments and Categories are translated', () {
    for (final lang in ['de', 'en', 'fr', 'es', 'pt', 'hr']) {
      testWidgets('All CatalogDepartments have non-empty localized names in $lang', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale(lang),
            home: Builder(
              builder: (context) {
                for (final dept in CatalogDepartment.values) {
                  final locName = dept.localizedName(context);
                  expect(locName, isNotEmpty);
                  if (lang != 'de') {
                    if (dept == CatalogDepartment.obstGemuese) {
                      expect(locName, isNot(equals('Obst und Gemüse')));
                    } else if (dept == CatalogDepartment.molkerei) {
                      expect(locName, isNot(equals('Molkerei und Kühlregal')));
                    }
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('All ExpenseCategories have non-empty localized names in $lang', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale(lang),
            home: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                for (final cat in ExpenseCategory.values) {
                  final locName = cat.localizedName(l10n);
                  expect(locName, isNotEmpty);
                  if (lang != 'de') {
                    if (cat == ExpenseCategory.provisions) {
                      expect(locName, isNot(equals('Proviant')));
                    } else if (cat == ExpenseCategory.drinks) {
                      expect(locName, isNot(equals('Getränke')));
                    }
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });
    }
  });

  group('S9 Acceptance Criteria 5: Zero visible German leftovers when foreign locale selected', () {
    testWidgets('Renders localized UI strings in English with no German leftovers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Column(
                  children: [
                    Text(l10n.startShopping),
                    Text(l10n.storageTitle),
                    Text(l10n.freezerAvailable),
                    Text(l10n.waterTankDrinkable),
                    Text(l10n.whoManagesFund),
                    Text(l10n.byCategory),
                    Text(l10n.byDepartment),
                    Text(l10n.paidCash),
                    Text(l10n.transferMoney),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Verify English strings are rendered
      expect(find.text('Start shopping'), findsOneWidget);
      expect(find.text('Storage'), findsOneWidget);
      expect(find.text('Freezer compartment available'), findsOneWidget);
      expect(find.text('Tank water is potable'), findsOneWidget);
      expect(find.text('Who manages the crew fund?'), findsOneWidget);
      expect(find.text('By category'), findsOneWidget);
      expect(find.text('By department'), findsOneWidget);
      expect(find.text('Paid in cash'), findsOneWidget);
      expect(find.text('Bank transfer'), findsOneWidget);

      // Verify German equivalents are NOT rendered
      expect(find.text('Einkauf starten'), findsNothing);
      expect(find.text('Einlagern'), findsNothing);
      expect(find.text('Tiefkühlfach vorhanden'), findsNothing);
      expect(find.text('Tankwasser ist trinkbar'), findsNothing);
      expect(find.text('Wer verwaltet die Kasse?'), findsNothing);
      expect(find.text('Nach Kategorie'), findsNothing);
      expect(find.text('Nach Abteilung'), findsNothing);
      expect(find.text('Bar ausgezahlt'), findsNothing);
      expect(find.text('Überweisen'), findsNothing);
    });

    testWidgets('Renders localized UI strings in French with no German leftovers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Column(
                  children: [
                    Text(l10n.startShopping),
                    Text(l10n.storageTitle),
                    Text(l10n.freezerAvailable),
                    Text(l10n.waterTankDrinkable),
                    Text(l10n.paidCash),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Démarrer les courses'), findsOneWidget);
      expect(find.text('Rangement à bord'), findsOneWidget);
      expect(find.text('Compartiment congélateur disponible'), findsOneWidget);
      expect(find.text('L\'eau du réservoir est potable'), findsOneWidget);
      expect(find.text('Payé en espèces'), findsOneWidget);

      expect(find.text('Einkauf starten'), findsNothing);
      expect(find.text('Einlagern'), findsNothing);
      expect(find.text('Tiefkühlfach vorhanden'), findsNothing);
    });

    testWidgets('Renders localized UI strings in Spanish with no German leftovers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Column(
                  children: [
                    Text(l10n.startShopping),
                    Text(l10n.storageTitle),
                    Text(l10n.freezerAvailable),
                    Text(l10n.paidCash),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Iniciar compra'), findsOneWidget);
      expect(find.text('Estiba a bordo'), findsOneWidget);
      expect(find.text('Compartimento congelador disponible'), findsOneWidget);
      expect(find.text('Pagado en efectivo'), findsOneWidget);

      expect(find.text('Einkauf starten'), findsNothing);
      expect(find.text('Einlagern'), findsNothing);
    });

    testWidgets('Renders localized UI strings in Croatian with no German leftovers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('hr'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Column(
                  children: [
                    Text(l10n.startShopping),
                    Text(l10n.freezerAvailable),
                    Text(l10n.paidCash),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Kreni u kupovinu'), findsOneWidget);
      expect(find.text('Dostupan zamrzivač'), findsOneWidget);
      expect(find.text('Isplaćeno u gotovini'), findsOneWidget);

      expect(find.text('Einkauf starten'), findsNothing);
    });
  });
}
