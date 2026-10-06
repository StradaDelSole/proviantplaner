/// Reine Dart-Rechenlogik für Bordkasse, Salden und Debt Simplification (Slice S5).
library;

import '../models/kitty_models.dart';

/// Ergebnis der einheitlichen Abrechnungsgrundlage (Unified Ledger, FIX-B).
class UnifiedLedgerResult {
  final int totalDepositsInCents;
  final int totalExpensesInCents;
  final int kittyPaidExpensesInCents;
  final int personallyPaidExpensesInCents;
  final int kittyCashInCents;
  final List<MemberBalance> memberBalances;
  final KittyMember? treasurer;

  const UnifiedLedgerResult({
    required this.totalDepositsInCents,
    required this.totalExpensesInCents,
    required this.kittyPaidExpensesInCents,
    required this.personallyPaidExpensesInCents,
    required this.kittyCashInCents,
    required this.memberBalances,
    this.treasurer,
  });
}

/// Ergebnis der Kassenberechnung für eine gemeinsame Bordkasse (FIX-B).
class SharedKittyCalculationResult {
  final int totalDepositsInCents;
  final int totalExpensesInCents;
  final int currentBalanceInCents;
  final int kittyPaidExpensesInCents;
  final int personallyPaidExpensesInCents;
  final List<MemberBalance> memberBalances;
  final List<PaymentTransfer> settlementTransfers;
  final KittyMember? treasurer;

  const SharedKittyCalculationResult({
    required this.totalDepositsInCents,
    required this.totalExpensesInCents,
    required this.currentBalanceInCents,
    this.kittyPaidExpensesInCents = 0,
    this.personallyPaidExpensesInCents = 0,
    required this.memberBalances,
    required this.settlementTransfers,
    this.treasurer,
  });
}

/// Ergebnis der Einzelabrechnung ("wer schuldet wem", FIX-B).
class IndividualSettlementResult {
  final int totalExpensesInCents;
  final List<MemberBalance> memberBalances;
  final List<PaymentTransfer> simplifiedTransfers;
  final int totalDepositsInCents;
  final int kittyPaidExpensesInCents;
  final int personallyPaidExpensesInCents;
  final int currentBalanceInCents;
  final KittyMember? treasurer;

  const IndividualSettlementResult({
    required this.totalExpensesInCents,
    required this.memberBalances,
    required this.simplifiedTransfers,
    this.totalDepositsInCents = 0,
    this.kittyPaidExpensesInCents = 0,
    this.personallyPaidExpensesInCents = 0,
    this.currentBalanceInCents = 0,
    this.treasurer,
  });
}

/// Engine zur centgenauen Berechnung beider Bordkassenmodelle (FIX-B: Unified Ledger).
class KittyEngine {
  const KittyEngine();

  /// Berechnet die einheitliche Abrechnungsgrundlage (Unified Ledger) für beide Modelle.
  UnifiedLedgerResult calculateUnifiedLedger({
    required List<KittyMember> members,
    required List<KittyDeposit> deposits,
    required List<KittyExpense> expenses,
    int? treasurerMemberId,
    String currency = 'EUR',
  }) {
    _validateLedgerInputs(members, deposits, expenses, currency);

    final kittyExpenses = expenses.where((e) => e.isPaidFromKitty).toList();
    final personExpenses = expenses.where((e) => !e.isPaidFromKitty).toList();

    final totalDeposits = deposits.fold<int>(0, (sum, d) => sum + d.amountInCents);
    final kittyPaidExpenses = kittyExpenses.fold<int>(0, (sum, e) => sum + e.amountInCents);
    final personallyPaidExpenses = personExpenses.fold<int>(0, (sum, e) => sum + e.amountInCents);
    final totalExpenses = expenses.fold<int>(0, (sum, e) => sum + e.amountInCents);
    final kittyCash = totalDeposits - kittyPaidExpenses;

    final resolvedTreasurer = _resolveTreasurer(members, treasurerMemberId);
    final memberDeposits = _sumDepositsByMember(deposits);
    final memberPersonalExpenses = _sumExpensesByPayer(personExpenses);
    final memberCostShares = _calculateCostShares(expenses, members);

    final balances = members.map((m) {
      final actualDeposits = memberDeposits[m.id] ?? 0;
      final personallyPaid = memberPersonalExpenses[m.id] ?? 0;
      final grossContribution = actualDeposits + personallyPaid;
      final costShare = memberCostShares[m.id] ?? 0;
      final isTreasurer = m.id == resolvedTreasurer?.id;
      final cashHeld = isTreasurer ? kittyCash : 0;

      return MemberBalance(
        member: m,
        paidInCents: grossContribution,
        costShareInCents: costShare,
        isTreasurer: isTreasurer,
        actualDepositsInCents: actualDeposits,
        personallyPaidExpensesInCents: personallyPaid,
        cashHeldInCents: cashHeld,
      );
    }).toList();

    return UnifiedLedgerResult(
      totalDepositsInCents: totalDeposits,
      totalExpensesInCents: totalExpenses,
      kittyPaidExpensesInCents: kittyPaidExpenses,
      personallyPaidExpensesInCents: personallyPaidExpenses,
      kittyCashInCents: kittyCash,
      memberBalances: balances,
      treasurer: resolvedTreasurer,
    );
  }

