/// FIX-B – Unified Settlement Ledger Abnahmetests.
///
/// Vollständiger Nachweis aller Kriterien gemäß:
/// - docs/impl/FIXB_release_reconciliation_2026-10-06.md
/// - docs/impl/FIXB_plan.md
/// - Issue #27
library;

import 'dart:math';
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
import 'package:proviantplaner/features/kitty/ui/settlement_screen.dart';
import 'package:proviantplaner/features/kitty/ui/widgets/epc_qr_widget.dart';
import 'package:proviantplaner/features/kitty/ui/widgets/expense_sheet.dart';

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

void main() {
  const engine = KittyEngine();

  late AppDatabase db;
  late KittyService kittyService;
  late int tripId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    kittyService = KittyService(
      tripDao: db.tripDao,
      expenseDao: db.expenseDao,
      engine: engine,
    );

    tripId = await db.tripDao.createTrip(
      TripsCompanion.insert(
        name: 'FIX-B Test Trip',
        startDate: DateTime(2026, 8, 1),
        daysCount: const Value(7),
        kittyModel: const Value(KittyModel.sharedKitty),
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

  group('FIX-B Kriterium 1: Nur Kassenausgaben (Only Kitty Expenses)', () {
    test('Kassenausgaben reduzieren Kassenstand und gehen centgenau in Kostenanteile ein', () {
      final a = KittyMember(id: 1, name: 'A', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final b = KittyMember(id: 2, name: 'B', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final members = [a, b];

      final deposits = [
        KittyDeposit(id: 1, tripId: 1, memberId: 1, amountInCents: 10000, paidAt: DateTime(2026, 8, 1)),
        KittyDeposit(id: 2, tripId: 1, memberId: 2, amountInCents: 10000, paidAt: DateTime(2026, 8, 1)),
      ];

      final expenses = [
        KittyExpense(
          id: 1,
          tripId: 1,
          title: 'Proviant',
          amountInCents: 12000,
          category: ExpenseCategory.provisions,
          isPaidFromKitty: true,
          createdAt: DateTime(2026, 8, 2),
        ),
      ];

      final ledger = engine.calculateUnifiedLedger(
        members: members,
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: a.id,
      );

      expect(ledger.totalDepositsInCents, equals(20000));
      expect(ledger.totalExpensesInCents, equals(12000));
      expect(ledger.kittyPaidExpensesInCents, equals(12000));
      expect(ledger.personallyPaidExpensesInCents, equals(0));
      expect(ledger.kittyCashInCents, equals(8000)); // 200 € - 120 € = 80 € Rest in Kasse

      // A (Kassenwart): Einzahlung 100 €, Kostenanteil 60 €, hält 80 € Kasse
      // net = 100 - 60 - 80 = -40 € (-4000 Cent)
      final aBal = ledger.memberBalances.firstWhere((m) => m.member.id == a.id);
      expect(aBal.paidInCents, equals(10000));
      expect(aBal.costShareInCents, equals(6000));
      expect(aBal.cashHeldInCents, equals(8000));
      expect(aBal.netBalanceInCents, equals(-4000));

      // B: Einzahlung 100 €, Kostenanteil 60 €, hält 0 €
      // net = 100 - 60 - 0 = +40 € (+4000 Cent)
      final bBal = ledger.memberBalances.firstWhere((m) => m.member.id == b.id);
      expect(bBal.paidInCents, equals(10000));
      expect(bBal.costShareInCents, equals(6000));
      expect(bBal.cashHeldInCents, equals(0));
      expect(bBal.netBalanceInCents, equals(4000));

      // Summe der Netto-Salden ist exakt 0
      final sumNet = ledger.memberBalances.fold<int>(0, (sum, m) => sum + m.netBalanceInCents);
      expect(sumNet, equals(0));
    });
  });

  group('FIX-B Kriterium 2: Nur personengezahlte Ausgaben (Only Personally Paid Expenses)', () {
    test('Personengezahlte Ausgaben erzeugen Payer-Credit und Summe 0 ohne Kassenbewegung', () {
      final a = KittyMember(id: 1, name: 'A', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final b = KittyMember(id: 2, name: 'B', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final members = [a, b];

      final expenses = [
        KittyExpense(
          id: 1,
          tripId: 1,
          title: 'Diesel von B',
          amountInCents: 6000,
          category: ExpenseCategory.fuel,
          isPaidFromKitty: false,
          paidByMemberId: b.id,
          createdAt: DateTime(2026, 8, 2),
        ),
      ];

      final ledger = engine.calculateUnifiedLedger(
        members: members,
        deposits: const [],
        expenses: expenses,
        treasurerMemberId: a.id,
      );

      expect(ledger.totalDepositsInCents, equals(0));
      expect(ledger.totalExpensesInCents, equals(6000));
      expect(ledger.kittyPaidExpensesInCents, equals(0));
      expect(ledger.personallyPaidExpensesInCents, equals(6000));
      expect(ledger.kittyCashInCents, equals(0));

      final aBal = ledger.memberBalances.firstWhere((m) => m.member.id == a.id);
      expect(aBal.paidInCents, equals(0));
      expect(aBal.costShareInCents, equals(3000));
      expect(aBal.netBalanceInCents, equals(-3000));

      final bBal = ledger.memberBalances.firstWhere((m) => m.member.id == b.id);
      expect(bBal.paidInCents, equals(6000));
      expect(bBal.costShareInCents, equals(3000));
      expect(bBal.netBalanceInCents, equals(3000));

      final sumNet = ledger.memberBalances.fold<int>(0, (sum, m) => sum + m.netBalanceInCents);
      expect(sumNet, equals(0));
    });
  });

  group('FIX-B Kriterium 3, 4, 5, 6, 7, 10: Kanonisches 4-Personen Mixed Case', () {
    test('Exakte Berechnung des kanonischen 4-Personen Mixed Cases laut Spezifikation', () {
      // 4 Teilnehmer: A, B, C, D
      // A = Kassenwart
      final a = KittyMember(id: 1, name: 'A', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final b = KittyMember(id: 2, name: 'B', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final c = KittyMember(id: 3, name: 'C', categoryParticipation: {for (final cat in ExpenseCategory.values) cat: true});
      final d = KittyMember(id: 4, name: 'D', categoryParticipation: {for (final cat in ExpenseCategory.values) cat: true});
      final members = [a, b, c, d];

      // Einzahlungen: A/B/C/D je 100 EUR = 10.000 Cent -> Summe 40.000 Cent
      final deposits = [
        KittyDeposit(id: 1, tripId: 1, memberId: 1, amountInCents: 10000, paidAt: DateTime(2026, 8, 1)),
        KittyDeposit(id: 2, tripId: 1, memberId: 2, amountInCents: 10000, paidAt: DateTime(2026, 8, 1)),
        KittyDeposit(id: 3, tripId: 1, memberId: 3, amountInCents: 10000, paidAt: DateTime(2026, 8, 1)),
        KittyDeposit(id: 4, tripId: 1, memberId: 4, amountInCents: 10000, paidAt: DateTime(2026, 8, 1)),
      ];

      // Ausgaben:
      // E1: 200 EUR (20.000 Cent) aus Kasse bezahlt
      // E2: 120 EUR (12.000 Cent) persönlich von B bezahlt
      final expenses = [
        KittyExpense(
          id: 1,
          tripId: 1,
          title: 'Kassenausgabe Hafen',
          amountInCents: 20000,
          category: ExpenseCategory.marinaBerth,
          isPaidFromKitty: true,
          createdAt: DateTime(2026, 8, 2),
        ),
        KittyExpense(
          id: 2,
          tripId: 1,
          title: 'Persönliche Ausgabe von B Restaurant',
          amountInCents: 12000,
          category: ExpenseCategory.restaurant,
          isPaidFromKitty: false,
          paidByMemberId: b.id,
          createdAt: DateTime(2026, 8, 3),
        ),
      ];

      final sharedResult = engine.calculateSharedKitty(
        members: members,
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: a.id,
      );

      // Kriterium 4 & 6:
      // total expenses = 320 EUR
      expect(sharedResult.totalExpensesInCents, equals(32000));
      // kitty expenses = 200 EUR
      expect(sharedResult.kittyPaidExpensesInCents, equals(20000));
      // person expenses = 120 EUR
      expect(sharedResult.personallyPaidExpensesInCents, equals(12000));
      // kitty cash = 400 - 200 = 200 EUR (persönliche Ausgabe ändert den Kassenbestand nicht!)
      expect(sharedResult.currentBalanceInCents, equals(20000));

      // Kostenanteile je Person: 320 EUR / 4 = 80 EUR (8.000 Cent)
      for (final m in sharedResult.memberBalances) {
        expect(m.costShareInCents, equals(8000), reason: '${m.member.name} muss genau 80 EUR Kostenanteil tragen');
      }

      // Kriterium 5: Factual Gross Contributions (reale Bruttobeiträge, keine synthetischen Werte)
      final aBal = sharedResult.memberBalances.firstWhere((m) => m.member.id == a.id);
      final bBal = sharedResult.memberBalances.firstWhere((m) => m.member.id == b.id);
      final cBal = sharedResult.memberBalances.firstWhere((m) => m.member.id == c.id);
      final dBal = sharedResult.memberBalances.firstWhere((m) => m.member.id == d.id);

      expect(aBal.paidInCents, equals(10000)); // 100 EUR Einzahlung
      expect(aBal.actualDepositsInCents, equals(10000));
      expect(aBal.personallyPaidExpensesInCents, equals(0));
      expect(aBal.cashHeldInCents, equals(20000)); // hält 200 EUR physische Kasse

      expect(bBal.paidInCents, equals(22000)); // 100 EUR Einzahlung + 120 EUR Auslagen = 220 EUR
      expect(bBal.actualDepositsInCents, equals(10000));
      expect(bBal.personallyPaidExpensesInCents, equals(12000));
      expect(bBal.cashHeldInCents, equals(0));

      expect(cBal.paidInCents, equals(10000));
      expect(cBal.actualDepositsInCents, equals(10000));
      expect(cBal.personallyPaidExpensesInCents, equals(0));
      expect(cBal.cashHeldInCents, equals(0));

      expect(dBal.paidInCents, equals(10000));
      expect(dBal.actualDepositsInCents, equals(10000));
      expect(dBal.personallyPaidExpensesInCents, equals(0));
      expect(dBal.cashHeldInCents, equals(0));

      // Netto-Salden:
      // A: 100 - 80 - 200 = -180 EUR (-18.000 Cent)
      expect(aBal.netBalanceInCents, equals(-18000));
      // B: 220 - 80 = +140 EUR (+14.000 Cent)
      expect(bBal.netBalanceInCents, equals(14000));
      // C: 100 - 80 = +20 EUR (+2.000 Cent)
      expect(cBal.netBalanceInCents, equals(2000));
      // D: 100 - 80 = +20 EUR (+2.000 Cent)
      expect(dBal.netBalanceInCents, equals(2000));

      // Kriterium 7: Summe aller Netto-Salden ist mathematisch exakt 0 Cent
      final sumNet = sharedResult.memberBalances.fold<int>(0, (sum, m) => sum + m.netBalanceInCents);
      expect(sumNet, equals(0));

      // Kriterium 10: Shared Transfers sind Kassenwart-zentriert
      // A -> B: 140 EUR
      // A -> C: 20 EUR
      // A -> D: 20 EUR
      final transfers = sharedResult.settlementTransfers;
      expect(transfers.length, equals(3));

      final transferToB = transfers.firstWhere((t) => t.toMember.id == b.id);
      expect(transferToB.fromMember.id, equals(a.id));
      expect(transferToB.amountInCents, equals(14000));

      final transferToC = transfers.firstWhere((t) => t.toMember.id == c.id);
      expect(transferToC.fromMember.id, equals(a.id));
      expect(transferToC.amountInCents, equals(2000));

      final transferToD = transfers.firstWhere((t) => t.toMember.id == d.id);
      expect(transferToD.fromMember.id, equals(a.id));
      expect(transferToD.amountInCents, equals(2000));
    });
  });

  group('FIX-B Kriterium 8 & 11: Individual Settlement mit Debt Simplification', () {
    test('Einzelabrechnung nutzt einheitliche Balances und minimiert Überweisungen', () {
      final a = KittyMember(id: 1, name: 'A', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final b = KittyMember(id: 2, name: 'B', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final c = KittyMember(id: 3, name: 'C', categoryParticipation: {for (final cat in ExpenseCategory.values) cat: true});
      final members = [a, b, c];

      // A zahlt 120 € Restaurant (je 40 €)
      // B zahlt 30 € Proviant (je 10 €)
      // C zahlt nichts
      final expenses = [
        KittyExpense(
          id: 1,
          tripId: 1,
          title: 'Restaurant',
          amountInCents: 12000,
          category: ExpenseCategory.restaurant,
          isPaidFromKitty: false,
          paidByMemberId: a.id,
          createdAt: DateTime(2026, 8, 2),
        ),
        KittyExpense(
          id: 2,
          tripId: 1,
          title: 'Proviant',
          amountInCents: 3000,
          category: ExpenseCategory.provisions,
          isPaidFromKitty: false,
          paidByMemberId: b.id,
          createdAt: DateTime(2026, 8, 3),
        ),
      ];

      final indResult = engine.calculateIndividualSettlement(
        members: members,
        expenses: expenses,
      );

      // Gesamtkosten 150 €, pro Person 50 €
      expect(indResult.totalExpensesInCents, equals(15000));

      // A: paid 120 €, cost 50 € -> net +70 €
      final aBal = indResult.memberBalances.firstWhere((m) => m.member.id == a.id);
      expect(aBal.netBalanceInCents, equals(7000));

      // B: paid 30 €, cost 50 € -> net -20 €
      final bBal = indResult.memberBalances.firstWhere((m) => m.member.id == b.id);
      expect(bBal.netBalanceInCents, equals(-2000));

      // C: paid 0 €, cost 50 € -> net -50 €
      final cBal = indResult.memberBalances.firstWhere((m) => m.member.id == c.id);
      expect(cBal.netBalanceInCents, equals(-5000));

      // Summe ist exakt 0
      final sumNet = indResult.memberBalances.fold<int>(0, (sum, m) => sum + m.netBalanceInCents);
      expect(sumNet, equals(0));

      // Simplified transfers: B zahlt 20 € an A, C zahlt 50 € an A
      expect(indResult.simplifiedTransfers.length, equals(2));
      final tFromB = indResult.simplifiedTransfers.firstWhere((t) => t.fromMember.id == b.id);
      expect(tFromB.toMember.id, equals(a.id));
      expect(tFromB.amountInCents, equals(2000));

      final tFromC = indResult.simplifiedTransfers.firstWhere((t) => t.fromMember.id == c.id);
      expect(tFromC.toMember.id, equals(a.id));
      expect(tFromC.amountInCents, equals(5000));
    });
  });

  group('FIX-B Kriterium 9: Model Switch Invariance (Modellwechsel-Invarianz)', () {
    test('Wechsel sharedKitty <-> individualSettlement verändert die Netto-Salden für kein Mitglied', () async {
      final aId = await db.tripDao.addCrewMember(
        CrewMembersCompanion.insert(
          tripId: tripId,
          name: 'Alice',
          isChild: const Value(false),
          isSkipperFree: const Value(false),
          categoryParticipation: const Value('{"all":true}'),
        ),
      );
      final bId = await db.tripDao.addCrewMember(
        CrewMembersCompanion.insert(
          tripId: tripId,
          name: 'Bob',
          isChild: const Value(false),
          isSkipperFree: const Value(false),
          categoryParticipation: const Value('{"all":true}'),
        ),
      );
      final cId = await db.tripDao.addCrewMember(
        CrewMembersCompanion.insert(
          tripId: tripId,
          name: 'Charlie',
          isChild: const Value(false),
          isSkipperFree: const Value(false),
          categoryParticipation: const Value('{"all":true}'),
        ),
      );
      await db.tripDao.setTripTreasurer(tripId, aId);

      // Einzahlungen
      await kittyService.addDeposit(tripId: tripId, memberId: aId, amountInCents: 10000);
      await kittyService.addDeposit(tripId: tripId, memberId: bId, amountInCents: 10000);
      await kittyService.addDeposit(tripId: tripId, memberId: cId, amountInCents: 10000);

      // Ausgaben gemischt: 1x Kasse, 1x Person Bob
      await kittyService.addExpense(
        ExpenseInput(
          tripId: tripId,
          title: 'Hafen Kasse',
          amountInCents: 15000,
          category: ExpenseCategory.marinaBerth,
          isPaidFromKitty: true,
        ),
      );
      await kittyService.addExpense(
        ExpenseInput(
          tripId: tripId,
          title: 'Einkauf Bob',
          amountInCents: 9000,
          category: ExpenseCategory.provisions,
          isPaidFromKitty: false,
          paidByMemberId: bId,
        ),
      );

      // 1. In Shared Kitty laden
      final sharedData = await kittyService.loadKittyData(tripId);
      expect(sharedData.model, equals(KittyModel.sharedKitty));
      final sharedNetA = sharedData.balances.firstWhere((b) => b.member.id == aId).netBalanceInCents;
      final sharedNetB = sharedData.balances.firstWhere((b) => b.member.id == bId).netBalanceInCents;
      final sharedNetC = sharedData.balances.firstWhere((b) => b.member.id == cId).netBalanceInCents;

      // 2. Zu Individual Settlement wechseln
      final switched = await kittyService.switchKittyModel(tripId, KittyModel.individualSettlement);
      expect(switched, isTrue);

      final indData = await kittyService.loadKittyData(tripId);
      expect(indData.model, equals(KittyModel.individualSettlement));
      final indNetA = indData.balances.firstWhere((b) => b.member.id == aId).netBalanceInCents;
      final indNetB = indData.balances.firstWhere((b) => b.member.id == bId).netBalanceInCents;
      final indNetC = indData.balances.firstWhere((b) => b.member.id == cId).netBalanceInCents;

      // INVARIANZ: Netto-Salden MÜSSEN cent-exakt identisch sein
      expect(indNetA, equals(sharedNetA));
      expect(indNetB, equals(sharedNetB));
      expect(indNetC, equals(sharedNetC));

      // 3. Zurück zu Shared Kitty wechseln
      await kittyService.switchKittyModel(tripId, KittyModel.sharedKitty);
      final backData = await kittyService.loadKittyData(tripId);
      expect(backData.model, equals(KittyModel.sharedKitty));
      final backNetA = backData.balances.firstWhere((b) => b.member.id == aId).netBalanceInCents;
      final backNetB = backData.balances.firstWhere((b) => b.member.id == bId).netBalanceInCents;
      final backNetC = backData.balances.firstWhere((b) => b.member.id == cId).netBalanceInCents;

      expect(backNetA, equals(sharedNetA));
      expect(backNetB, equals(sharedNetB));
      expect(backNetC, equals(sharedNetC));
    });
  });

  group('FIX-B Kriterium 12, 13, 14, 15: Beteiligungsregeln, Custom-Split & Skipper frei', () {
    test('Kategoriebeteiligung schließt Nicht-Beteiligte von Kostenanteilen aus', () {
      final a = KittyMember(id: 1, name: 'A', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final b = KittyMember(id: 2, name: 'B (No Alk)', categoryParticipation: {
        for (final c in ExpenseCategory.values) c: c != ExpenseCategory.drinks,
      });
      final members = [a, b];

      final exp = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Wein',
        amountInCents: 5000,
        category: ExpenseCategory.drinks,
        isPaidFromKitty: true,
        createdAt: DateTime(2026, 8, 1),
      );

      final split = engine.distributeExpense(exp, members);
      expect(split[a.id], equals(5000));
      expect(split[b.id], isNull);
    });

    test('Custom-Split teilt Beträge manuell vorgegeben centgenau auf', () {
      final a = KittyMember(id: 1, name: 'A', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final b = KittyMember(id: 2, name: 'B', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final members = [a, b];

      final exp = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Sonderposten',
        amountInCents: 10000,
        category: ExpenseCategory.other,
        isPaidFromKitty: true,
        createdAt: DateTime(2026, 8, 1),
        customSplitInCents: {a.id: 7000, b.id: 3000},
      );

      final split = engine.distributeExpense(exp, members);
      expect(split[a.id], equals(7000));
      expect(split[b.id], equals(3000));
    });

    test('Skipper frei partiell (exclude_food) zahlt Essen mit, aber Diesel und Liegeplatz nicht', () {
      const skipper = KittyMember(
        id: 1,
        name: 'Skipper',
        isSkipperFree: true,
        skipperFreeScope: 'exclude_food',
        categoryParticipation: {},
      );
      final crew = KittyMember(id: 2, name: 'Crew', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final members = [skipper, crew];

      // Proviant: beide zahlen
      final foodExp = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Essen',
        amountInCents: 4000,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
        createdAt: DateTime(2026, 8, 1),
      );
      final foodSplit = engine.distributeExpense(foodExp, members);
      expect(foodSplit[skipper.id], equals(2000));
      expect(foodSplit[crew.id], equals(2000));

      // Diesel: nur Crew zahlt
      final fuelExp = KittyExpense(
        id: 2,
        tripId: 1,
        title: 'Diesel',
        amountInCents: 4000,
        category: ExpenseCategory.fuel,
        isPaidFromKitty: true,
        createdAt: DateTime(2026, 8, 1),
      );
      final fuelSplit = engine.distributeExpense(fuelExp, members);
      expect(fuelSplit[skipper.id], isNull);
      expect(fuelSplit[crew.id], equals(4000));
    });

    test('Cent-Restaufteilung teilt 1 Cent Rest ohne Verlust auf erste Teilnehmer auf', () {
      final a = KittyMember(id: 1, name: 'A', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final b = KittyMember(id: 2, name: 'B', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
      final c = KittyMember(id: 3, name: 'C', categoryParticipation: {for (final cat in ExpenseCategory.values) cat: true});
      final members = [a, b, c];

      final exp = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Test Rest',
        amountInCents: 100, // 1,00 € auf 3 Personen: 34 + 33 + 33 Cent
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
        createdAt: DateTime(2026, 8, 1),
      );

      final split = engine.distributeExpense(exp, members);
      expect(split[a.id], equals(34));
      expect(split[b.id], equals(33));
      expect(split[c.id], equals(33));
      expect(split.values.fold<int>(0, (s, v) => s + v), equals(100));
    });
  });

  group('FIX-B Kriterium 16: Zero, Positive & Negative Kitty Cash', () {
    final a = KittyMember(id: 1, name: 'A', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
    final b = KittyMember(id: 2, name: 'B', categoryParticipation: {for (final c in ExpenseCategory.values) c: true});
    final members = [a, b];

    test('Positive Kitty Cash: Restguthaben in Kasse, Summe Net-Salden = 0', () {
      final deposits = [
        KittyDeposit(id: 1, tripId: 1, memberId: 1, amountInCents: 20000, paidAt: DateTime(2026, 8, 1)),
        KittyDeposit(id: 2, tripId: 1, memberId: 2, amountInCents: 20000, paidAt: DateTime(2026, 8, 1)),
      ];
      final expenses = [
        KittyExpense(id: 1, tripId: 1, title: 'Hafen', amountInCents: 10000, category: ExpenseCategory.marinaBerth, isPaidFromKitty: true, createdAt: DateTime(2026, 8, 2)),
      ];

      final res = engine.calculateSharedKitty(members: members, deposits: deposits, expenses: expenses, treasurerMemberId: a.id);
      expect(res.currentBalanceInCents, equals(30000)); // 400 - 100 = 300 €
      final sum = res.memberBalances.fold<int>(0, (s, m) => s + m.netBalanceInCents);
      expect(sum, equals(0));
    });

    test('Zero Kitty Cash: Kasse exakt aufgebraucht, Summe Net-Salden = 0', () {
      final deposits = [
        KittyDeposit(id: 1, tripId: 1, memberId: 1, amountInCents: 5000, paidAt: DateTime(2026, 8, 1)),
        KittyDeposit(id: 2, tripId: 1, memberId: 2, amountInCents: 5000, paidAt: DateTime(2026, 8, 1)),
      ];
      final expenses = [
        KittyExpense(id: 1, tripId: 1, title: 'Hafen', amountInCents: 10000, category: ExpenseCategory.marinaBerth, isPaidFromKitty: true, createdAt: DateTime(2026, 8, 2)),
      ];

      final res = engine.calculateSharedKitty(members: members, deposits: deposits, expenses: expenses, treasurerMemberId: a.id);
      expect(res.currentBalanceInCents, equals(0));
      final sum = res.memberBalances.fold<int>(0, (s, m) => s + m.netBalanceInCents);
      expect(sum, equals(0));
    });

    test('Negative Kitty Cash: Mehr Ausgaben als Einzahlungen, Summe Net-Salden = 0', () {
      // 0 Einzahlungen, aber 100 € Kassenausgabe -> Kasse -100 €
      final expenses = [
        KittyExpense(id: 1, tripId: 1, title: 'Hafen', amountInCents: 10000, category: ExpenseCategory.marinaBerth, isPaidFromKitty: true, createdAt: DateTime(2026, 8, 2)),
      ];

      final res = engine.calculateSharedKitty(members: members, deposits: const [], expenses: expenses, treasurerMemberId: a.id);
      expect(res.currentBalanceInCents, equals(-10000));

      // A (Kassenwart) hat die 100 € physisch ausgelegt:
      // net_A = 0 - 50 - (-100) = +50 € (bekommt 50 € erstattet)
      // net_B = 0 - 50 - 0 = -50 € (zahlt 50 € an Kassenwart)
      final aBal = res.memberBalances.firstWhere((m) => m.member.id == a.id);
      final bBal = res.memberBalances.firstWhere((m) => m.member.id == b.id);
      expect(aBal.netBalanceInCents, equals(5000));
      expect(bBal.netBalanceInCents, equals(-5000));

      final sum = res.memberBalances.fold<int>(0, (s, m) => s + m.netBalanceInCents);
      expect(sum, equals(0));

      // Transfer: B zahlt an A 50 €
      expect(res.settlementTransfers.length, equals(1));
      expect(res.settlementTransfers.first.fromMember.id, equals(b.id));
      expect(res.settlementTransfers.first.toMember.id, equals(a.id));
      expect(res.settlementTransfers.first.amountInCents, equals(5000));
    });
  });

  group('FIX-B Kriterium 17: Expense Source Invariant Enforcement', () {
    test('addExpense lehnt ungültige Kombinationen von isPaidFromKitty und paidByMemberId strikt ab', () async {
      final aId = await db.tripDao.addCrewMember(
        CrewMembersCompanion.insert(
          tripId: tripId,
          name: 'Payer A',
          categoryParticipation: const Value('{"all":true}'),
        ),
      );

      // Kasse mit Zahler -> ungültig
      expect(
        () => kittyService.addExpense(
          ExpenseInput(
            tripId: tripId,
            title: 'Ungültig 1',
            amountInCents: 5000,
            category: ExpenseCategory.provisions,
            isPaidFromKitty: true,
            paidByMemberId: aId,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Person ohne Zahler -> ungültig
      expect(
        () => kittyService.addExpense(
          ExpenseInput(
            tripId: tripId,
            title: 'Ungültig 2',
            amountInCents: 5000,
            category: ExpenseCategory.provisions,
            isPaidFromKitty: false,
            paidByMemberId: null,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Gültig: Kasse ohne Zahler
      final kasseId = await kittyService.addExpense(
        ExpenseInput(
          tripId: tripId,
          title: 'Gültig Kasse',
          amountInCents: 5000,
          category: ExpenseCategory.provisions,
          isPaidFromKitty: true,
          paidByMemberId: null,
        ),
      );
      expect(kasseId, isPositive);

      // Gültig: Person mit Zahler
      final personId = await kittyService.addExpense(
        ExpenseInput(
          tripId: tripId,
          title: 'Gültig Person',
          amountInCents: 5000,
          category: ExpenseCategory.provisions,
          isPaidFromKitty: false,
          paidByMemberId: aId,
        ),
      );
      expect(personId, isPositive);

      // updateExpense mit ungültigen Kombinationen lehnt ab
      expect(
        () => kittyService.updateExpense(
          id: kasseId,
          input: ExpenseInput(
            tripId: tripId,
            title: 'Update ungültig',
            amountInCents: 6000,
            category: ExpenseCategory.provisions,
            isPaidFromKitty: true,
            paidByMemberId: aId,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => kittyService.updateExpense(
          id: personId,
          input: ExpenseInput(
            tripId: tripId,
            title: 'Update ungültig',
            amountInCents: 6000,
            category: ExpenseCategory.provisions,
            isPaidFromKitty: false,
            paidByMemberId: null,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('FIX-B Kriterium 18: ExpenseSheet Real UI Journey (Person als Zahler in Shared Kitty)', () {
    testWidgets('ExpenseSheet erlaubt Auswahl Person als Zahler in Shared Kitty und speichert valide', (tester) async {
      final aId = await db.tripDao.addCrewMember(
        CrewMembersCompanion.insert(tripId: tripId, name: 'Anna', categoryParticipation: const Value('{"all":true}')),
      );
      final bId = await db.tripDao.addCrewMember(
        CrewMembersCompanion.insert(tripId: tripId, name: 'Ben', categoryParticipation: const Value('{"all":true}')),
      );

      final members = [
        KittyMember(id: aId, name: 'Anna', categoryParticipation: {}),
        KittyMember(id: bId, name: 'Ben', categoryParticipation: {}),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: ExpenseSheet(
              tripId: tripId,
              kittyModel: KittyModel.sharedKitty,
              members: members,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Betrag eingeben: 80.00
      await tester.enterText(find.byType(TextFormField).first, '80.00');

      // SegmentedButton auf "Person" umschalten
      final personSegment = find.text('Person');
      expect(personSegment, findsOneWidget);
      await tester.tap(personSegment);
      await tester.pumpAndSettle();

      // Dropdown für Crew-Mitglied muss jetzt sichtbar sein
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);

      // Speichern
      final saveBtn = find.text('Ausgabe speichern');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // In der Datenbank prüfen
      final expenses = await db.expenseDao.getExpensesForTrip(tripId);
      expect(expenses.length, equals(1));
      final saved = expenses.first;
      expect(saved.isPaidFromKitty, isFalse);
      expect(saved.paidByCrewMemberId, isNotNull);
      expect(saved.amount, equals(80.0));

      // Im Service prüfen: loadKittyData berechnet Ben als Zahler
      final data = await kittyService.loadKittyData(tripId);
      expect(data.sharedResult?.personallyPaidExpensesInCents, equals(8000));
      expect(data.sharedResult?.totalExpensesInCents, equals(8000));
      expect(data.sharedResult?.kittyPaidExpensesInCents, equals(0));
    });
  });

  group('FIX-B Kriterium 19: Expense Source Edit Kasse <-> Person', () {
    testWidgets('Bestehende Ausgabe kann zwischen Kasse und Person gewechselt werden', (tester) async {
      final aId = await db.tripDao.addCrewMember(
        CrewMembersCompanion.insert(tripId: tripId, name: 'Anna', categoryParticipation: const Value('{"all":true}')),
      );
      final bId = await db.tripDao.addCrewMember(
        CrewMembersCompanion.insert(tripId: tripId, name: 'Ben', categoryParticipation: const Value('{"all":true}')),
      );

      final members = [
        KittyMember(id: aId, name: 'Anna', categoryParticipation: {}),
        KittyMember(id: bId, name: 'Ben', categoryParticipation: {}),
      ];

      // 1. Ausgabe als Kasse anlegen
      final expId = await kittyService.addExpense(
        ExpenseInput(
          tripId: tripId,
          title: 'Initial Kasse',
          amountInCents: 5000,
          category: ExpenseCategory.provisions,
          isPaidFromKitty: true,
        ),
      );

      var dbExp = await db.expenseDao.getExpensesForTrip(tripId);
      expect(dbExp.first.isPaidFromKitty, isTrue);
      expect(dbExp.first.paidByCrewMemberId, isNull);

      final initialKittyExp = KittyExpense(
        id: expId,
        tripId: tripId,
        title: 'Initial Kasse',
        amountInCents: 5000,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
        createdAt: DateTime.now(),
      );

      // Helper zum Öffnen des ExpenseSheets über showModalBottomSheet
      Future<void> openSheet(KittyExpense? exp) async {
        await tester.pumpWidget(
          buildTestableWidget(
            Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: ctx,
                      isScrollControlled: true,
                      builder: (_) => ExpenseSheet(
                        tripId: tripId,
                        kittyModel: KittyModel.sharedKitty,
                        members: members,
                        expenseToEdit: exp,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
      }

      // 2. Im Edit-Sheet öffnen und auf Person wechseln
      await openSheet(initialKittyExp);

      await tester.tap(find.text('Person'));
      await tester.pumpAndSettle();

      final saveBtn1 = find.text('Ausgabe speichern');
      await tester.ensureVisible(saveBtn1);
      await tester.tap(saveBtn1);
      await tester.pumpAndSettle();

      dbExp = await db.expenseDao.getExpensesForTrip(tripId);
      expect(dbExp.first.isPaidFromKitty, isFalse);
      expect(dbExp.first.paidByCrewMemberId, equals(aId));

      // 3. Zurück auf Kasse wechseln
      final editedExp = KittyExpense(
        id: expId,
        tripId: tripId,
        title: 'Initial Kasse',
        amountInCents: 5000,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: false,
        paidByMemberId: aId,
        createdAt: DateTime.now(),
      );

      await openSheet(editedExp);

      await tester.tap(find.text('Kasse'));
      await tester.pumpAndSettle();

      final saveBtn2 = find.text('Ausgabe speichern');
      await tester.ensureVisible(saveBtn2);
      await tester.tap(saveBtn2);
      await tester.pumpAndSettle();

      dbExp = await db.expenseDao.getExpensesForTrip(tripId);
      expect(dbExp.first.isPaidFromKitty, isTrue);
      expect(dbExp.first.paidByCrewMemberId, isNull);
    });
  });

  group('FIX-B Kriterium 20 & 21: SettlementScreen & EPC-QR mit Unified Balances', () {
    testWidgets('SettlementScreen zeigt kanonische Salden und EPC-QR öffnet Empfängerdaten', (tester) async {
      final aId = await db.tripDao.addCrewMember(
        CrewMembersCompanion.insert(
          tripId: tripId,
          name: 'Alex (Kassenwart)',
          isChild: const Value(false),
          isSkipperFree: const Value(false),
          categoryParticipation: const Value('{"all":true}'),
          iban: const Value('DE89370400440532013000'),
        ),
      );
      final bId = await db.tripDao.addCrewMember(
        CrewMembersCompanion.insert(
          tripId: tripId,
          name: 'Berta',
          isChild: const Value(false),
          isSkipperFree: const Value(false),
          categoryParticipation: const Value('{"all":true}'),
          iban: const Value('DE12500105170648489890'),
        ),
      );
      final cId = await db.tripDao.addCrewMember(
        CrewMembersCompanion.insert(
          tripId: tripId,
          name: 'Chris',
          isChild: const Value(false),
          isSkipperFree: const Value(false),
          categoryParticipation: const Value('{"all":true}'),
          iban: const Value('DE45500105170648489891'),
        ),
      );
      final dId = await db.tripDao.addCrewMember(
        CrewMembersCompanion.insert(
          tripId: tripId,
          name: 'Daniel',
          isChild: const Value(false),
          isSkipperFree: const Value(false),
          categoryParticipation: const Value('{"all":true}'),
          iban: const Value('DE78500105170648489892'),
        ),
      );
      await db.tripDao.setTripTreasurer(tripId, aId);

      // 400 € Einzahlungen (je 100 €)
      await kittyService.addDeposit(tripId: tripId, memberId: aId, amountInCents: 10000);
      await kittyService.addDeposit(tripId: tripId, memberId: bId, amountInCents: 10000);
      await kittyService.addDeposit(tripId: tripId, memberId: cId, amountInCents: 10000);
      await kittyService.addDeposit(tripId: tripId, memberId: dId, amountInCents: 10000);

      // E1: 200 € aus Kasse
      await kittyService.addExpense(
        ExpenseInput(
          tripId: tripId,
          title: 'Hafen',
          amountInCents: 20000,
          category: ExpenseCategory.marinaBerth,
          isPaidFromKitty: true,
        ),
      );
      // E2: 120 € persönlich von B
      await kittyService.addExpense(
        ExpenseInput(
          tripId: tripId,
          title: 'Restaurant Berta',
          amountInCents: 12000,
          category: ExpenseCategory.restaurant,
          isPaidFromKitty: false,
          paidByMemberId: bId,
        ),
      );

      await tester.pumpWidget(buildTestableWidget(SettlementScreen(tripId: tripId)));
      await tester.pumpAndSettle();

      // Erwartete Transfers: Alex zahlt an Berta (140 €), an Chris (20 €), an Daniel (20 €)
      expect(find.textContaining('Alex (Kassenwart)'), findsWidgets);
      expect(find.text('Berta'), findsWidgets);
      expect(find.text('140,00 €'), findsWidgets);
      expect(find.textContaining('20,00 €'), findsWidgets);

      // Klick auf ersten "Bezahlen"-Button (Alex an Berta)
      expect(find.text('Bezahlen'), findsWidgets);
      await tester.tap(find.text('Bezahlen').first);
      await tester.pumpAndSettle();

      // EPC QR-Code mit Bertas Daten
      expect(find.byType(EpcQrWidget), findsOneWidget);
      final qr = tester.widget<EpcQrWidget>(find.byType(EpcQrWidget));
      expect(qr.payload.beneficiaryName, equals('Berta'));
      expect(qr.payload.iban, equals('DE12500105170648489890'));
      expect(qr.payload.amountInCents, equals(14000));
    });
  });

  group('FIX-B Kriterium 22: Deterministische Matrix & Seeded Invarianz-Tests', () {
    test('100 pseudo-zufällige Testfälle erfüllen strikt Summe(Salden) == 0 und exakten Schuldenausgleich', () {
      final rand = Random(42); // Fester Seed für Reproduzierbarkeit

      for (int iteration = 0; iteration < 100; iteration++) {
        final memberCount = 2 + rand.nextInt(7); // 2 bis 8 Personen
        final members = List.generate(memberCount, (i) {
          final isFree = (i == 0 && rand.nextBool());
          return KittyMember(
            id: i + 1,
            name: 'Member_${i + 1}',
            isSkipperFree: isFree,
            skipperFreeScope: isFree ? (rand.nextBool() ? 'all' : 'exclude_food') : null,
            categoryParticipation: {
              for (final cat in ExpenseCategory.values)
                cat: rand.nextInt(5) != 0, // 80% Beteiligung
            },
          );
        });

        final treasurer = members[rand.nextInt(memberCount)];

        // Zufällige Einzahlungen
        final depositCount = rand.nextInt(memberCount * 2);
        final deposits = <KittyDeposit>[];
        for (int d = 0; d < depositCount; d++) {
          final m = members[rand.nextInt(memberCount)];
          final amt = (rand.nextInt(300) + 1) * 100 + rand.nextInt(100); // 1,00 bis 300,99 €
          deposits.add(KittyDeposit(
            id: d + 1,
            tripId: 1,
            memberId: m.id,
            amountInCents: amt,
            paidAt: DateTime(2026, 8, 1),
          ));
        }

        // Zufällige Ausgaben (sowohl Kasse als auch Person)
        final expenseCount = rand.nextInt(10) + 1; // 1 bis 10 Ausgaben
        final expenses = <KittyExpense>[];
        for (int e = 0; e < expenseCount; e++) {
          final isKitty = rand.nextBool();
          final payer = isKitty ? null : members[rand.nextInt(memberCount)];
          final amt = (rand.nextInt(200) + 1) * 100 + rand.nextInt(100);
          final cat = ExpenseCategory.values[rand.nextInt(ExpenseCategory.values.length)];

          expenses.add(KittyExpense(
            id: e + 1,
            tripId: 1,
            title: 'Exp_$e',
            amountInCents: amt,
            category: cat,
            isPaidFromKitty: isKitty,
            paidByMemberId: payer?.id,
            createdAt: DateTime(2026, 8, 2),
          ));
        }

        // 1. Unified Ledger berechnen
        final ledger = engine.calculateUnifiedLedger(
          members: members,
          deposits: deposits,
          expenses: expenses,
          treasurerMemberId: treasurer.id,
        );

        // INVARIANZ 1: Summe der Expense-Splits == Summe aller Ausgaben
        final totalExpenseCents = expenses.fold<int>(0, (s, e) => s + e.amountInCents);
        expect(ledger.totalExpensesInCents, equals(totalExpenseCents));

        final totalCostShares = ledger.memberBalances.fold<int>(0, (s, b) => s + b.costShareInCents);
        expect(totalCostShares, equals(totalExpenseCents),
            reason: 'Iteration $iteration: Summe aller Kostenanteile muss totalExpenses entsprechen');

        // INVARIANZ 2: Summe der Netto-Salden ist mathematisch exakt 0
        final sumNetBalances = ledger.memberBalances.fold<int>(0, (s, b) => s + b.netBalanceInCents);
        expect(sumNetBalances, equals(0),
            reason: 'Iteration $iteration: Summe der Netto-Salden muss exakt 0 Cent sein');

        // INVARIANZ 3: Shared Kitty Berechnung
        final shared = engine.calculateSharedKitty(
          members: members,
          deposits: deposits,
          expenses: expenses,
          treasurerMemberId: treasurer.id,
        );

        expect(shared.memberBalances.fold<int>(0, (s, b) => s + b.netBalanceInCents), equals(0));

        // Alle Transfers laufen über den Kassenwart
        for (final t in shared.settlementTransfers) {
          final touchesTreasurer = t.fromMember.id == treasurer.id || t.toMember.id == treasurer.id;
          expect(touchesTreasurer, isTrue);
        }

        // INVARIANZ 4: Individual Settlement Berechnung
        final ind = engine.calculateIndividualSettlement(
          members: members,
          expenses: expenses,
          deposits: deposits,
          treasurerMemberId: treasurer.id,
        );

        // Netto-Salden sind zwischen Shared und Individual 100% identisch
        for (int i = 0; i < members.length; i++) {
          expect(
            ind.memberBalances[i].netBalanceInCents,
            equals(shared.memberBalances[i].netBalanceInCents),
            reason: 'Iteration $iteration: Model-Switch-Invarianz für Member ${members[i].name}',
          );
        }

        // Debt Simplification gleicht alle Gläubiger vollständig aus
        final totalCreditors = ind.memberBalances
            .where((b) => b.netBalanceInCents > 0)
            .fold<int>(0, (s, b) => s + b.netBalanceInCents);
        final totalDebtors = ind.memberBalances
            .where((b) => b.netBalanceInCents < 0)
            .fold<int>(0, (s, b) => s - b.netBalanceInCents);
        expect(totalCreditors, equals(totalDebtors));

        final totalTransferred = ind.simplifiedTransfers.fold<int>(0, (s, t) => s + t.amountInCents);
        expect(totalTransferred, equals(totalCreditors));
      }
    });
  });
}
