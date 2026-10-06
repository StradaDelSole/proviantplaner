/// Tests für FIX-B Review Amendment (Findings A–H, S1–S5).
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/services/backup_coordinator.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';
import 'package:proviantplaner/core/services/hullq_backup_service.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/kitty/data/kitty_service.dart';
import 'package:proviantplaner/features/kitty/data/kitty_providers.dart';
import 'package:proviantplaner/features/kitty/domain/calculation/kitty_engine.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/kitty/ui/kitty_screen.dart';
import 'package:proviantplaner/features/kitty/ui/settlement_screen.dart';

void main() {
  late AppDatabase db;
  late TripService tripService;
  late KittyService kittyService;
  late CatalogRepository catalogRepo;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    catalogRepo = CatalogRepository();
    await catalogRepo.loadFromBundle();
    tripService = TripService(
      tripDao: db.tripDao,
      listItemDao: db.listItemDao,
      catalogRepository: catalogRepo,
      expenseDao: db.expenseDao,
    );
    kittyService = KittyService(
      tripDao: db.tripDao,
      expenseDao: db.expenseDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createStandardTrip({String currency = 'EUR', KittyModel kittyModel = KittyModel.sharedKitty}) async {
    final tripId = await db.tripDao.createTrip(
      TripsCompanion.insert(
        name: 'Test Törn',
        startDate: DateTime(2026, 8, 1),
        daysCount: const Value(7),
        currency: Value(currency),
        kittyModel: Value(kittyModel),
      ),
    );
    await db.tripDao.addCrewMember(CrewMembersCompanion.insert(tripId: tripId, name: 'Alice'));
    await db.tripDao.addCrewMember(CrewMembersCompanion.insert(tripId: tripId, name: 'Bob'));
    return tripId;
  }

  group('S1 & Finding A: Crew Deletion Financial Guard', () {
    test('Löschen eines unreferenzierten Crew-Mitglieds ist erlaubt', () async {
      final tripId = await createStandardTrip();
      final memberId = await db.tripDao.addCrewMember(
        CrewMembersCompanion.insert(tripId: tripId, name: 'Charlie'),
      );

      final hasHistory = await tripService.hasFinancialHistory(memberId);
      expect(hasHistory, isFalse);

      await tripService.deleteCrewMemberSafely(memberId);
      final crew = await db.tripDao.getCrewForTrip(tripId);
      expect(crew.any((m) => m.id == memberId), isFalse);
    });

    test('Löschen eines Mitglieds mit getätigter Ausgabe wird abgewiesen', () async {
      final tripId = await createStandardTrip();
      final crew = await db.tripDao.getCrewForTrip(tripId);
      final payer = crew.first;

      await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'Brot',
        amountInCents: 500,
        category: ExpenseCategory.provisions,
        paidByMemberId: payer.id,
        isPaidFromKitty: false,
      ));

      final hasHistory = await tripService.hasFinancialHistory(payer.id);
      expect(hasHistory, isTrue);

      expect(
        () => tripService.deleteCrewMemberSafely(payer.id),
        throwsA(isA<CrewMemberHasFinancialHistoryException>()),
      );
    });

    test('Löschen eines Mitglieds mit Einzahlung wird abgewiesen', () async {
      final tripId = await createStandardTrip();
      final crew = await db.tripDao.getCrewForTrip(tripId);
      final depositor = crew.first;

      await kittyService.addDeposit(
        tripId: tripId,
        memberId: depositor.id,
        amountInCents: 5000,
      );

      final hasHistory = await tripService.hasFinancialHistory(depositor.id);
      expect(hasHistory, isTrue);

      expect(
        () => tripService.deleteCrewMemberSafely(depositor.id),
        throwsA(isA<CrewMemberHasFinancialHistoryException>()),
      );
    });

    test('Löschen eines Mitglieds in Custom Split wird abgewiesen', () async {
      final tripId = await createStandardTrip();
      final crew = await db.tripDao.getCrewForTrip(tripId);
      final m1 = crew[0];
      final m2 = crew[1];

      await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'Restaurant',
        amountInCents: 5000,
        category: ExpenseCategory.restaurant,
        paidByMemberId: m1.id,
        isPaidFromKitty: false,
        customSplitInCents: {m1.id: 2500, m2.id: 2500},
      ));

      final hasHistory = await tripService.hasFinancialHistory(m2.id);
      expect(hasHistory, isTrue);

      expect(
        () => tripService.deleteCrewMemberSafely(m2.id),
        throwsA(isA<CrewMemberHasFinancialHistoryException>()),
      );
    });

    test('Löschen des aktiven Kassenwarts wird abgewiesen', () async {
      final tripId = await createStandardTrip();
      final crew = await db.tripDao.getCrewForTrip(tripId);
      final treasurer = crew.first;

      await db.tripDao.setTripTreasurer(tripId, treasurer.id);

      final hasHistory = await tripService.hasFinancialHistory(treasurer.id);
      expect(hasHistory, isTrue);

      expect(
        () => tripService.deleteCrewMemberSafely(treasurer.id),
        throwsA(isA<CrewMemberHasFinancialHistoryException>()),
      );
    });

    test('Löschen des letzten verbleibenden Crew-Mitglieds wirft StateError', () async {
      final tripId = await db.tripDao.createTrip(
        TripsCompanion.insert(
          name: 'Solo Törn',
          startDate: DateTime(2026, 8, 1),
          daysCount: const Value(7),
        ),
      );
      final soloId = await db.tripDao.addCrewMember(CrewMembersCompanion.insert(tripId: tripId, name: 'Solo'));

      expect(
        () => tripService.deleteCrewMemberSafely(soloId),
        throwsStateError,
      );
    });

    test('Engine wirft LedgerValidationException bei person-paid mit fehlendem Payer', () {
      const engine = KittyEngine();
      const m1 = KittyMember(id: 1, name: 'Alice', categoryParticipation: {});
      final exp = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Brot',
        amountInCents: 500,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: false,
        paidByMemberId: null, // Fehlend
        createdAt: DateTime(2026, 8, 1),
      );

      expect(
        () => engine.calculateUnifiedLedger(
          members: [m1],
          deposits: const [],
          expenses: [exp],
        ),
        throwsA(predicate((e) =>
            e is LedgerValidationException &&
            e.reason == LedgerValidationReason.missingPayer)),
      );
    });

    test('Engine wirft LedgerValidationException bei unbekanntem Einzahler', () {
      const engine = KittyEngine();
      const m1 = KittyMember(id: 1, name: 'Alice', categoryParticipation: {});
      final dep = KittyDeposit(
        id: 1,
        tripId: 1,
        memberId: 999, // Nicht in members
        amountInCents: 5000,
        paidAt: DateTime(2026, 8, 1),
      );

      expect(
        () => engine.calculateUnifiedLedger(
          members: [m1],
          deposits: [dep],
          expenses: const [],
        ),
        throwsA(predicate((e) =>
            e is LedgerValidationException &&
            e.reason == LedgerValidationReason.unknownDepositMember)),
      );
    });
  });

  group('S2 & Finding B: Custom Split Validierung', () {
    const engine = KittyEngine();
    const m1 = KittyMember(id: 1, name: 'Alice', categoryParticipation: {});
    const m2 = KittyMember(id: 2, name: 'Bob', categoryParticipation: {});

    test('Custom Split mit verwaister Crew-ID wirft unknownCustomSplitMember', () {
      final exp = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Einkauf',
        amountInCents: 5000,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
        customSplitInCents: const {1: 2500, 999: 2500},
        createdAt: DateTime(2026, 8, 1),
      );

      expect(
        () => engine.calculateUnifiedLedger(
          members: [m1, m2],
          deposits: const [],
          expenses: [exp],
        ),
        throwsA(predicate((e) =>
            e is LedgerValidationException &&
            e.reason == LedgerValidationReason.unknownCustomSplitMember)),
      );
    });

    test('Custom Split mit Summen-Abweichung zu gering wirft customSplitTotalMismatch', () {
      final exp = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Einkauf',
        amountInCents: 5000,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
        customSplitInCents: const {1: 2500, 2: 2499}, // Summe 4999 != 5000
        createdAt: DateTime(2026, 8, 1),
      );

      expect(
        () => engine.calculateUnifiedLedger(
          members: [m1, m2],
          deposits: const [],
          expenses: [exp],
        ),
        throwsA(predicate((e) =>
            e is LedgerValidationException &&
            e.reason == LedgerValidationReason.customSplitTotalMismatch)),
      );
    });

    test('Custom Split mit Summen-Abweichung zu hoch wirft customSplitTotalMismatch', () {
      final exp = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Einkauf',
        amountInCents: 5000,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
        customSplitInCents: const {1: 2500, 2: 2501}, // Summe 5001 != 5000
        createdAt: DateTime(2026, 8, 1),
      );

      expect(
        () => engine.calculateUnifiedLedger(
          members: [m1, m2],
          deposits: const [],
          expenses: [exp],
        ),
        throwsA(predicate((e) =>
            e is LedgerValidationException &&
            e.reason == LedgerValidationReason.customSplitTotalMismatch)),
      );
    });

    test('Custom Split mit negativem Anteil wirft negativeCustomSplitShare', () {
      final exp = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Einkauf',
        amountInCents: 5000,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
        customSplitInCents: const {1: 6000, 2: -1000},
        createdAt: DateTime(2026, 8, 1),
      );

      expect(
        () => engine.calculateUnifiedLedger(
          members: [m1, m2],
          deposits: const [],
          expenses: [exp],
        ),
        throwsA(predicate((e) =>
            e is LedgerValidationException &&
            e.reason == LedgerValidationReason.negativeCustomSplitShare)),
      );
    });

    test('Valider ungerader Custom Split (Odd Cents) summiert exakt', () {
      final exp = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Einkauf',
        amountInCents: 10001,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
        customSplitInCents: const {1: 5000, 2: 5001},
        createdAt: DateTime(2026, 8, 1),
      );

      final res = engine.calculateUnifiedLedger(
        members: [m1, m2],
        deposits: const [],
        expenses: [exp],
      );

      expect(res.totalExpensesInCents, equals(10001));
      expect(res.memberBalances[0].costShareInCents, equals(5000));
      expect(res.memberBalances[1].costShareInCents, equals(5001));
    });

    test('KittyService weist Anlage von Custom Split mit fehlerhafter Summe ab', () async {
      final tripId = await createStandardTrip();
      final crew = await db.tripDao.getCrewForTrip(tripId);

      expect(
        () => kittyService.addExpense(ExpenseInput(
          tripId: tripId,
          title: 'Ungültiger Split',
          amountInCents: 5000,
          category: ExpenseCategory.provisions,
          isPaidFromKitty: true,
          customSplitInCents: {crew[0].id: 2000, crew[1].id: 2000},
        )),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('S2 & Finding C: Backup Custom Split Remapping', () {
    test('v2 Backup mappt Custom Split Member-IDs transaktionssicher auf neue IDs um', () async {
      final tripId = await createStandardTrip();
      final crew = await db.tripDao.getCrewForTrip(tripId);
      final m1 = crew[0];
      final m2 = crew[1];

      await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'Abendessen mit Custom Split',
        amountInCents: 10000,
        category: ExpenseCategory.restaurant,
        paidByMemberId: m1.id,
        isPaidFromKitty: false,
        customSplitInCents: {m1.id: 6000, m2.id: 4000},
      ));

      final preBackupData = await kittyService.loadKittyData(tripId);
      final preBalances = preBackupData.balances;

      final mockBackup = MockHullqBackupService();
      final mockAuth = MockHullqAuthService();
      await mockAuth.loginWithEmail('sailor@hullq.com', newsletterOptIn: false);
      final coordinator = BackupCoordinator(
        db: db,
        backupService: mockBackup,
        authService: mockAuth,
      );

      await coordinator.createBackup();
      final backedUpJson = await mockBackup.restoreData();
      expect(backedUpJson, isNotNull);

      // Aus Backup wiederherstellen
      await coordinator.restoreBackup();

      final allTrips = await db.tripDao.getAllTrips();
      final restoredTripId = allTrips.first.id;
      final restoredCrew = await db.tripDao.getCrewForTrip(restoredTripId);
      final restoredM1 = restoredCrew.firstWhere((m) => m.name == m1.name);
      final restoredM2 = restoredCrew.firstWhere((m) => m.name == m2.name);

      final restoredExpenses = await db.expenseDao.getExpensesForTrip(restoredTripId);
      final restoredExp = restoredExpenses.single;
      expect(restoredExp.customSplit, isNotNull);

      final splitMap = jsonDecode(restoredExp.customSplit!) as Map<String, dynamic>;
      expect(splitMap.containsKey(restoredM1.id.toString()), isTrue);
      expect(splitMap.containsKey(restoredM2.id.toString()), isTrue);
      expect(splitMap[restoredM1.id.toString()], equals(6000));
      expect(splitMap[restoredM2.id.toString()], equals(4000));

      final postBackupData = await kittyService.loadKittyData(restoredTripId);
      final postBalances = postBackupData.balances;
      expect(postBalances[0].costShareInCents, equals(preBalances[0].costShareInCents));
      expect(postBalances[1].costShareInCents, equals(preBalances[1].costShareInCents));
      expect(postBalances[0].netBalanceInCents, equals(preBalances[0].netBalanceInCents));
      expect(postBalances[1].netBalanceInCents, equals(preBalances[1].netBalanceInCents));
    });

    test('v2 Backup scheitert explizit, wenn Custom Split ein nicht-vorhandenes Mitglied referenziert', () async {
      final mockBackup = MockHullqBackupService();
      final mockAuth = MockHullqAuthService();
      await mockAuth.loginWithEmail('sailor@hullq.com', newsletterOptIn: false);
      final coordinator = BackupCoordinator(
        db: db,
        backupService: mockBackup,
        authService: mockAuth,
      );

      final invalidPayload = jsonEncode({
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'profiles': [],
        'trips': [
          {
            'trip': {
              'id': 1,
              'name': 'Korrupter Törn',
              'startDate': '2026-08-01T00:00:00.000',
              'daysCount': 7,
              'region': 'warm',
              'climate': 'warm',
              'isCharter': true,
              'boatType': 'mono',
              'fridgeCapacity': 100,
              'currency': 'EUR',
            },
            'stops': [],
            'days': [],
            'crew': [
              {'id': 1, 'name': 'Alice'},
            ],
            'items': [],
            'allocations': [],
            'expenses': [
              {
                'id': 1,
                'amount': 50.0,
                'currency': 'EUR',
                'category': 'provisions',
                'paidByCrewMemberId': 1,
                'isPaidFromKitty': false,
                'customSplit': '{"1": 2500, "999": 2500}', // 999 existiert nicht
              }
            ],
            'payments': [],
          }
        ],
      });

      await mockBackup.backupData(invalidPayload);
      expect(() => coordinator.restoreBackup(), throwsA(isA<StateError>()));
    });
  });

  group('S3 & Finding G: Deterministic Treasurer Resolution', () {
    const engine = KittyEngine();
    const m1 = KittyMember(id: 1, name: 'Skipper Free', isSkipperFree: true, categoryParticipation: {});
    const m2 = KittyMember(id: 2, name: 'Normal Crew', categoryParticipation: {});
    final expenses = <KittyExpense>[
      KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Proviant',
        amountInCents: 10000,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
        createdAt: DateTime(2026, 8, 1),
      ),
    ];
    final deposits = <KittyDeposit>[
      KittyDeposit(id: 1, tripId: 1, memberId: 1, amountInCents: 5000, paidAt: DateTime(2026, 8, 1)),
      KittyDeposit(id: 2, tripId: 1, memberId: 2, amountInCents: 5000, paidAt: DateTime(2026, 8, 1)),
    ];

    test('Expliziter valider Kassenwart wird in beiden Modi identisch aufgelöst', () {
      final shared = engine.calculateSharedKitty(
        members: [m1, m2],
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: 2,
      );
      final individual = engine.calculateIndividualSettlement(
        members: [m1, m2],
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: 2,
      );

      expect(shared.treasurer?.id, equals(2));
      expect(individual.treasurer?.id, equals(2));
      expect(shared.treasurer?.id, equals(individual.treasurer?.id));
    });

    test('Fehlender Kassenwart greift deterministisch auf denselben Fallback (Skipper) zurück', () {
      final shared = engine.calculateSharedKitty(
        members: [m1, m2],
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: null,
      );
      final individual = engine.calculateIndividualSettlement(
        members: [m1, m2],
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: null,
      );

      expect(shared.treasurer?.id, equals(1));
      expect(individual.treasurer?.id, equals(1));
      expect(shared.treasurer?.id, equals(individual.treasurer?.id));
    });

    test('Verwaister (dangling) Kassenwart greift deterministisch auf denselben Fallback zurück', () {
      final shared = engine.calculateSharedKitty(
        members: [m1, m2],
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: 999,
      );
      final individual = engine.calculateIndividualSettlement(
        members: [m1, m2],
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: 999,
      );

      expect(shared.treasurer?.id, equals(1));
      expect(individual.treasurer?.id, equals(1));
      expect(shared.treasurer?.id, equals(individual.treasurer?.id));
    });

    test('Modellwechsel Shared -> Individual -> Shared bewahrt Netto-Salden cent-exakt', () {
      final shared1 = engine.calculateSharedKitty(
        members: [m1, m2],
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: 2,
      );
      final ind = engine.calculateIndividualSettlement(
        members: [m1, m2],
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: 2,
      );
      final shared2 = engine.calculateSharedKitty(
        members: [m1, m2],
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: 2,
      );

      for (int i = 0; i < shared1.memberBalances.length; i++) {
        expect(shared1.memberBalances[i].netBalanceInCents, equals(ind.memberBalances[i].netBalanceInCents));
        expect(shared1.memberBalances[i].netBalanceInCents, equals(shared2.memberBalances[i].netBalanceInCents));
      }
    });
  });

  group('S4 & Finding D: Währungsintegrität (Single Currency Guardrail)', () {
    const engine = KittyEngine();
    const m1 = KittyMember(id: 1, name: 'Alice', categoryParticipation: {});
    const m2 = KittyMember(id: 2, name: 'Bob', categoryParticipation: {});

    test('Reiner EUR-Törn rechnet normal', () {
      final exp = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Brot',
        amountInCents: 1000,
        currency: 'EUR',
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
        createdAt: DateTime(2026, 8, 1),
      );

      final res = engine.calculateUnifiedLedger(
        members: [m1, m2],
        deposits: const [],
        expenses: [exp],
        currency: 'EUR',
      );
      expect(res.totalExpensesInCents, equals(1000));
    });

    test('Einzelner Nicht-EUR Törn (z.B. USD) rechnet in seiner eigenen Währung', () {
      final exp = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Brot',
        amountInCents: 1500,
        currency: 'USD',
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
        createdAt: DateTime(2026, 8, 1),
      );

      final res = engine.calculateUnifiedLedger(
        members: [m1, m2],
        deposits: const [],
        expenses: [exp],
        currency: 'USD',
      );
      expect(res.totalExpensesInCents, equals(1500));
    });

    test('Gemischte Währungen werfen typed LedgerValidationException (currencyMismatch)', () {
      final exp1 = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Brot',
        amountInCents: 1000,
        currency: 'EUR',
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
        createdAt: DateTime(2026, 8, 1),
      );
      final exp2 = KittyExpense(
        id: 2,
        tripId: 1,
        title: 'Käse',
        amountInCents: 1000,
        currency: 'USD',
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
        createdAt: DateTime(2026, 8, 1),
      );

      expect(
        () => engine.calculateUnifiedLedger(
          members: [m1, m2],
          deposits: const [],
          expenses: [exp1, exp2],
          currency: 'EUR',
        ),
        throwsA(predicate((e) =>
            e is LedgerValidationException &&
            e.reason == LedgerValidationReason.currencyMismatch)),
      );
    });

    test('KittyService addExpense übernimmt Törn-Währung', () async {
      final tripId = await createStandardTrip(currency: 'HRK');
      final expId = await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'Einkauf Split',
        amountInCents: 2000,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
      ));

      final expenses = await db.expenseDao.getExpensesForTrip(tripId);
      final exp = expenses.firstWhere((e) => e.id == expId);
      expect(exp.currency, equals('HRK'));
    });

    test('KittyService updateExpense bewahrt bestehende Währung', () async {
      final tripId = await createStandardTrip(currency: 'USD');
      final expId = await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'USD Brot',
        amountInCents: 2000,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
      ));

      await kittyService.updateExpense(
        id: expId,
        input: ExpenseInput(
          tripId: tripId,
          title: 'USD Brot & Butter',
          amountInCents: 2500,
          category: ExpenseCategory.provisions,
          isPaidFromKitty: true,
        ),
      );

      final expenses = await db.expenseDao.getExpensesForTrip(tripId);
      final exp = expenses.firstWhere((e) => e.id == expId);
      expect(exp.currency, equals('USD'));
      expect((exp.amount * 100).round(), equals(2500));
    });

    test('KittyService restoreExpense bewahrt Währung bei Undo', () async {
      final tripId = await createStandardTrip(currency: 'USD');
      final expId = await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'USD Wein',
        amountInCents: 3000,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
      ));

      final data = await kittyService.loadKittyData(tripId);
      final expToDelete = data.expenses.firstWhere((e) => e.id == expId);
      await kittyService.deleteExpense(expId);

      await kittyService.restoreExpense(expToDelete);
      final expenses = await db.expenseDao.getExpensesForTrip(tripId);
      final restored = expenses.firstWhere((e) => e.id == expId);
      expect(restored.currency, equals('USD'));
    });
  });

  group('Finding F: UI-Fehlerdarstellung bei ungültigem Ledger', () {
    testWidgets('KittyScreen zeigt dedizierte Fehleransicht bei LedgerValidationException', (tester) async {
      final container = ProviderContainer(
        overrides: [
          tripKittyDataProvider(1).overrideWith((ref) => throw const LedgerValidationException(
                reason: LedgerValidationReason.currencyMismatch,
                message: 'Währungsungleichheit',
              )),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: KittyScreen(tripId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Es darf NICHT tripNotFound angezeigt werden
      expect(find.text('Abrechnung prüfen'), findsNWidgets(2));
      expect(find.text('Die Abrechnung enthält ungültige oder widersprüchliche Einträge. Bitte prüfe Ausgaben und Einzahlungen.'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Törn nicht gefunden'), findsNothing);
    });

    testWidgets('SettlementScreen zeigt dedizierte Fehleransicht bei LedgerValidationException', (tester) async {
      final container = ProviderContainer(
        overrides: [
          tripKittyDataProvider(1).overrideWith((ref) => throw const LedgerValidationException(
                reason: LedgerValidationReason.missingPayer,
                message: 'Payer fehlt',
              )),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettlementScreen(tripId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Es darf NICHT tripNotFound angezeigt werden
      expect(find.text('Abrechnung prüfen'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Törn nicht gefunden'), findsNothing);
    });
  });
}