  /// Berechnet Modell 1: Gemeinsame Bordkasse (FB1-D mit Kassenwart).
  SharedKittyCalculationResult calculateSharedKitty({
    required List<KittyMember> members,
    required List<KittyDeposit> deposits,
    required List<KittyExpense> expenses,
    int? treasurerMemberId,
    String currency = 'EUR',
  }) {
    final ledger = calculateUnifiedLedger(
      members: members,
      deposits: deposits,
      expenses: expenses,
      treasurerMemberId: treasurerMemberId,
      currency: currency,
    );

    final transfers = _generateSharedKittyTransfers(ledger.memberBalances, ledger.treasurer);

    return SharedKittyCalculationResult(
      totalDepositsInCents: ledger.totalDepositsInCents,
      totalExpensesInCents: ledger.totalExpensesInCents,
      currentBalanceInCents: ledger.kittyCashInCents,
      kittyPaidExpensesInCents: ledger.kittyPaidExpensesInCents,
      personallyPaidExpensesInCents: ledger.personallyPaidExpensesInCents,
      memberBalances: ledger.memberBalances,
      settlementTransfers: transfers,
      treasurer: ledger.treasurer,
    );
  }

  /// Berechnet Modell 2: Einzelabrechnung ("wer schuldet wem").
  IndividualSettlementResult calculateIndividualSettlement({
    required List<KittyMember> members,
    required List<KittyExpense> expenses,
    List<KittyDeposit> deposits = const [],
    int? treasurerMemberId,
    String currency = 'EUR',
  }) {
    final ledger = calculateUnifiedLedger(
      members: members,
      deposits: deposits,
      expenses: expenses,
      treasurerMemberId: treasurerMemberId,
      currency: currency,
    );

    final transfers = simplifyDebts(ledger.memberBalances);

    return IndividualSettlementResult(
      totalExpensesInCents: ledger.totalExpensesInCents,
      memberBalances: ledger.memberBalances,
      simplifiedTransfers: transfers,
      totalDepositsInCents: ledger.totalDepositsInCents,
      kittyPaidExpensesInCents: ledger.kittyPaidExpensesInCents,
      personallyPaidExpensesInCents: ledger.personallyPaidExpensesInCents,
      currentBalanceInCents: ledger.kittyCashInCents,
      treasurer: ledger.treasurer,
    );
  }

  void _validateLedgerInputs(
    List<KittyMember> members,
    List<KittyDeposit> deposits,
    List<KittyExpense> expenses,
    String currency,
  ) {
    for (final exp in expenses) {
      if (exp.isPaidFromKitty && exp.paidByMemberId != null) {
        throw const LedgerValidationException(
          reason: LedgerValidationReason.unknownPayer,
          message: 'Kassenausgabe darf keinen persönlichen Zahler haben.',
        );
      }
      if (!exp.isPaidFromKitty && exp.paidByMemberId == null) {
        throw const LedgerValidationException(
          reason: LedgerValidationReason.missingPayer,
          message: 'Personenausgabe muss ein Crew-Mitglied als Zahler haben.',
        );
      }
      if (exp.paidByMemberId != null && !members.any((m) => m.id == exp.paidByMemberId)) {
        throw LedgerValidationException(
          reason: LedgerValidationReason.unknownPayer,
          message:
              'Zahler für Ausgabe "${exp.title}" (ID: ${exp.paidByMemberId}) ist nicht in den Crew-Mitgliedern enthalten.',
        );
      }

      if (exp.currency != currency) {
        throw LedgerValidationException(
          reason: LedgerValidationReason.currencyMismatch,
          message:
              'Ausgabe "${exp.title}" hat Währung ${exp.currency}, erwartet wird $currency.',
        );
      }

      if (exp.customSplitInCents != null && exp.customSplitInCents!.isNotEmpty) {
        int splitSum = 0;
        for (final entry in exp.customSplitInCents!.entries) {
          final memberId = entry.key;
          final share = entry.value;
          if (!members.any((m) => m.id == memberId)) {
            throw LedgerValidationException(
              reason: LedgerValidationReason.unknownCustomSplitMember,
              message:
                  'CustomSplit für Ausgabe "${exp.title}" enthält unbekanntes Crew-Mitglied ID $memberId.',
            );
          }
          if (share < 0) {
            throw LedgerValidationException(
              reason: LedgerValidationReason.negativeCustomSplitShare,
              message:
                  'CustomSplit für Ausgabe "${exp.title}" enthält negativen Anteil: $share Cent.',
            );
          }
          splitSum += share;
        }
        if (splitSum != exp.amountInCents) {
          throw LedgerValidationException(
            reason: LedgerValidationReason.customSplitTotalMismatch,
            message:
                'CustomSplit-Summe ($splitSum Cent) entspricht nicht dem Ausgabenbetrag (${exp.amountInCents} Cent).',
          );
        }
      }
    }

    for (final dep in deposits) {
      if (!members.any((m) => m.id == dep.memberId)) {
        throw LedgerValidationException(
          reason: LedgerValidationReason.unknownDepositMember,
          message:
              'Einzahler mit ID ${dep.memberId} ist nicht in den Crew-Mitgliedern enthalten.',
        );
      }
    }
  }

