/// Reine Dart-Rechenlogik für Bordkasse, Salden und Debt Simplification (Slice S5).
library;

import '../models/kitty_models.dart';

/// Ergebnis der Kassenberechnung für eine gemeinsame Bordkasse.
class SharedKittyCalculationResult {
  final int totalDepositsInCents;
  final int totalExpensesInCents;
  final int currentBalanceInCents;
  final List<MemberBalance> memberBalances;
  final List<PaymentTransfer> settlementTransfers;

  const SharedKittyCalculationResult({
    required this.totalDepositsInCents,
    required this.totalExpensesInCents,
    required this.currentBalanceInCents,
    required this.memberBalances,
    required this.settlementTransfers,
  });
}

/// Ergebnis der Einzelabrechnung ("wer schuldet wem").
class IndividualSettlementResult {
  final int totalExpensesInCents;
  final List<MemberBalance> memberBalances;
  final List<PaymentTransfer> simplifiedTransfers;

  const IndividualSettlementResult({
    required this.totalExpensesInCents,
    required this.memberBalances,
    required this.simplifiedTransfers,
  });
}

/// Engine zur centgenauen Berechnung beider Bordkassenmodelle.
class KittyEngine {
  const KittyEngine();

  /// Berechnet Modell 1: Gemeinsame Bordkasse.
  SharedKittyCalculationResult calculateSharedKitty({
    required List<KittyMember> members,
    required List<KittyDeposit> deposits,
    required List<KittyExpense> expenses,
  }) {
    final kittyExpenses = expenses.where((e) => e.isPaidFromKitty).toList();
    final totalDeposits = deposits.fold<int>(0, (sum, d) => sum + d.amountInCents);
    final totalExpenses = kittyExpenses.fold<int>(0, (sum, e) => sum + e.amountInCents);
    final currentBalance = totalDeposits - totalExpenses;

    final memberPaidMap = _sumDepositsByMember(deposits);
    final memberCostShareMap = _calculateCostShares(kittyExpenses, members);

    final balances = members.map((m) {
      final paid = memberPaidMap[m.id] ?? 0;
      final cost = memberCostShareMap[m.id] ?? 0;
      return MemberBalance(member: m, paidInCents: paid, costShareInCents: cost);
    }).toList();

    final transfers = _generateSharedKittyTransfers(balances);

    return SharedKittyCalculationResult(
      totalDepositsInCents: totalDeposits,
      totalExpensesInCents: totalExpenses,
      currentBalanceInCents: currentBalance,
      memberBalances: balances,
      settlementTransfers: transfers,
    );
  }

  /// Berechnet Modell 2: Einzelabrechnung ("wer schuldet wem").
  IndividualSettlementResult calculateIndividualSettlement({
    required List<KittyMember> members,
    required List<KittyExpense> expenses,
  }) {
    final totalExpenses = expenses.fold<int>(0, (sum, e) => sum + e.amountInCents);
    final memberPaidMap = _sumExpensesByPayer(expenses);
    final memberCostShareMap = _calculateCostShares(expenses, members);

    final balances = members.map((m) {
      final paid = memberPaidMap[m.id] ?? 0;
      final cost = memberCostShareMap[m.id] ?? 0;
      return MemberBalance(member: m, paidInCents: paid, costShareInCents: cost);
    }).toList();

    final transfers = simplifyDebts(balances);

    return IndividualSettlementResult(
      totalExpensesInCents: totalExpenses,
      memberBalances: balances,
      simplifiedTransfers: transfers,
    );
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

  List<PaymentTransfer> _generateSharedKittyTransfers(List<MemberBalance> balances) {
    final transfers = <PaymentTransfer>[];
    const kittyPseudoMember = KittyMember(
      id: 0,
      name: 'Bordkasse',
      categoryParticipation: {},
    );

    for (final b in balances) {
      if (b.netBalanceInCents < 0) {
        // Nachschuss in die Kasse
        transfers.add(
          PaymentTransfer(
            fromMember: b.member,
            toMember: kittyPseudoMember,
            amountInCents: -b.netBalanceInCents,
          ),
        );
      } else if (b.netBalanceInCents > 0) {
        // Rückzahlung aus der Kasse
        transfers.add(
          PaymentTransfer(
            fromMember: kittyPseudoMember,
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
