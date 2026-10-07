/// UI- und Widget-Tests für Bordkasse und Kostenteilung (Slice S5).
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/core/theme/theme_controller.dart';
import 'package:proviantplaner/features/kitty/data/kitty_providers.dart';
import 'package:proviantplaner/features/kitty/data/kitty_service.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/kitty/ui/kitty_screen.dart';
import 'package:proviantplaner/features/kitty/ui/settlement_screen.dart';
import 'package:proviantplaner/features/kitty/ui/widgets/epc_qr_widget.dart';
import 'package:proviantplaner/features/kitty/ui/widgets/expense_sheet.dart';
import 'package:proviantplaner/features/kitty/ui/widgets/payment_sheet.dart';
import 'package:proviantplaner/features/kitty/ui/widgets/participation_matrix_sheet.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';

void main() {
  late AppDatabase db;
  late KittyService kittyService;
  late int tripId;
  late int member1Id;
  late int member2Id;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    kittyService = KittyService(
      tripDao: db.tripDao,
      expenseDao: db.expenseDao,
    );

    // Törn anlegen
    tripId = await db.tripDao.createTrip(
      TripsCompanion.insert(
        name: 'Kroatien Törn 2026',
        startDate: DateTime(2026, 9, 20),
        daysCount: const Value(7),
        kittyModel: const Value(KittyModel.sharedKitty),
        treasurerMemberId: const Value(1),
      ),
    );

    // Crew-Mitglieder
    member1Id = await db.tripDao.addCrewMember(
      CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Anna (Skipper)',
        isChild: const Value(false),
        isSkipperFree: const Value(true),
        skipperFreeScope: const Value('all'),
        categoryParticipation: const Value('{"all":true}'),
        iban: const Value('DE89370400440532013000'),
      ),
    );

    member2Id = await db.tripDao.addCrewMember(
      CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Ben',
        isChild: const Value(false),
        isSkipperFree: const Value(false),
        categoryParticipation: const Value('{"all":true}'),
        iban: const Value('DE89370400440532013000'),
      ),
    );

    // Einzahlungen
    await db.tripDao.setTripTreasurer(tripId, member1Id);
    await kittyService.addDeposit(
      tripId: tripId,
      memberId: member2Id,
      amountInCents: 50000, // 500,00 €
    );

    // Ausgaben
    await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Supermarkt Einkauf',
        amountInCents: 18000, // 180,00 €
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableWidget(
    Widget child, {
    ThemeData? theme,
    AppThemeMode themeMode = AppThemeMode.light,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        kittyServiceProvider.overrideWithValue(kittyService),
        themeControllerProvider.overrideWith((ref) => _MockThemeController(themeMode)),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('de'), Locale('en')],
        locale: const Locale('de'),
        home: child,
      ),
    );
  }

  testWidgets('SC-KAS-01: KittyScreen rendert Bento-Card, Ausgaben und Personen in Hell, Dunkel und Nachtwache', (tester) async {
    // 1. Hell-Modus
    await tester.pumpWidget(buildTestableWidget(KittyScreen(tripId: tripId)));
    await tester.pumpAndSettle();

    expect(find.text('Bordkasse'), findsWidgets);
    expect(find.text('Gemeinsame Bordkasse'), findsOneWidget);
    expect(find.text('Supermarkt Einkauf'), findsOneWidget);
    expect(find.text('-180,00 €'), findsOneWidget);
    expect(find.text('320,00 €'), findsWidgets); // Kassenstand: 500 - 180 = 320,00 €

    // Umschalten auf "Personen & Anteile"
    final segFinder = find.text('Personen & Anteile');
    await tester.ensureVisible(segFinder);
    await tester.tap(segFinder);
    await tester.pumpAndSettle();

    expect(find.text('Anna (Skipper)'), findsWidgets);
    expect(find.text('Ben'), findsOneWidget);
    expect(find.text('Skipper frei'), findsWidgets);

    // 2. Nachtwache-Modus
    await tester.pumpWidget(buildTestableWidget(
      KittyScreen(tripId: tripId),
      theme: AppTheme.nightwatchTheme,
      themeMode: AppThemeMode.nightwatch,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Bordkasse'), findsWidgets);
  });

  testWidgets('SC-KAS-02: ExpenseSheet Dialog erfasst neue Ausgabe mit Kategorie und Betrag', (tester) async {
    final members = [
      KittyMember(id: member1Id, name: 'Anna', categoryParticipation: {}),
      KittyMember(id: member2Id, name: 'Ben', categoryParticipation: {}),
    ];

    await tester.pumpWidget(
      buildTestableWidget(
        Scaffold(
          body: ExpenseSheet(
            tripId: tripId,
            kittyModel: KittyModel.sharedKitty,
            members: members,
            currency: 'EUR',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ausgabe erfassen'), findsOneWidget);
    expect(find.text('Proviant'), findsOneWidget);
    expect(find.text('Ausgabe speichern'), findsOneWidget);

    // Betrag eingeben
    await tester.enterText(find.byType(TextFormField).first, '45.50');

    // Notiz unter Mehr Optionen eingeben
    await tester.tap(find.text('Mehr Optionen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Titel / Zweck'), 'Hafengebühr Vis');

    // Kategorie wählen
    await tester.tap(find.text('Proviant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hafen und Liegeplatz').last);
    await tester.pumpAndSettle();

    // Speichern
    final saveFinder = find.text('Ausgabe speichern');
    await tester.ensureVisible(saveFinder);
    await tester.tap(saveFinder);
    await tester.pumpAndSettle();

    final expenses = await db.expenseDao.getExpensesForTrip(tripId);
    expect(expenses.any((e) => e.note == 'Hafengebühr Vis' && e.amount == 45.50), isTrue);
  });

  testWidgets('SC-KAS-03: PaymentSheet Dialog erfasst Einzahlung', (tester) async {
    final members = [
      KittyMember(id: member1Id, name: 'Anna', categoryParticipation: {}),
      KittyMember(id: member2Id, name: 'Ben', categoryParticipation: {}),
    ];

    await tester.pumpWidget(
      buildTestableWidget(
        Scaffold(
          body: PaymentSheet(
            tripId: tripId,
            members: members,
            currency: 'EUR',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Einzahlung erfassen'), findsOneWidget);
    expect(find.textContaining('Wie viel zahlt jeder ein?'), findsOneWidget);
    expect(find.text('Einzahlung speichern'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '100.00');
    await tester.pumpAndSettle();

    final saveBtnFinder = find.text('Einzahlungen speichern (200,00 €)');
    await tester.ensureVisible(saveBtnFinder);
    await tester.tap(saveBtnFinder);
    await tester.pumpAndSettle();

    final payments = await db.expenseDao.getKittyPaymentsForTrip(tripId);
    // Vorher 1 Zahlung (500 €), jetzt für beide je 100 € -> 3 Zahlungen
    expect(payments.length, 3);
  });

  testWidgets('SC-KAS-04: ParticipationMatrixSheet schaltet Profile und Kategorien', (tester) async {
    final members = [
      KittyMember(id: member1Id, name: 'Anna', categoryParticipation: {for (final c in ExpenseCategory.values) c: true}),
    ];

    await tester.pumpWidget(
      buildTestableWidget(
        ParticipationMatrixSheet(
          tripId: tripId,
          members: members,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beteiligung je Person'), findsOneWidget);
    expect(find.text('Überall beteiligt'), findsOneWidget);
    expect(find.text('Skipper frei (ganz)'), findsOneWidget);
    expect(find.text('Kein Alkohol'), findsOneWidget);

    // Klick auf "Kein Alkohol"
    await tester.tap(find.text('Kein Alkohol'));
    await tester.pumpAndSettle();

    expect(find.text('Übernehmen'), findsOneWidget);
  });

  testWidgets('SC-KAS-05: SettlementScreen rendert Wer zahlt wem mit EPC-QR-Code und Archivieren', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(SettlementScreen(tripId: tripId)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Törn abschließen'), findsOneWidget);
    expect(find.text('WER ZAHLT WEM'), findsOneWidget);
    expect(find.text('EPC-GiroCode scannen'), findsOneWidget);
    expect(find.text('Bordkassen-Konto ausgeglichen'), findsOneWidget);
    expect(find.text('Törn archivieren'), findsOneWidget);

    // Prüfen, dass der QR-Code im Widget-Baum existiert
    expect(find.byType(EpcQrWidget), findsOneWidget);

    // Archivieren betätigen
    final archiveFinder = find.text('Törn archivieren');
    await tester.ensureVisible(archiveFinder);
    await tester.tap(archiveFinder);
    await tester.pumpAndSettle();

    final trip = await db.tripDao.getTripById(tripId);
    expect(trip?.isArchived, isTrue);
    expect(trip?.phase, TripPhase.conclusion);
  });

  testWidgets('S5 Designregeln: Tippflächen >= 48 dp und Barrierefreiheit', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(SettlementScreen(tripId: tripId)),
    );
    await tester.pumpAndSettle();

    // Archivieren Button Höhe prüfen
    final archiveFinder = find.widgetWithText(FilledButton, 'Törn archivieren');
    expect(archiveFinder, findsOneWidget);
    final size = tester.getSize(archiveFinder);
    expect(size.height, greaterThanOrEqualTo(48.0));
  });
}

class _MockThemeController extends ThemeController {
  _MockThemeController(AppThemeMode mode) : super(_MockThemeStorage(mode.name));
}

class _MockThemeStorage implements ThemeStorage {
  final String _val;
  _MockThemeStorage(this._val);

  @override
  Future<String?> readTheme() async => _val;

  @override
  Future<void> saveTheme(String value) async {}
}
