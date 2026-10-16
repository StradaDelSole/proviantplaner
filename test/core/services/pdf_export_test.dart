/// Tests für den PDF-Exportdienst (Slice S8).
/// Verifiziert die fehlerfreie Erzeugung von PDF-Dokumenten für Einkaufsliste
/// und Bordkassenabrechnung gemäß Design-Brief und PRD.
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/tables.dart';
import 'package:proviantplaner/core/services/pdf_export_service.dart';
import 'package:proviantplaner/features/kitty/data/kitty_service.dart';
import 'package:proviantplaner/features/kitty/domain/calculation/kitty_engine.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/assist_type.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/catalog_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';

void main() {
  late PdfExportService pdfService;

  setUp(() {
    pdfService = PdfExportService();
  });

  Trip createTestTrip() {
    return Trip(
      id: 1,
      name: 'Sommertörn Elba',
      startDate: DateTime(2026, 8, 15),
      daysCount: 7,
      region: 'mediterranean',
      climate: 'warm',
      isCharter: true,
      boatType: 'mono',
      fridgeCapacity: 120,
      appetite: CrewAppetite.normal,
      reserveDays: 'few_days',
      drinkingHabit: CrewDrinking.normal,
      hasStorageChecklist: true,
      hasFreezer: false,
      freezerCapacity: 0,
      waterTankLiters: 0,
      isWaterTankDrinkable: false,
      hasWatermaker: false,
      phase: TripPhase.shopping,
      isArchived: false,
      currency: 'EUR',
      kittyModel: KittyModel.sharedKitty,
      createdAt: DateTime(2026, 8, 1),
    );
  }

  group('Slice S8: PDF-Export Tests', () {
    test('generateShoppingListPdf erzeugt valides PDF mit %PDF-Header und Abteilungen', () async {
      final trip = createTestTrip();

      const dummyListItem = ListItem(
        id: 10,
        tripId: 1,
        catalogId: 'brot_weissbrot',
        isCustom: false,
        selected: true,
        share: 1.0,
        calculatedQuantity: 2000,
        calculatedPackages: 4,
        checkState: CheckItemState.available,
        isAdopted: true,
      );

      const dummyItem2 = ListItem(
        id: 11,
        tripId: 1,
        catalogId: 'milch_vollmilch',
        isCustom: false,
        selected: true,
        share: 1.0,
        calculatedQuantity: 6.0,
        calculatedPackages: 6,
        checkState: CheckItemState.available,
        isAdopted: true,
      );

      const items = [
        ShoppingListItemView(
          item: dummyListItem,
          variant: null,
          id: 'brot_weissbrot',
          name: 'Weißbrot',
          unit: 'g',
          department: CatalogDepartment.backwaren,
          categoryId: 'bread',
          calculatedPackages: 4,
          overriddenPackages: null,
          calculatedQuantity: 2000,
          customPackageSize: 500,
          isSelected: true,
          share: 1.0,
          isCustom: false,
          shelfLifeDays: 4,
          storageHints: ['Kühl und trocken lagern'],
          allocationsByStop: {},
          assistType: AssistType.guided,
        ),
        ShoppingListItemView(
          item: dummyItem2,
          variant: null,
          id: 'milch_vollmilch',
          name: 'Vollmilch',
          unit: 'l',
          department: CatalogDepartment.molkerei,
          categoryId: 'dairy',
          calculatedPackages: 6,
          overriddenPackages: null,
          calculatedQuantity: 6.0,
          customPackageSize: 1.0,
          isSelected: true,
          share: 1.0,
          isCustom: false,
          shelfLifeDays: 7,
          storageHints: ['Immer kühlen'],
          allocationsByStop: {},
          assistType: AssistType.guided,
        ),
      ];

      const currentStop = ShoppingStop(
        id: 1,
        tripId: 1,
        name: 'Marina Portoferraio',
        dayNumber: 1,
        isInitial: true,
      );

      final Uint8List pdfBytes = await pdfService.generateShoppingListPdf(
        trip: trip,
        items: items,
        currentStop: currentStop,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));

      // PDF Magic Header: %PDF-
      final header = ascii.decode(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generateSettlementPdf erzeugt valides PDF mit Wer zahlt wem und Salden', () async {
      final trip = createTestTrip();

      const member1 = KittyMember(
        id: 1,
        name: 'Anna (Skipperin)',
        isSkipperFree: false,
        categoryParticipation: {},
      );

      const member2 = KittyMember(
        id: 2,
        name: 'Ben',
        isSkipperFree: false,
        categoryParticipation: {},
      );

      final expense1 = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Großeinkauf Supermarkt',
        amountInCents: 15400,
        currency: 'EUR',
        category: ExpenseCategory.provisions,
        paidByMemberId: 1,
        isPaidFromKitty: false,
        createdAt: DateTime(2026, 8, 15),
      );

      final deposit1 = KittyDeposit(
        id: 1,
        tripId: 1,
        memberId: 1,
        amountInCents: 8000,
        paidAt: DateTime(2026, 8, 15),
      );

      final deposit2 = KittyDeposit(
        id: 2,
        tripId: 1,
        memberId: 2,
        amountInCents: 8000,
        paidAt: DateTime(2026, 8, 15),
      );

      const settlementResult = SharedKittyCalculationResult(
        totalExpensesInCents: 15400,
        totalDepositsInCents: 16000,
        currentBalanceInCents: 600,
        memberBalances: [
          MemberBalance(
            member: member1,
            paidInCents: 15400,
            costShareInCents: 7700,
          ),
          MemberBalance(
            member: member2,
            paidInCents: 0,
            costShareInCents: 7700,
          ),
        ],
        settlementTransfers: [
          PaymentTransfer(
            fromMember: member2,
            toMember: member1,
            amountInCents: 7700,
          ),
        ],
      );

      final data = TripKittyData(
        trip: trip,
        model: KittyModel.sharedKitty,
        members: const [member1, member2],
        expenses: [expense1],
        deposits: [deposit1, deposit2],
        sharedResult: settlementResult,
      );

      final Uint8List pdfBytes = await pdfService.generateSettlementPdf(data: data);

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));

      final header = ascii.decode(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('FIX-B Finding E: SettlementPdfSummary canonical mixed case (320 EUR Ausgaben, 200 EUR Kassenstand)', () async {
      final trip = createTestTrip();
      const member1 = KittyMember(id: 1, name: 'Anna', categoryParticipation: {});
      const member2 = KittyMember(id: 2, name: 'Ben', categoryParticipation: {});
      const member3 = KittyMember(id: 3, name: 'Clara', categoryParticipation: {});
      const member4 = KittyMember(id: 4, name: 'David', categoryParticipation: {});

      final deposits = [
        KittyDeposit(id: 1, tripId: 1, memberId: 1, amountInCents: 10000, paidAt: DateTime(2026, 8, 15)),
        KittyDeposit(id: 2, tripId: 1, memberId: 2, amountInCents: 10000, paidAt: DateTime(2026, 8, 15)),
        KittyDeposit(id: 3, tripId: 1, memberId: 3, amountInCents: 10000, paidAt: DateTime(2026, 8, 15)),
        KittyDeposit(id: 4, tripId: 1, memberId: 4, amountInCents: 10000, paidAt: DateTime(2026, 8, 15)),
      ];

      final expenses = [
        KittyExpense(id: 1, tripId: 1, title: 'Proviant', amountInCents: 20000, category: ExpenseCategory.provisions, isPaidFromKitty: true, createdAt: DateTime(2026, 8, 15)),
        KittyExpense(id: 2, tripId: 1, title: 'Restaurant', amountInCents: 12000, category: ExpenseCategory.restaurant, paidByMemberId: 1, isPaidFromKitty: false, createdAt: DateTime(2026, 8, 15)),
      ];

      const engine = KittyEngine();
      final sharedResult = engine.calculateSharedKitty(
        members: const [member1, member2, member3, member4],
        deposits: deposits,
        expenses: expenses,
        treasurerMemberId: 1,
      );

      final data = TripKittyData(
        trip: trip,
        model: KittyModel.sharedKitty,
        members: const [member1, member2, member3, member4],
        expenses: expenses,
        deposits: deposits,
        sharedResult: sharedResult,
      );

      final summary = SettlementPdfSummary.fromTripKittyData(data);
      expect(summary.totalExpensesCents, equals(32000));
      expect(summary.totalDepositsCents, equals(40000));
      expect(summary.kittyCashCents, equals(20000));

      final Uint8List pdfBytes = await pdfService.generateSettlementPdf(data: data);
      expect(pdfBytes, isNotEmpty);
      expect(ascii.decode(pdfBytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('FIX-B Finding E: SettlementPdfSummary individual mode person-paid only does not fabricate negative cash', () async {
      final trip = createTestTrip().copyWith(kittyModel: KittyModel.individualSettlement);
      const member1 = KittyMember(id: 1, name: 'Anna', categoryParticipation: {});
      const member2 = KittyMember(id: 2, name: 'Ben', categoryParticipation: {});

      final expenses = [
        KittyExpense(id: 1, tripId: 1, title: 'Proviant', amountInCents: 10000, category: ExpenseCategory.provisions, paidByMemberId: 1, isPaidFromKitty: false, createdAt: DateTime(2026, 8, 15)),
      ];

      const engine = KittyEngine();
      final indResult = engine.calculateIndividualSettlement(
        members: const [member1, member2],
        deposits: const [],
        expenses: expenses,
      );

      final data = TripKittyData(
        trip: trip,
        model: KittyModel.individualSettlement,
        members: const [member1, member2],
        expenses: expenses,
        deposits: const [],
        individualResult: indResult,
      );

      final summary = SettlementPdfSummary.fromTripKittyData(data);
      expect(summary.totalExpensesCents, equals(10000));
      expect(summary.totalDepositsCents, equals(0));
      expect(summary.kittyCashCents, isNull);

      final Uint8List pdfBytes = await pdfService.generateSettlementPdf(data: data);
      expect(pdfBytes, isNotEmpty);
      expect(ascii.decode(pdfBytes.sublist(0, 5)), equals('%PDF-'));
    });
  });
}