  KittyMember? _resolveTreasurer(List<KittyMember> members, int? treasurerMemberId) {
    if (members.isEmpty) return null;
    if (treasurerMemberId != null) {
      final found = members.where((m) => m.id == treasurerMemberId).firstOrNull;
      if (found != null) return found;
    }
    return members.where((m) => m.isSkipperFree).firstOrNull ?? members.firstOrNull;
  }

  /// Verteilt eine Ausgabe centgenau auf die teilnehmenden Crew-Mitglieder.
  Map<int, int> distributeExpense(KittyExpense expense, List<KittyMember> members) {
    if (expense.customSplitInCents != null && expense.customSplitInCents!.isNotEmpty) {
      return Map<int, int>.from(expense.customSplitInCents!);
    }

    final participants = members.where((m) => m.participatesIn(expense.category)).toList();
    final effectiveList = participants.isNotEmpty ? participants : members;
    final n = effectiveList.length;

    final base = expense.amountInCents ~/ n;
    final rem = expense.amountInCents % n;

    final result = <int, int>{};
    for (int i = 0; i < n; i++) {
      final m = effectiveList[i];
      result[m.id] = base + (i < rem ? 1 : 0);
    }
    return result;
  }

  /// Ermittelt die Summe der Kostenanteile je Mitglied über alle Ausgaben.
  Map<int, int> _calculateCostShares(List<KittyExpense> expenses, List<KittyMember> members) {
    final shares = <int, int>{for (final m in members) m.id: 0};

    for (final exp in expenses) {
      final split = distributeExpense(exp, members);
      for (final entry in split.entries) {
        shares[entry.key] = (shares[entry.key] ?? 0) + entry.value;
      }
    }
    return shares;
  }

  Map<int, int> _sumDepositsByMember(List<KittyDeposit> deposits) {
    final map = <int, int>{};
    for (final d in deposits) {
      map[d.memberId] = (map[d.memberId] ?? 0) + d.amountInCents;
    }
    return map;
  }

  Map<int, int> _sumExpensesByPayer(List<KittyExpense> expenses) {
    final map = <int, int>{};
    for (final e in expenses) {
      if (e.paidByMemberId != null) {
        map[e.paidByMemberId!] = (map[e.paidByMemberId!] ?? 0) + e.amountInCents;
      }
    }
    return map;
  }

  /// Berechnet minimale Ausgleichszahlungen per Greedy-Matching.
  List<PaymentTransfer> simplifyDebts(List<MemberBalance> balances) {
    final creditors = <_TempBalance>[];
    final debtors = <_TempBalance>[];

    for (final b in balances) {
      if (b.netBalanceInCents > 0) {
        creditors.add(_TempBalance(b.member, b.netBalanceInCents));
      } else if (b.netBalanceInCents < 0) {
        debtors.add(_TempBalance(b.member, -b.netBalanceInCents));
      }
    }

    final transfers = <PaymentTransfer>[];
    int cIdx = 0;
    int dIdx = 0;

    while (cIdx < creditors.length && dIdx < debtors.length) {
      final creditor = creditors[cIdx];
      final debtor = debtors[dIdx];

      final amount = creditor.amount < debtor.amount ? creditor.amount : debtor.amount;
      if (amount > 0) {
        transfers.add(
          PaymentTransfer(
            fromMember: debtor.member,
            toMember: creditor.member,
            amountInCents: amount,
          ),
        );
      }

      creditor.amount -= amount;
      debtor.amount -= amount;

      if (creditor.amount == 0) cIdx++;
      if (debtor.amount == 0) dIdx++;
    }

    return transfers;
  }

  List<PaymentTransfer> _generateSharedKittyTransfers(
    List<MemberBalance> balances,
    KittyMember? treasurer,
  ) {
    if (treasurer == null) return const [];
    final transfers = <PaymentTransfer>[];

    for (final b in balances) {
      if (b.member.id == treasurer.id) continue;

      if (b.netBalanceInCents < 0) {
        // Nachschuss in die Kasse: Mitglied zahlt an Kassenwart
        transfers.add(
          PaymentTransfer(
            fromMember: b.member,
            toMember: treasurer,
            amountInCents: -b.netBalanceInCents,
          ),
        );
      } else if (b.netBalanceInCents > 0) {
        // Rückzahlung aus der Kasse: Kassenwart zahlt an Mitglied
        transfers.add(
          PaymentTransfer(
            fromMember: treasurer,
            toMember: b.member,
            amountInCents: b.netBalanceInCents,
          ),
        );
      }
    }
    return transfers;
  }
}

class _TempBalance {
  final KittyMember member;
  int amount;
  _TempBalance(this.member, this.amount);
}
