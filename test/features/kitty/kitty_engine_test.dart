/// Mathematische Unit-Tests für die Bordkassen-Engine (Slice S5).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/features/kitty/domain/calculation/kitty_engine.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';

void main() {
  const engine = KittyEngine();

  late KittyMember skipperAlex;
  late KittyMember berta;
  late KittyMember chris;
  late KittyMember emilNoAlk;

  setUp(() {
    skipperAlex = const KittyMember(
      id: 1,
      name: 'Skipper Alex',
      isSkipperFree: true,
      skipperFreeScope: 'exclude_food', // zahlt Proviant, Getränke, Restaurant, Sonstiges mit; Hafen/Diesel/Charter frei
      categoryParticipation: {},
    );

    berta = KittyMember(
      id: 2,
      name: 'Berta',
      isSkipperFree: false,
      categoryParticipation: {for (final c in ExpenseCategory.values) c: true},
    );

    chris = KittyMember(
      id: 3,
      name: 'Chris',
      isSkipperFree: false,
      categoryParticipation: {for (final c in ExpenseCategory.values) c: true},
    );

    emilNoAlk = KittyMember(
      id: 4,
      name: 'Emil (NoAlk)',
      isSkipperFree: false,
      categoryParticipation: {
        for (final c in ExpenseCategory.values) c: c != ExpenseCategory.drinks,
      },
    );
  });

  group('Slice S5: Modell 1 – Gemeinsame Bordkasse', () {
    test('Einzahlungen, Ausgaben aus der Kasse und Kassenstand-Bilanz', () {
      final members = [skipperAlex, berta, chris, emilNoAlk];

      // Jedes Mitglied zahlt 250,00 € (25.000 Cent) ein = 1.000,00 €
      final deposits = members.map((m) => KittyDeposit(
        id: m.id,
        tripId: 1,
        memberId: m.id,
        amountInCents: 25000,
        paidAt: DateTime(2026, 7, 1),
      )).toList();

      // Ausgaben aus der Kasse:
      // 1. Proviant: 400,00 € (alle 4 Personen beteiligt: 40000 / 4 = 10000 Cent = 100,00 € je Person)
      // 2. Diesel: 120,00 € (Skipper frei: 3 Personen beteiligt: 12000 / 3 = 4000 Cent = 40,00 € je Person)
      // 3. Getränke: 80,00 € (Emil trinkt keinen Alkohol: 3 Personen beteiligt: 8000 / 3 = 2666 + Rest 2 Cent)
      final expenses = [
        KittyExpense(
          id: 1,
          tripId: 1,
          title: 'Supermarkt-Einkauf',
          amountInCents: 40000,
          category: ExpenseCategory.provisions,
          isPaidFromKitty: true,
          createdAt: DateTime(2026, 7, 2),
        ),
        KittyExpense(
          id: 2,
          tripId: 1,
          title: 'Diesel Marina',
          amountInCents: 12000,
          category: ExpenseCategory.fuel,
          isPaidFromKitty: true,
          createdAt: DateTime(2026, 7, 3),
        ),
        KittyExpense(
          id: 3,
          tripId: 1,
          title: 'Bier & Wein',
          amountInCents: 8000,
          category: ExpenseCategory.drinks,
          isPaidFromKitty: true,
          createdAt: DateTime(2026, 7, 3),
        ),
      ];

      final result = engine.calculateSharedKitty(
        members: members,
        deposits: deposits,
        expenses: expenses,
      );

      // Gesamteinzahlung: 1.000,00 € = 100.000 Cent
      expect(result.totalDepositsInCents, equals(100000));

      // Gesamtausgaben: 400 + 120 + 80 = 600,00 € = 60.000 Cent
      expect(result.totalExpensesInCents, equals(60000));

      // Kassenstand: 100.000 - 60.000 = 40.000 Cent (400,00 € Rest)
      expect(result.currentBalanceInCents, equals(40000));

      // In FB1-D: Summe aller Netto-Salden ist mathematisch exakt 0 Cent (Kassenwart gleicht Kasse aus)
      final sumNetBalances = result.memberBalances.fold<int>(0, (sum, b) => sum + b.netBalanceInCents);
      expect(sumNetBalances, equals(0));

      // Skipper Alex ist Kassenwart
      expect(result.treasurer?.id, equals(skipperAlex.id));
      expect(result.settlementTransfers.every((t) => t.fromMember.id == skipperAlex.id || t.toMember.id == skipperAlex.id), isTrue);
      expect(result.settlementTransfers.any((t) => t.fromMember.name == 'Bordkasse' || t.toMember.name == 'Bordkasse'), isFalse);

      // Emil (NoAlk): zahlt Proviant (100 €) + Diesel (40 €) = 140,00 € Kostenanteil
      // Bei Getränken 0 €
      final emilBalance = result.memberBalances.firstWhere((b) => b.member.id == emilNoAlk.id);
      expect(emilBalance.costShareInCents, equals(14000));
    });
  });

  group('Slice S5: Modell 2 – Einzelabrechnung', () {
    test('Summe aller Netto-Salden ist mathematisch immer exakt 0 Cent', () {
      final members = [skipperAlex, berta, chris, emilNoAlk];

      // Berta zahlt Hafengebühr: 90,00 € (Skipper frei -> Berta, Chris, Emil zahlen je 30,00 €)
      // Chris zahlt Restaurant: 150,00 € (alle 4 beteiligt -> 15000 / 4 = 3750 Cent = 37,50 €)
      // Emil zahlt Getränke: 45,00 € (Emil trinkt nicht mit -> Alex, Berta, Chris zahlen je 15,00 €)
      final expenses = [
        KittyExpense(
          id: 1,
          tripId: 1,
          title: 'Hafengebühr Rogoznica',
          amountInCents: 9000,
          category: ExpenseCategory.marinaBerth,
          paidByMemberId: berta.id,
          createdAt: DateTime(2026, 7, 2),
        ),
        KittyExpense(
          id: 2,
          tripId: 1,
          title: 'Abendessen Konoba',
          amountInCents: 15000,
          category: ExpenseCategory.restaurant,
          paidByMemberId: chris.id,
          createdAt: DateTime(2026, 7, 3),
        ),
        KittyExpense(
          id: 3,
          tripId: 1,
          title: 'Getränkemarkt',
          amountInCents: 4500,
          category: ExpenseCategory.drinks,
          paidByMemberId: emilNoAlk.id,
          createdAt: DateTime(2026, 7, 4),
        ),
      ];

      final result = engine.calculateIndividualSettlement(
        members: members,
        expenses: expenses,
      );

      // Summe aller Salden ist exakt 0
      final sumNetBalances = result.memberBalances.fold<int>(0, (sum, b) => sum + b.netBalanceInCents);
      expect(sumNetBalances, equals(0),
          reason: 'In der Einzelabrechnung muss die Summe aller Salden immer exakt 0 Cent sein.');

      // Berta hat 90 € bezahlt, Kostenanteil: Hafen (30 €) + Restaurant (37,50 €) + Getränke (15 €) = 82,50 €
      // Netto: 90,00 - 82,50 = +7,50 € (bekommt 7,50 €)
      final bertaBal = result.memberBalances.firstWhere((b) => b.member.id == berta.id);
      expect(bertaBal.paidInCents, equals(9000));
      expect(bertaBal.costShareInCents, equals(8250));
      expect(bertaBal.netBalanceInCents, equals(750));

      // Ausgleichszahlungen minimieren (Debt Simplification)
      expect(result.simplifiedTransfers.isNotEmpty, isTrue);

      // Summe der Überweisungen deckt alle Schulden ab
      final totalTransferred = result.simplifiedTransfers.fold<int>(0, (sum, t) => sum + t.amountInCents);
      final totalCreditorAmount = result.memberBalances
          .where((b) => b.netBalanceInCents > 0)
          .fold<int>(0, (sum, b) => sum + b.netBalanceInCents);
      expect(totalTransferred, equals(totalCreditorAmount));
    });
  });

  group('Slice S5: Cent-genaue Restaufteilung & Skipper frei', () {
    test('100,00 € auf 3 Personen teilt Rest-Cent ohne Rundungsverlust auf (33,34 € + 33,33 € + 33,33 €)', () {
      final members = [berta, chris, emilNoAlk];
      final exp = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Einkauf',
        amountInCents: 10000,
        category: ExpenseCategory.provisions,
        createdAt: DateTime(2026, 7, 1),
      );

      final split = engine.distributeExpense(exp, members);
      final sumSplit = split.values.fold<int>(0, (sum, val) => sum + val);

      // Exakte Cent-Summe
      expect(sumSplit, equals(10000));
      expect(split[berta.id], equals(3334));
      expect(split[chris.id], equals(3333));
      expect(split[emilNoAlk.id], equals(3333));
    });

    test('Skipper frei ganz: 0 % Kostenanteil auf alle Kategorien', () {
      const fullFreeSkipper = KittyMember(
        id: 9,
        name: 'Skipper Hans',
        isSkipperFree: true,
        skipperFreeScope: 'all',
        categoryParticipation: {},
      );

      final members = [fullFreeSkipper, berta];
      final exp = KittyExpense(
        id: 1,
        tripId: 1,
        title: 'Einkauf',
        amountInCents: 5000,
        category: ExpenseCategory.provisions,
        createdAt: DateTime(2026, 7, 1),
      );

      final split = engine.distributeExpense(exp, members);
      expect(split[fullFreeSkipper.id], isNull);
      expect(split[berta.id], equals(5000), reason: 'Berta übernimmt 100% da Skipper ganz frei ist.');
    });
  });

  group('Slice S5: EPC-QR-Code (GiroCode) Spezifikation EPC069-12', () {
    test('Erzeugt validen EPC069-12 Payload-String', () {
      final payload = EpcQrPayload(
        beneficiaryName: 'Berta Seglerin',
        iban: 'DE12 5001 0517 0648 4898 90',
        bic: 'HELAADEF100',
        amountInCents: 4210,
        remittanceInformation: 'Bordkasse Ausgleich Sommer 2026',
      );

      final epcString = payload.toEpcString();
      final lines = epcString.split('\n');

      expect(lines[0], equals('BCD'), reason: 'Line 1: Service Tag must be BCD');
      expect(lines[1], equals('002'), reason: 'Line 2: Version must be 002');
      expect(lines[2], equals('1'), reason: 'Line 3: Encoding must be 1 (UTF-8)');
      expect(lines[3], equals('SCT'), reason: 'Line 4: Identification must be SCT');
      expect(lines[4], equals('HELAADEF100'), reason: 'Line 5: BIC');
      expect(lines[5], equals('Berta Seglerin'), reason: 'Line 6: Beneficiary Name');
      expect(lines[6], equals('DE12500105170648489890'), reason: 'Line 7: Clean IBAN without spaces');
      expect(lines[7], equals('EUR42.10'), reason: 'Line 8: Amount formatted as EUR42.10');
      expect(lines[10], equals('Bordkasse Ausgleich Sommer 2026'), reason: 'Line 11: Remittance Info');
    });
  });
}
