/// Verbindliche Abnahmetests für Slice FB1-D – Bordkasse neu.
///
/// Prüft alle 5 Kriterien laut docs/SLICES_v0.15.md und FEEDBACK_R1 Punkt 9:
/// 1. Alle Kassenzahlungen laufen über den Kassenwart
/// 2. Abrechnung ohne Zeilen "→ Kasse" (kein Pseudomitglied)
/// 3. Summe der Salden ist mathematisch immer exakt 0 Cent
/// 4. "Bezahlen" öffnet EPC-QR-Code mit den Daten des Empfängers
/// 5. Fehlende Zahlungsdaten zeigen Hinweiskasten mit "Jetzt eintragen"
/// Sowie Kassenwart-Erstabfrage und Nachschuss-Banner bei Kassenstand < 50 €.
library;

import 'package:drift/drift.dart' show Value;
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
import 'package:proviantplaner/features/kitty/domain/calculation/kitty_engine.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/kitty/ui/kitty_screen.dart';
import 'package:proviantplaner/features/kitty/ui/settlement_screen.dart';
import 'package:proviantplaner/features/kitty/ui/widgets/epc_qr_widget.dart';

void main() {
  const engine = KittyEngine();

  late AppDatabase db;
  late KittyService kittyService;
  late int tripId;
  late int member1Id;
  late int member2Id;
  late int member3Id;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    kittyService = KittyService(
      tripDao: db.tripDao,
      expenseDao: db.expenseDao,
    );

    tripId = await db.tripDao.createTrip(
      TripsCompanion.insert(
        name: 'Sommertörn 2026',
        startDate: DateTime(2026, 8, 1),
        daysCount: const Value(7),
        kittyModel: const Value(KittyModel.sharedKitty),
      ),
    );

    // Skipper Alex (hat valide IBAN)
    member1Id = await db.tripDao.addCrewMember(
      CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Alex (Skipper)',
        isChild: const Value(false),
        isSkipperFree: const Value(true),
        skipperFreeScope: const Value('all'),
        categoryParticipation: const Value('{"all":true}'),
        iban: const Value('DE89370400440532013000'),
      ),
    );

    // Berta (hat valide IBAN)
    member2Id = await db.tripDao.addCrewMember(
      CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Berta',
        isChild: const Value(false),
        isSkipperFree: const Value(false),
        categoryParticipation: const Value('{"all":true}'),
        iban: const Value('DE12500105170648489890'),
      ),
    );

    // Chris (OHNE Zahlungsdaten / IBAN)
    member3Id = await db.tripDao.addCrewMember(
      CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Chris (ohne IBAN)',
        isChild: const Value(false),
        isSkipperFree: const Value(false),
        categoryParticipation: const Value('{"all":true}'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        kittyServiceProvider.overrideWithValue(kittyService),
        themeControllerProvider.overrideWith((ref) => _MockThemeController(AppThemeMode.light)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
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

  group('FB1-D Abnahmekriterium 1: Alle Kassenzahlungen laufen über den Kassenwart', () {
    test('calculateSharedKitty generiert nur Transfers zwischen Mitgliedern und Kassenwart', () {
      final alex = KittyMember(id: 1, name: 'Alex', isSkipperFree: true, categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final berta = KittyMember(id: 2, name: 'Berta', isSkipperFree: false, categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final chris = KittyMember(id: 3, name: 'Chris', isSkipperFree: false, categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final members = [alex, berta, chris];

      // Einzahlungen: Alex 100 €, Berta 200 €, Chris 50 €
      final deposits = [
        KittyDeposit(id: 1, tripId: 1, memberId: 1, amountInCents: 10000, paidAt: DateTime(2026, 8, 1)),
        KittyDeposit(id: 2, tripId: 1, memberId: 2, amountInCents: 20000, paidAt: DateTime(2026, 8, 1)),
        KittyDeposit(id: 3, tripId: 1, memberId: 3, amountInCents: 5000, paidAt: DateTime(2026, 8, 1)),
      ];

      // Ausgabe aus der Kasse: 150 € Proviant (Alex frei -> Berta und Chris zahlen je 75 €)
      final expenses = [
        KittyExpense(id: 1, tripId: 1, title: 'Proviant', amountInCents: 15000, category: ExpenseCategory.provisions, isPaidFromKitty: true, createdAt: DateTime(2026, 8, 2)),
      ];

      // Alex ist Kassenwart
      final result = engine.calculateSharedKitty(
        members: members,
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: alex.id,
      );

      expect(result.treasurer?.id, equals(alex.id));

      // Jeder Transfer MUSS den Kassenwart (Alex) als Beteiligten haben (entweder fromMember oder toMember)
      for (final transfer in result.settlementTransfers) {
        final touchesTreasurer = transfer.fromMember.id == alex.id || transfer.toMember.id == alex.id;
        expect(touchesTreasurer, isTrue, reason: 'Transfer $transfer muss über den Kassenwart laufen');
        expect(transfer.fromMember.name, isNot(equals('Bordkasse')));
        expect(transfer.toMember.name, isNot(equals('Bordkasse')));
      }
    });
  });

  group('FB1-D Abnahmekriterium 2: Abrechnung ohne Zeilen "→ Kasse"', () {
    testWidgets('SettlementScreen zeigt formatierte Zeilen ohne "→ Kasse" oder Pseudomitglied', (tester) async {
      await db.tripDao.setTripTreasurer(tripId, member1Id);

      // Einzahlung: Berta zahlt 200 € ein
      await kittyService.addDeposit(tripId: tripId, memberId: member2Id, amountInCents: 20000);
      // Ausgabe aus Kasse: 80 €
      await kittyService.addExpense(
        ExpenseInput(
          tripId: tripId,
          title: 'Lebensmittel',
          amountInCents: 8000,
          category: ExpenseCategory.provisions,
          isPaidFromKitty: true,
        ),
      );

      await tester.pumpWidget(buildTestableWidget(SettlementScreen(tripId: tripId)));
      await tester.pumpAndSettle();

      // Es darf an keiner Stelle "→ Kasse", "an Kasse" oder "von Kasse" stehen
      expect(find.textContaining('→ Kasse'), findsNothing);
      expect(find.textContaining('an Kasse'), findsNothing);
      expect(find.textContaining('von Kasse'), findsNothing);
      expect(find.text('Bordkasse'), findsNothing);

      // Zeilen müssen die neue Syntax verwenden ("bekommt ... von ..." oder "zahlt ... an ...")
      final hasBekommtOrZahlt = find.byWidgetPredicate((widget) {
        if (widget is Text && widget.data != null) {
          return widget.data!.contains('bekommt') || widget.data!.contains('zahlt');
        }
        return false;
      });
      expect(hasBekommtOrZahlt, findsWidgets);
    });
  });

  group('FB1-D Abnahmekriterium 3: Summe der Salden ist mathematisch immer exakt 0 Cent', () {
    test('Kasse im Plus (Restguthaben in Kasse): sum(netBalanceInCents) == 0', () {
      final alex = KittyMember(id: 1, name: 'Alex', isSkipperFree: false, categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final berta = KittyMember(id: 2, name: 'Berta', isSkipperFree: false, categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final members = [alex, berta];

      // Beide zahlen 150 € ein = 300 €
      final deposits = [
        KittyDeposit(id: 1, tripId: 1, memberId: 1, amountInCents: 15000, paidAt: DateTime(2026, 8, 1)),
        KittyDeposit(id: 2, tripId: 1, memberId: 2, amountInCents: 15000, paidAt: DateTime(2026, 8, 1)),
      ];
      // Ausgabe: 100 € -> 200 € Kassenrest
      final expenses = [
        KittyExpense(id: 1, tripId: 1, title: 'Diesel', amountInCents: 10000, category: ExpenseCategory.fuel, isPaidFromKitty: true, createdAt: DateTime(2026, 8, 2)),
      ];

      final result = engine.calculateSharedKitty(
        members: members,
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: alex.id,
      );

      final sumNet = result.memberBalances.fold<int>(0, (sum, b) => sum + b.netBalanceInCents);
      expect(sumNet, equals(0));
    });

    test('Kasse im Minus (mehr Ausgaben als Einzahlungen): sum(netBalanceInCents) == 0', () {
      final alex = KittyMember(id: 1, name: 'Alex', isSkipperFree: false, categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final berta = KittyMember(id: 2, name: 'Berta', isSkipperFree: false, categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final members = [alex, berta];

      // Einzahlung nur 20 €
      final deposits = [
        KittyDeposit(id: 1, tripId: 1, memberId: 1, amountInCents: 2000, paidAt: DateTime(2026, 8, 1)),
      ];
      // Ausgabe: 100 € -> Kasse -80 €
      final expenses = [
        KittyExpense(id: 1, tripId: 1, title: 'Hafen', amountInCents: 10000, category: ExpenseCategory.marinaBerth, isPaidFromKitty: true, createdAt: DateTime(2026, 8, 2)),
      ];

      final result = engine.calculateSharedKitty(
        members: members,
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: alex.id,
      );

      final sumNet = result.memberBalances.fold<int>(0, (sum, b) => sum + b.netBalanceInCents);
      expect(sumNet, equals(0));
    });

    test('Kasse glatt: sum(netBalanceInCents) == 0', () {
      final alex = KittyMember(id: 1, name: 'Alex', isSkipperFree: false, categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final berta = KittyMember(id: 2, name: 'Berta', isSkipperFree: false, categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final members = [alex, berta];

      final deposits = [
        KittyDeposit(id: 1, tripId: 1, memberId: 1, amountInCents: 5000, paidAt: DateTime(2026, 8, 1)),
        KittyDeposit(id: 2, tripId: 1, memberId: 2, amountInCents: 5000, paidAt: DateTime(2026, 8, 1)),
      ];
      final expenses = [
        KittyExpense(id: 1, tripId: 1, title: 'Einkauf', amountInCents: 10000, category: ExpenseCategory.provisions, isPaidFromKitty: true, createdAt: DateTime(2026, 8, 2)),
      ];

      final result = engine.calculateSharedKitty(
        members: members,
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: alex.id,
      );

      final sumNet = result.memberBalances.fold<int>(0, (sum, b) => sum + b.netBalanceInCents);
      expect(sumNet, equals(0));
    });
  });

  group('FB1-D Abnahmekriterium 4: Bezahlen öffnet QR mit den Daten des Empfängers', () {
    testWidgets('Tipp auf Bezahlen öffnet EpcQrWidget mit Daten des Empfängers', (tester) async {
      await db.tripDao.setTripTreasurer(tripId, member1Id); // Alex ist Kassenwart

      // Berta zahlt weniger ein als Alex -> Berta schuldet Alex einen Ausgleich
      await kittyService.addDeposit(tripId: tripId, memberId: member1Id, amountInCents: 20000);
      await kittyService.addDeposit(tripId: tripId, memberId: member2Id, amountInCents: 5000);
      // Ausgabe: 150 € Proviant
      await kittyService.addExpense(
        ExpenseInput(
          tripId: tripId,
          title: 'Lebensmittel',
          amountInCents: 15000,
          category: ExpenseCategory.provisions,
          isPaidFromKitty: true,
        ),
      );

      await tester.pumpWidget(buildTestableWidget(SettlementScreen(tripId: tripId)));
      await tester.pumpAndSettle();

      // Es gibt eine Überweisung an Alex (Skipper) mit valider IBAN
      expect(find.text('Bezahlen'), findsWidgets);

      // Klick auf den ersten Bezahlen-Button
      await tester.tap(find.text('Bezahlen').first);
      await tester.pumpAndSettle();

      // EPC-QR-Code muss jetzt sichtbar sein
      expect(find.byType(EpcQrWidget), findsWidgets);
      final qrWidget = tester.widget<EpcQrWidget>(find.byType(EpcQrWidget).first);
      // Der Empfänger ist Alex
      expect(qrWidget.payload.beneficiaryName, equals('Alex (Skipper)'));
      expect(qrWidget.payload.iban, equals('DE89370400440532013000'));
    });
  });

  group('FB1-D Abnahmekriterium 5: Fehlende Zahlungsdaten zeigen Hinweiskasten', () {
    testWidgets('Empfänger ohne Zahlungsdaten zeigt Hinweis "Für ... keine Zahlungsdaten hinterlegt" mit "Jetzt eintragen"', (tester) async {
      // Chris (member3Id) wird als Kassenwart gesetzt
      await db.tripDao.setTripTreasurer(tripId, member3Id);

      // Berta zahlt 0 € ein, Chris legt 100 € aus
      await kittyService.addDeposit(tripId: tripId, memberId: member3Id, amountInCents: 10000);
      await kittyService.addExpense(
        ExpenseInput(
          tripId: tripId,
          title: 'Proviant',
          amountInCents: 6000,
          category: ExpenseCategory.provisions,
          isPaidFromKitty: true,
        ),
      );

      await tester.pumpWidget(buildTestableWidget(SettlementScreen(tripId: tripId)));
      await tester.pumpAndSettle();

      // Berta zahlt an Chris, aber Chris hat keine IBAN
      expect(find.text('Bezahlen'), findsWidgets);
      await tester.tap(find.text('Bezahlen').first);
      await tester.pumpAndSettle();

      // Hinweiskasten für Chris muss erscheinen
      expect(find.textContaining('keine Zahlungsdaten hinterlegt'), findsOneWidget);
      expect(find.text('Jetzt eintragen'), findsOneWidget);
    });
  });

  group('FB1-D Features: Kassenwart-Erstabfrage und Nachschuss-Banner', () {
    testWidgets('Erstaufruf der Kasse ohne Kassenwart zeigt Auswahldialog', (tester) async {
      // Trip ohne Kassenwart (treasurerMemberId == null)
      await tester.pumpWidget(buildTestableWidget(KittyScreen(tripId: tripId)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Wer verwaltet die Kasse?'), findsOneWidget);
      expect(find.text('Alex (Skipper)'), findsWidgets);
      expect(find.text('Berta'), findsWidgets);
      expect(find.text('Als Kassenwart festlegen'), findsOneWidget);

      // Klick auf "Als Kassenwart festlegen"
      await tester.tap(find.text('Als Kassenwart festlegen'));
      await tester.pumpAndSettle();

      // Trip hat nun den ausgewählten Kassenwart
      final trip = await db.tripDao.getTripById(tripId);
      expect(trip?.treasurerMemberId, isNotNull);
    });

    testWidgets('Nachschuss-Banner erscheint bei Kassenstand < 50 €', (tester) async {
      await db.tripDao.setTripTreasurer(tripId, member1Id);

      // 60 € eingezahlt, 40 € ausgegeben -> 20 € Kassenstand (< 50 €)
      await kittyService.addDeposit(tripId: tripId, memberId: member1Id, amountInCents: 6000);
      await kittyService.addExpense(
        ExpenseInput(
          tripId: tripId,
          title: 'Mittagessen',
          amountInCents: 4000,
          category: ExpenseCategory.restaurant,
          isPaidFromKitty: true,
        ),
      );

      await tester.pumpWidget(buildTestableWidget(KittyScreen(tripId: tripId)));
      await tester.pumpAndSettle();

      expect(find.text('Kasse fast leer – jeder legt 50 € nach?'), findsOneWidget);
      expect(find.text('Übernehmen'), findsOneWidget);

      // Klick auf Übernehmen öffnet PaymentSheet vorbefüllt mit 50 €
      await tester.tap(find.text('Übernehmen'));
      await tester.pumpAndSettle();

      expect(find.text('Einzahlung erfassen'), findsOneWidget);
      expect(find.text('50.00'), findsOneWidget);
    });
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
