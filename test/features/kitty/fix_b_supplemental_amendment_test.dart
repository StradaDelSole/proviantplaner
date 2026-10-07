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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/boat_profile_service.dart';
import 'package:proviantplaner/features/trip/ui/trip_overview_screen.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/delivery_order_service.dart';
import 'package:proviantplaner/features/kitty/domain/calculation/kitty_engine.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/kitty/ui/kitty_screen.dart';
import 'package:proviantplaner/features/kitty/ui/settlement_screen.dart';
import 'package:proviantplaner/features/kitty/ui/widgets/epc_qr_widget.dart';

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

  Future<int> createStandardTrip({
    String currency = 'EUR',
    KittyModel kittyModel = KittyModel.sharedKitty,
    bool setTreasurer = false,
  }) async {
    final tripId = await db.tripDao.createTrip(
      TripsCompanion.insert(
        name: 'Test Törn',
        startDate: DateTime(2026, 8, 1),
        daysCount: const Value(7),
        currency: Value(currency),
        kittyModel: Value(kittyModel),
      ),
    );
    final aId = await db.tripDao.addCrewMember(CrewMembersCompanion.insert(tripId: tripId, name: 'Alice'));
    await db.tripDao.addCrewMember(CrewMembersCompanion.insert(tripId: tripId, name: 'Bob'));
    if (setTreasurer) {
      await db.tripDao.setTripTreasurer(tripId, aId);
    }
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

  group('Finding I: Error-State-Differenzierung (LedgerValidation vs TripNotFound vs Generic Error)', () {
    testWidgets('KittyScreen: LedgerValidationException -> Abrechnung prüfen (nicht TripNotFound, nicht Technischer Fehler)', (tester) async {
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

      expect(find.text('Abrechnung prüfen'), findsNWidgets(2));
      expect(find.text('Die Abrechnung enthält ungültige oder widersprüchliche Einträge. Bitte prüfe Ausgaben und Einzahlungen.'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Törn nicht gefunden'), findsNothing);
      expect(find.text('Technischer Fehler'), findsNothing);
    });

    testWidgets('KittyScreen: TripNotFoundException -> NotFoundScreen (Törn nicht gefunden)', (tester) async {
      final container = ProviderContainer(
        overrides: [
          tripKittyDataProvider(1).overrideWith((ref) => throw const TripNotFoundException('Törn 1 nicht gefunden')),
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

      expect(find.text('Törn nicht gefunden'), findsOneWidget);
      expect(find.text('Abrechnung prüfen'), findsNothing);
      expect(find.text('Technischer Fehler'), findsNothing);
    });

    testWidgets('KittyScreen: generic StateError -> Technischer Fehler und ausdrücklich NICHT Törn nicht gefunden', (tester) async {
      final container = ProviderContainer(
        overrides: [
          tripKittyDataProvider(1).overrideWith((ref) => throw StateError('DB connection failure')),
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

      expect(find.text('Technischer Fehler'), findsNWidgets(2));
      expect(find.text('Ein unerwarteter technischer Fehler ist aufgetreten. Bitte versuche es erneut.'), findsOneWidget);
      expect(find.text('Erneut versuchen'), findsOneWidget);
      expect(find.text('Törn nicht gefunden'), findsNothing);
      expect(find.text('Abrechnung prüfen'), findsNothing);
    });

    testWidgets('SettlementScreen: LedgerValidationException -> Abrechnung prüfen (nicht TripNotFound, nicht Technischer Fehler)', (tester) async {
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

      expect(find.text('Abrechnung prüfen'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Törn nicht gefunden'), findsNothing);
      expect(find.text('Technischer Fehler'), findsNothing);
    });

    testWidgets('SettlementScreen: TripNotFoundException -> NotFoundScreen (Törn nicht gefunden)', (tester) async {
      final container = ProviderContainer(
        overrides: [
          tripKittyDataProvider(1).overrideWith((ref) => throw const TripNotFoundException('Törn 1 nicht gefunden')),
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

      expect(find.text('Törn nicht gefunden'), findsOneWidget);
      expect(find.text('Abrechnung prüfen'), findsNothing);
      expect(find.text('Technischer Fehler'), findsNothing);
    });

    testWidgets('SettlementScreen: generic Exception -> Technischer Fehler und ausdrücklich NICHT Törn nicht gefunden', (tester) async {
      final container = ProviderContainer(
        overrides: [
          tripKittyDataProvider(1).overrideWith((ref) => throw Exception('Fatal network/storage error')),
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

      expect(find.text('Technischer Fehler'), findsNWidgets(2));
      expect(find.text('Ein unerwarteter technischer Fehler ist aufgetreten. Bitte versuche es erneut.'), findsOneWidget);
      expect(find.text('Erneut versuchen'), findsOneWidget);
      expect(find.text('Törn nicht gefunden'), findsNothing);
      expect(find.text('Abrechnung prüfen'), findsNothing);
    });
  });

  group('Finding J: Single-Currency-UI & EPC EUR-Only Guard', () {
    testWidgets('USD Trip KittyScreen zeigt USD, nicht EUR (€) TABULAR und keine €-Zeichen', (tester) async {
      final tripId = await createStandardTrip(currency: 'USD');
      final crew = await db.tripDao.getCrewForTrip(tripId);
      await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'USD Dinner',
        amountInCents: 5000,
        category: ExpenseCategory.provisions,
        paidByMemberId: crew.first.id,
        isPaidFromKitty: false,
      ));

      final container = ProviderContainer(
        overrides: [
          kittyServiceProvider.overrideWithValue(kittyService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: KittyScreen(tripId: tripId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('USD TABULAR'), findsOneWidget);
      expect(find.text('EUR (€) TABULAR'), findsNothing);
      expect(find.textContaining('€'), findsNothing);
      expect(find.textContaining('50,00 USD'), findsWidgets);
    });

    testWidgets('USD Trip SettlementScreen: Transfer in USD, kein EPC QR, zeigt epcQrEurOnly Hinweis', (tester) async {
      final tripId = await createStandardTrip(currency: 'USD', kittyModel: KittyModel.individualSettlement);
      final crew = await db.tripDao.getCrewForTrip(tripId);
      final alice = crew[0];
      final bob = crew[1];

      // Alice und Bob bekommen gültige IBAN
      await db.tripDao.updateCrewMember(alice.copyWith(iban: const Value('DE89370400440532013000')));
      await db.tripDao.updateCrewMember(bob.copyWith(iban: const Value('DE89370400440532013000')));

      // Alice zahlt 30 USD für beide -> Bob schuldet Alice 15 USD
      await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'USD Lunch',
        amountInCents: 3000,
        category: ExpenseCategory.provisions,
        paidByMemberId: alice.id,
        isPaidFromKitty: false,
      ));

      final container = ProviderContainer(
        overrides: [
          kittyServiceProvider.overrideWithValue(kittyService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettlementScreen(tripId: tripId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Transfer Zeile enthält USD, kein €
      expect(find.textContaining('15,00 USD'), findsWidgets);
      expect(find.textContaining('€'), findsNothing);

      // Transfer-Karte antippen zum Aufklappen
      await tester.tap(find.text('Bezahlen').first);
      await tester.pumpAndSettle();

      // KEIN EPC QR Widget für USD Trip
      expect(find.byType(EpcQrWidget), findsNothing);

      // epcQrEurOnly Hinweis sichtbar
      expect(find.text('GiroCode (EPC-QR) ist nur für Zahlungen in Euro (EUR) verfügbar.'), findsOneWidget);

      // Sichere manuelle Zahlungsdetails mit USD vorhanden
      expect(find.text('15,00 USD'), findsWidgets);
      expect(find.text('Überweisungsdaten kopieren'), findsOneWidget);
    });

    testWidgets('EUR Trip SettlementScreen: rendert EPC QR mit exakter Cent-Summe in EUR', (tester) async {
      final tripId = await createStandardTrip(currency: 'EUR', kittyModel: KittyModel.individualSettlement);
      final crew = await db.tripDao.getCrewForTrip(tripId);
      final alice = crew[0];
      final bob = crew[1];

      // Alice und Bob bekommen gültige IBAN
      await db.tripDao.updateCrewMember(alice.copyWith(iban: const Value('DE89370400440532013000')));
      await db.tripDao.updateCrewMember(bob.copyWith(iban: const Value('DE89370400440532013000')));

      // Alice zahlt 30 EUR -> Bob schuldet Alice 15 EUR (1500 Cents)
      await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'EUR Lunch',
        amountInCents: 3000,
        category: ExpenseCategory.provisions,
        paidByMemberId: alice.id,
        isPaidFromKitty: false,
      ));

      final container = ProviderContainer(
        overrides: [
          kittyServiceProvider.overrideWithValue(kittyService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettlementScreen(tripId: tripId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Transfer-Karte antippen zum Aufklappen
      await tester.tap(find.text('Bezahlen').first);
      await tester.pumpAndSettle();

      // EpcQrWidget ist bei EUR Trip sichtbar
      expect(find.byType(EpcQrWidget), findsOneWidget);
      final qrWidget = tester.widget<EpcQrWidget>(find.byType(EpcQrWidget));
      expect(qrWidget.payload.amountInCents, equals(1500));
      expect(qrWidget.payload.iban, equals('DE89370400440532013000'));
      expect(find.text('GiroCode / EPC-QR-Code steht nur für Überweisungen in Euro (EUR) zur Verfügung.'), findsNothing);
    });
  });

  group('Proof Gap K: Real Crew Deletion UI Journey via TripOverviewScreen', () {
    testWidgets('Löschversuch eines Mitglieds mit getätigter Ausgabe in TripOverview zeigt SnackBar und Datenbank bleibt unverändert', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createStandardTrip();
      final crew = await db.tripDao.getCrewForTrip(tripId);
      final alice = crew.firstWhere((m) => m.name == 'Alice');

      // Alice zahlt eine persönliche Ausgabe
      final expId = await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'Hafengebühr',
        amountInCents: 4500,
        category: ExpenseCategory.marinaBerth,
        paidByMemberId: alice.id,
        isPaidFromKitty: false,
      ));

      final boatProfileService = BoatProfileService(boatProfileDao: db.boatProfileDao);
      final shoppingListService = ShoppingListService(
        listItemDao: db.listItemDao,
        tripDao: db.tripDao,
        catalogRepository: catalogRepo,
        tripService: tripService,
      );
      final deliveryOrderService = DeliveryOrderService();

      final router = GoRouter(
        initialLocation: '/trips/$tripId',
        routes: [
          GoRoute(
            path: '/trips/:id',
            builder: (_, state) => TripOverviewScreen(tripId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            tripServiceProvider.overrideWithValue(tripService),
            kittyServiceProvider.overrideWithValue(kittyService),
            boatProfileServiceProvider.overrideWithValue(boatProfileService),
            shoppingListServiceProvider.overrideWithValue(shoppingListService),
            deliveryOrderServiceProvider.overrideWithValue(deliveryOrderService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('de')],
            locale: const Locale('de'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Edit Dialog öffnen
      final editIcon = find.byTooltip('Törn bearbeiten');
      expect(editIcon, findsOneWidget);
      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // Scroll zum Crew-Bereich (Alice)
      final aliceFinder = find.text('Alice');
      await tester.scrollUntilVisible(aliceFinder, 100, scrollable: find.byType(Scrollable).last);
      expect(aliceFinder, findsOneWidget);

      // Delete-Icon für Alice in ihrem ListTile suchen
      final aliceTile = find.ancestor(
        of: aliceFinder,
        matching: find.byType(ListTile),
      );
      final deleteAliceBtn = find.descendant(
        of: aliceTile,
        matching: find.byIcon(Icons.delete_outline),
      );
      expect(deleteAliceBtn, findsOneWidget);
      await tester.tap(deleteAliceBtn);
      await tester.pumpAndSettle();

      // SnackBar mit lokalisiertem Text sichtbar
      expect(
        find.text('Dieses Crew-Mitglied kann nicht gelöscht werden, da es in der Abrechnung oder Kassenführung erfasst ist.'),
        findsOneWidget,
      );

      // DB-Unveränderlichkeit prüfen
      final currentCrew = await db.tripDao.getCrewForTrip(tripId);
      expect(currentCrew.length, equals(2));
      expect(currentCrew.any((m) => m.id == alice.id), isTrue);

      final currentExpenses = await db.expenseDao.getExpensesForTrip(tripId);
      expect(currentExpenses.length, equals(1));
      expect(currentExpenses.first.id, equals(expId));
      expect(currentExpenses.first.paidByCrewMemberId, equals(alice.id));
    });
  });

  group('Proof Gap L: Update Custom-Split Service Boundary Validation', () {
    test('KittyService.updateExpense weist Custom-Split mit fremdem Mitglied oder Summen-Mismatch ab und behält DB-Stand bei', () async {
      final tripId = await createStandardTrip();
      final crew = await db.tripDao.getCrewForTrip(tripId);
      final alice = crew[0];
      final bob = crew[1];

      // Valide Ausgabe anlegen mit gleichmäßigem Custom Split (1000 Cents total = 500 Cents Alice + 500 Cents Bob)
      final expId = await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'Original Ausgabe',
        amountInCents: 1000,
        category: ExpenseCategory.provisions,
        paidByMemberId: alice.id,
        isPaidFromKitty: false,
        customSplitInCents: {alice.id: 500, bob.id: 500},
      ));

      final initialExpenses = await db.expenseDao.getExpensesForTrip(tripId);
      final initialExp = initialExpenses.firstWhere((e) => e.id == expId);
      expect(initialExp.note, equals('Original Ausgabe'));

      // 1. Update-Versuch: Fremde Mitglieds-ID im Split (z. B. 999999)
      expect(
        () => kittyService.updateExpense(
          id: expId,
          input: ExpenseInput(
            tripId: tripId,
            title: 'Manipulierte Ausgabe',
            amountInCents: 1000,
            category: ExpenseCategory.provisions,
            paidByMemberId: alice.id,
            isPaidFromKitty: false,
            customSplitInCents: {alice.id: 500, 999999: 500},
          ),
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('ungültiges/fremdes Mitglied'),
        )),
      );

      // 2. Update-Versuch: Summen-Mismatch (600 + 500 != 1000)
      expect(
        () => kittyService.updateExpense(
          id: expId,
          input: ExpenseInput(
            tripId: tripId,
            title: 'Mismatch Ausgabe',
            amountInCents: 1000,
            category: ExpenseCategory.provisions,
            paidByMemberId: alice.id,
            isPaidFromKitty: false,
            customSplitInCents: {alice.id: 600, bob.id: 500},
          ),
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('CustomSplit-Summe'),
        )),
      );

      // DB-Unveränderlichkeit prüfen: Ausgabe muss unverändert erhalten bleiben
      final afterExpenses = await db.expenseDao.getExpensesForTrip(tripId);
      final persisted = afterExpenses.firstWhere((e) => e.id == expId);
      expect(persisted.note, equals('Original Ausgabe'));
      expect((persisted.amount * 100).round(), equals(1000));
      final decodedSplit = jsonDecode(persisted.customSplit!) as Map<String, dynamic>;
      expect(decodedSplit[alice.id.toString()], equals(500));
      expect(decodedSplit[bob.id.toString()], equals(500));
    });
  });

  group('Proof Gap M: Backup & Restore Currency Preservation & Ledger Computation', () {
    test('Non-EUR (USD) Törn und Ausgaben behalten Währung nach Backup/Restore, Ledger rechnet fehlerfrei', () async {
      final tripId = await createStandardTrip(currency: 'USD', kittyModel: KittyModel.sharedKitty);
      final crew = await db.tripDao.getCrewForTrip(tripId);
      final alice = crew[0];
      final bob = crew[1];

      // USD Einzahlung in Kasse: Bob zahlt 20 USD (2000 Cents)
      await kittyService.addDeposit(
        tripId: tripId,
        memberId: bob.id,
        amountInCents: 2000,
      );

      // USD Gruppenausgabe aus Bordkasse: 15 USD (1500 Cents)
      await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'USD Proviant',
        amountInCents: 1500,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
      ));

      // USD persönliche Ausgabe: Alice zahlt 50 USD (5000 Cents) persönlich
      await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'USD Treibstoff',
        amountInCents: 5000,
        category: ExpenseCategory.fuel,
        paidByMemberId: alice.id,
        isPaidFromKitty: false,
      ));

      // Pre-Backup Prüfung: Ledger rechnet sauber in USD
      final preBackupData = await kittyService.loadKittyData(tripId);
      expect(preBackupData.trip.currency, equals('USD'));
      expect(preBackupData.sharedResult!.totalExpensesInCents, equals(6500));

      // Backup erstellen
      final mockBackup = MockHullqBackupService();
      final mockAuth = MockHullqAuthService();
      await mockAuth.loginWithEmail('sailor@hullq.com', newsletterOptIn: false);
      final coordinator = BackupCoordinator(
        db: db,
        backupService: mockBackup,
        authService: mockAuth,
      );
      await coordinator.createBackup();
      final backupJson = await mockBackup.restoreData();
      expect(backupJson, isNotNull);
      expect(backupJson!.contains('"currency":"USD"'), isTrue);

      // In eine frische Datenbank wiederherstellen
      final freshDb = AppDatabase(NativeDatabase.memory());
      addTearDown(freshDb.close);

      final freshCoordinator = BackupCoordinator(
        db: freshDb,
        backupService: mockBackup,
        authService: mockAuth,
      );
      await freshCoordinator.restoreBackup();

      // Restore prüfen
      final restoredTrips = await freshDb.tripDao.getAllTrips();
      expect(restoredTrips.length, equals(1));
      final restoredTrip = restoredTrips.first;
      expect(restoredTrip.currency, equals('USD'));

      final restoredExpenses = await freshDb.expenseDao.getExpensesForTrip(restoredTrip.id);
      expect(restoredExpenses.length, equals(2));
      for (final exp in restoredExpenses) {
        expect(exp.currency, equals('USD'));
      }

      // KittyService auf wiederhergestellter DB aufrufen
      final freshKittyService = KittyService(
        tripDao: freshDb.tripDao,
        expenseDao: freshDb.expenseDao,
      );
      final restoredData = await freshKittyService.loadKittyData(restoredTrip.id);

      // Ledger rechnet ohne currencyMismatch Exception
      expect(restoredData.trip.currency, equals('USD'));
      expect(restoredData.sharedResult!.totalExpensesInCents, equals(6500));
      expect(restoredData.sharedResult!.currentBalanceInCents, equals(500)); // 2000 eingezahlt - 1500 gezahlt = 500
      expect(restoredData.transfers, isNotEmpty);
    });
  });

  group('Findings N–P: Currency Entry Surfaces & PayPal Fallback Guard', () {
    group('PayPal URL Resolver Helper Unit Tests', () {
      test('EUR ohne expliziten Link erzeugt amount-bearing Link', () {
        const from = KittyMember(id: 1, name: 'Bob', categoryParticipation: {});
        const to = KittyMember(id: 2, name: 'Alice', categoryParticipation: {});
        const transfer = PaymentTransfer(fromMember: from, toMember: to, amountInCents: 1500);

        final url = resolvePaypalUrl(transfer: transfer, currency: 'EUR');
        expect(url, equals('https://paypal.me/Alice/15.00'));
      });

      test('EUR mit explizitem Link liefert gespeicherten Link unverändert', () {
        const from = KittyMember(id: 1, name: 'Bob', categoryParticipation: {});
        const to = KittyMember(id: 2, name: 'Alice', categoryParticipation: {}, paypalLink: 'https://paypal.me/alice_custom');
        const transfer = PaymentTransfer(fromMember: from, toMember: to, amountInCents: 1500);

        final url = resolvePaypalUrl(transfer: transfer, currency: 'EUR');
        expect(url, equals('https://paypal.me/alice_custom'));
      });

      test('USD ohne expliziten Link liefert null (kein ambivalenter Betrags-Link)', () {
        const from = KittyMember(id: 1, name: 'Bob', categoryParticipation: {});
        const to = KittyMember(id: 2, name: 'Alice', categoryParticipation: {});
        const transfer = PaymentTransfer(fromMember: from, toMember: to, amountInCents: 1500);

        final url = resolvePaypalUrl(transfer: transfer, currency: 'USD');
        expect(url, isNull);
      });

      test('USD mit explizitem Link liefert gespeicherten Link unverändert', () {
        const from = KittyMember(id: 1, name: 'Bob', categoryParticipation: {});
        const to = KittyMember(id: 2, name: 'Alice', categoryParticipation: {}, paypalLink: 'https://paypal.me/alice_usd');
        const transfer = PaymentTransfer(fromMember: from, toMember: to, amountInCents: 1500);

        final url = resolvePaypalUrl(transfer: transfer, currency: 'USD');
        expect(url, equals('https://paypal.me/alice_usd'));
      });
    });

    testWidgets('Finding N: USD ExpenseSheet Add zeigt USD, kein €, Custom Split in USD und speichert USD in DB', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createStandardTrip(currency: 'USD', setTreasurer: true);

      final container = ProviderContainer(
        overrides: [
          kittyServiceProvider.overrideWithValue(kittyService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: KittyScreen(tripId: tripId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // FAB antippen -> ExpenseSheet öffnet sich
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Hauptbetrag zeigt USD Suffix und kein €
      expect(find.text('USD'), findsWidgets);
      expect(find.text('€'), findsNothing);

      // Custom Split aktivieren unter "Mehr Optionen"
      final moreOptionsFinder = find.text('Mehr Optionen');
      await tester.ensureVisible(moreOptionsFinder);
      await tester.tap(moreOptionsFinder);
      await tester.pumpAndSettle();

      final switchFinder = find.widgetWithText(SwitchListTile, 'Individuelle Betragsaufteilung');
      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Beide Crew-Mitglieder (Alice und Bob) und Hauptfeld zeigen USD Suffix, kein €
      expect(find.text('USD'), findsNWidgets(3));
      expect(find.text('€'), findsNothing);

      // Beträge eingeben: Gesamt 60.00 USD, Alice 40.00, Bob 20.00
      final amountField = find.widgetWithText(TextFormField, 'Betrag *');
      await tester.ensureVisible(amountField);
      await tester.enterText(amountField, '60.00');

      // Split Textfelder ausfüllen (Index 0 ist Betrag, Index 1 ist Titel, Index 2 & 3 sind die Split-Felder)
      await tester.enterText(find.byType(TextField).at(2), '40.00');
      await tester.enterText(find.byType(TextField).at(3), '20.00');
      await tester.pumpAndSettle();

      // Speichern
      final saveFinder = find.text('Ausgabe speichern');
      await tester.ensureVisible(saveFinder);
      await tester.tap(saveFinder);
      await tester.pumpAndSettle();

      // In der DB prüfen
      final expenses = await db.expenseDao.getExpensesForTrip(tripId);
      expect(expenses.length, equals(1));
      expect(expenses.first.amount, equals(60.0));
      expect(expenses.first.currency, equals('USD'));
      expect(expenses.first.customSplit, isNotNull);
    });

    testWidgets('Finding N: USD Expense Edit Sheet zeigt USD, kein €, speichert neuen Betrag und bewahrt USD', (tester) async {
      final tripId = await createStandardTrip(currency: 'USD', setTreasurer: true);
      final crew = await db.tripDao.getCrewForTrip(tripId);

      // Vorhandene USD-Expense anlegen
      await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'Dinner USD',
        amountInCents: 5000,
        category: ExpenseCategory.provisions,
        paidByMemberId: crew.first.id,
        isPaidFromKitty: false,
      ));

      final container = ProviderContainer(
        overrides: [
          kittyServiceProvider.overrideWithValue(kittyService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: KittyScreen(tripId: tripId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expense antippen zum Bearbeiten
      final expFinder = find.text('Dinner USD');
      await tester.ensureVisible(expFinder);
      await tester.tap(expFinder);
      await tester.pumpAndSettle();

      // Edit Sheet prüft USD Suffix und Abwesenheit von €
      expect(find.text('Bearbeiten'), findsOneWidget);
      expect(find.text('USD'), findsWidgets);
      expect(find.text('€'), findsNothing);

      // Betrag auf 75.00 ändern
      final amountField = find.widgetWithText(TextFormField, 'Betrag *');
      await tester.enterText(amountField, '75.00');
      await tester.pumpAndSettle();

      // Speichern
      final saveFinder = find.text('Ausgabe speichern');
      await tester.ensureVisible(saveFinder);
      await tester.tap(saveFinder);
      await tester.pumpAndSettle();

      // DB prüfen: neuer Betrag 75.00, currency USD
      final expenses = await db.expenseDao.getExpensesForTrip(tripId);
      expect(expenses.length, equals(1));
      expect(expenses.first.amount, equals(75.0));
      expect(expenses.first.currency, equals('USD'));
    });

    testWidgets('Finding O: USD PaymentSheet zeigt USD, kein €, formatiert Gesamtsumme in USD und persistiert', (tester) async {
      final tripId = await createStandardTrip(currency: 'USD', kittyModel: KittyModel.sharedKitty, setTreasurer: true);

      final container = ProviderContainer(
        overrides: [
          kittyServiceProvider.overrideWithValue(kittyService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: KittyScreen(tripId: tripId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Popup-Menü öffnen und "Einzahlung erfassen" wählen
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Einzahlung erfassen'));
      await tester.pumpAndSettle();

      // PaymentSheet zeigt "Wie viel zahlt jeder ein? (USD)", Suffix "USD", kein "€"
      expect(find.text('Einzahlung erfassen'), findsOneWidget);
      expect(find.textContaining('Wie viel zahlt jeder ein? (USD)'), findsOneWidget);
      expect(find.text('USD'), findsWidgets);
      expect(find.text('€'), findsNothing);

      // Betrag 50.00 eingeben
      final amountField = find.widgetWithText(TextFormField, 'Wie viel zahlt jeder ein? (USD)');
      await tester.enterText(amountField, '50.00');
      await tester.pumpAndSettle();

      // 2 Personen vorausgewählt -> Gesamtsumme 100,00 USD
      expect(find.text('Einzahlungen speichern (100,00 USD)'), findsOneWidget);
      expect(find.textContaining('€'), findsNothing);

      // Speichern
      await tester.tap(find.text('Einzahlungen speichern (100,00 USD)'));
      await tester.pumpAndSettle();

      // In DB und Ledger prüfen
      final payments = await db.expenseDao.getKittyPaymentsForTrip(tripId);
      expect(payments.length, equals(2));
      for (final p in payments) {
        expect(p.amount, equals(50.0));
      }

      final kittyData = await kittyService.loadKittyData(tripId);
      expect(kittyData.sharedResult!.totalDepositsInCents, equals(10000));
      expect(kittyData.trip.currency, equals('USD'));
    });

    testWidgets('EUR Regression: ExpenseSheet und PaymentSheet zeigen weiterhin € für normale EUR-Törns', (tester) async {
      final tripId = await createStandardTrip(currency: 'EUR', setTreasurer: true);

      final container = ProviderContainer(
        overrides: [
          kittyServiceProvider.overrideWithValue(kittyService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: KittyScreen(tripId: tripId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ExpenseSheet öffnen -> € sichtbar
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('€'), findsWidgets);
      expect(find.text('EUR'), findsNothing);

      // Schließen
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // PaymentSheet öffnen -> € sichtbar
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Einzahlung erfassen'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Wie viel zahlt jeder ein? (€)'), findsOneWidget);
      expect(find.text('€'), findsWidgets);
      expect(find.text('EUR'), findsNothing);
    });

    testWidgets('Finding P: USD Settlement deaktiviert PayPal-Fallback ohne hinterlegten Link und hält Share in USD', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createStandardTrip(currency: 'USD', kittyModel: KittyModel.individualSettlement);
      final crew = await db.tripDao.getCrewForTrip(tripId);
      final alice = crew[0];
      final bob = crew[1];

      // Beide haben IBAN, aber KEINEN PayPal-Link
      await db.tripDao.updateCrewMember(alice.copyWith(iban: const Value('DE89370400440532013000')));
      await db.tripDao.updateCrewMember(bob.copyWith(iban: const Value('DE89370400440532013000')));

      // Alice zahlt 40 USD -> Bob schuldet Alice 20 USD
      await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'Groceries USD',
        amountInCents: 4000,
        category: ExpenseCategory.provisions,
        paidByMemberId: alice.id,
        isPaidFromKitty: false,
      ));

      final container = ProviderContainer(
        overrides: [
          kittyServiceProvider.overrideWithValue(kittyService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettlementScreen(tripId: tripId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Transfer Betrag zeigt USD
      expect(find.text('20,00 USD'), findsOneWidget);
      expect(find.textContaining('€'), findsNothing);

      // Transfer-Karte ausklappen falls noch nicht ausgeklappt
      if (find.text('PayPal-Link teilen').evaluate().isEmpty) {
        await tester.tap(find.text('Bezahlen').first);
        await tester.pumpAndSettle();
      }

      // PayPal Button finden
      expect(find.text('PayPal-Link teilen'), findsOneWidget);
      final paypalButtonFinder = find.ancestor(
        of: find.text('PayPal-Link teilen'),
        matching: find.byWidgetPredicate((w) => w is OutlinedButton),
      );
      expect(paypalButtonFinder, findsOneWidget);

      final paypalButton = tester.widget<OutlinedButton>(paypalButtonFinder);
      // Ohne expliziten PayPal-Link in USD MUSS der Button deaktiviert sein
      expect(paypalButton.onPressed, isNull);

      // Manuelle Zahlungsdaten und Teilen sind weiterhin aktiv
      expect(find.text('Überweisungsdaten kopieren'), findsOneWidget);
      expect(find.text('Revolut-Link teilen'), findsOneWidget);
    });

    testWidgets('Finding P: EUR Settlement behält funktionierenden PayPal-Fallback ohne hinterlegten Link', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createStandardTrip(currency: 'EUR', kittyModel: KittyModel.individualSettlement);
      final crew = await db.tripDao.getCrewForTrip(tripId);
      final alice = crew[0];
      final bob = crew[1];

      await db.tripDao.updateCrewMember(alice.copyWith(iban: const Value('DE89370400440532013000')));
      await db.tripDao.updateCrewMember(bob.copyWith(iban: const Value('DE89370400440532013000')));

      // Alice zahlt 40 EUR -> Bob schuldet Alice 20 EUR
      await kittyService.addExpense(ExpenseInput(
        tripId: tripId,
        title: 'Groceries EUR',
        amountInCents: 4000,
        category: ExpenseCategory.provisions,
        paidByMemberId: alice.id,
        isPaidFromKitty: false,
      ));

      final container = ProviderContainer(
        overrides: [
          kittyServiceProvider.overrideWithValue(kittyService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettlementScreen(tripId: tripId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Transfer-Karte ausklappen falls noch nicht ausgeklappt
      if (find.text('PayPal-Link teilen').evaluate().isEmpty) {
        await tester.tap(find.text('Bezahlen').first);
        await tester.pumpAndSettle();
      }

      expect(find.text('PayPal-Link teilen'), findsOneWidget);
      final paypalButtonFinder = find.ancestor(
        of: find.text('PayPal-Link teilen'),
        matching: find.byWidgetPredicate((w) => w is OutlinedButton),
      );
      expect(paypalButtonFinder, findsOneWidget);

      final paypalButton = tester.widget<OutlinedButton>(paypalButtonFinder);
      // In EUR ist der Button aktiv
      expect(paypalButton.onPressed, isNotNull);
    });
  });
}
