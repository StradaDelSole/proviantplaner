/// Service für Bordkassen-Verwaltung, Salden und Zahlungsanweisungen (Slice S5).
library;

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/daos.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';
import '../domain/calculation/kitty_engine.dart';
import '../domain/models/kitty_models.dart';

/// Aggregiertes Kassen-Datenobjekt für die Benutzeroberfläche.
class TripKittyData {
  final Trip trip;
  final KittyModel model;
  final List<KittyMember> members;
  final List<KittyExpense> expenses;
  final List<KittyDeposit> deposits;
  final SharedKittyCalculationResult? sharedResult;
  final IndividualSettlementResult? individualResult;

  const TripKittyData({
    required this.trip,
    required this.model,
    required this.members,
    required this.expenses,
    required this.deposits,
    this.sharedResult,
    this.individualResult,
  });

  /// Gibt die Liste der Netto-Salden für alle Crew-Mitglieder zurück.
  List<MemberBalance> get balances =>
      sharedResult?.memberBalances ?? individualResult?.memberBalances ?? const [];

  /// Gibt die Liste der berechneten Ausgleichszahlungen zurück.
  List<PaymentTransfer> get transfers =>
      sharedResult?.settlementTransfers ?? individualResult?.simplifiedTransfers ?? const [];
}

/// Eingabe-Objekt zum Erfassen oder Bearbeiten einer Ausgabe (SC-KAS-02).
class ExpenseInput {
  final int tripId;
  final String title;
  final int amountInCents;
  final ExpenseCategory category;
  final int? paidByMemberId;
  final bool isPaidFromKitty;
  final Map<int, int>? customSplitInCents;
  final DateTime? createdAt;

  const ExpenseInput({
    required this.tripId,
    required this.title,
    required this.amountInCents,
    required this.category,
    this.paidByMemberId,
    this.isPaidFromKitty = false,
    this.customSplitInCents,
    this.createdAt,
  });
}

/// Service zur Verwaltung der Bordkassendaten.
class KittyService {
  final TripDao tripDao;
  final ExpenseDao expenseDao;
  final KittyEngine engine;

  KittyService({
    required this.tripDao,
    required this.expenseDao,
    this.engine = const KittyEngine(),
  });

  /// Lädt den vollständigen Kassenstand inklusive Salden und Abrechnung.
  Future<TripKittyData> loadKittyData(int tripId) async {
    final trip = await tripDao.getTripById(tripId);
    if (trip == null) {
      throw ArgumentError('Törn $tripId nicht gefunden.');
    }

    final rawCrew = await tripDao.getCrewForTrip(tripId);
    final rawExpenses = await expenseDao.getExpensesForTrip(tripId);
    final rawDeposits = await expenseDao.getKittyPaymentsForTrip(tripId);

    final members = rawCrew.map(_mapCrewMember).toList();
    final expenses = rawExpenses.map(_mapExpense).toList();
    final deposits = rawDeposits.map(_mapDeposit).toList();

    final model = trip.kittyModel;

    SharedKittyCalculationResult? sharedRes;
    IndividualSettlementResult? indRes;

    if (model == KittyModel.sharedKitty) {
      sharedRes = engine.calculateSharedKitty(
        members: members,
        deposits: deposits,
        expenses: expenses,
      );
    } else {
      indRes = engine.calculateIndividualSettlement(
        members: members,
        expenses: expenses,
      );
    }

    return TripKittyData(
      trip: trip,
      model: model,
      members: members,
      expenses: expenses,
      deposits: deposits,
      sharedResult: sharedRes,
      individualResult: indRes,
    );
  }

  KittyMember _mapCrewMember(CrewMember c) {
    Map<ExpenseCategory, bool> partMap = {};
    try {
      final jsonMap = json.decode(c.categoryParticipation) as Map<String, dynamic>;
      if (jsonMap['all'] == true) {
        partMap = {for (final cat in ExpenseCategory.values) cat: true};
      } else {
        for (final cat in ExpenseCategory.values) {
          partMap[cat] = jsonMap[cat.rawValue] == true;
        }
      }
    } catch (_) {
      partMap = {for (final cat in ExpenseCategory.values) cat: true};
    }

    return KittyMember(
      id: c.id,
      name: c.name,
      isSkipperFree: c.isSkipperFree,
      skipperFreeScope: c.skipperFreeScope,
      categoryParticipation: partMap,
      iban: c.iban,
      paypalLink: c.paypalLink,
      revolutLink: c.revolutLink,
    );
  }

  KittyExpense _mapExpense(Expense e) {
    Map<int, int>? customSplit;
    if (e.customSplit != null && e.customSplit!.isNotEmpty) {
      try {
        final splitJson = json.decode(e.customSplit!) as Map<String, dynamic>;
        customSplit = splitJson.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
      } catch (_) {}
    }

    return KittyExpense(
      id: e.id,
      tripId: e.tripId,
      title: e.note ?? e.category.displayName,
      amountInCents: (e.amount * 100).round(),
      currency: e.currency,
      category: e.category,
      paidByMemberId: e.paidByCrewMemberId,
      isPaidFromKitty: e.isPaidFromKitty,
      createdAt: e.createdAt,
      customSplitInCents: customSplit,
    );
  }

  KittyDeposit _mapDeposit(KittyPayment p) {
    return KittyDeposit(
      id: p.id,
      tripId: p.tripId,
      memberId: p.crewMemberId,
      amountInCents: (p.amount * 100).round(),
      paidAt: p.paidAt,
    );
  }

  /// Erfasst eine neue Ausgabe (SC-KAS-02).
  Future<int> addExpense(ExpenseInput input) {
    final euros = input.amountInCents / 100.0;
    String? splitJson;
    if (input.customSplitInCents != null) {
      final strMap = input.customSplitInCents!.map((k, v) => MapEntry(k.toString(), v));
      splitJson = json.encode(strMap);
    }

    return expenseDao.addExpense(
      ExpensesCompanion.insert(
        tripId: input.tripId,
        amount: euros,
        category: input.category,
        note: Value(input.title),
        isPaidFromKitty: Value(input.isPaidFromKitty),
        paidByCrewMemberId: Value(input.paidByMemberId),
        customSplit: Value(splitJson),
        createdAt: Value(input.createdAt ?? DateTime.now()),
      ),
    );
  }

  /// Erfasst eine Einzahlung in die Bordkasse (SC-KAS-03).
  Future<int> addDeposit({
    required int tripId,
    required int memberId,
    required int amountInCents,
  }) {
    final euros = amountInCents / 100.0;
    return expenseDao.addKittyPayment(
      KittyPaymentsCompanion.insert(
        tripId: tripId,
        crewMemberId: memberId,
        amount: euros,
        paidAt: Value(DateTime.now()),
      ),
    );
  }

  /// Aktualisiert das Kassenmodell für den Törn (Bordkasse vs. Einzelabrechnung).
  Future<bool> switchKittyModel(int tripId, KittyModel newModel) async {
    final trip = await tripDao.getTripById(tripId);
    if (trip == null) return false;
    return tripDao.updateTrip(trip.copyWith(kittyModel: newModel));
  }

  /// Aktualisiert die Kategoriebeteiligung eines Mitglieds (SC-KAS-04).
  Future<bool> updateMemberParticipation({
    required int memberId,
    required Map<ExpenseCategory, bool> participation,
    required bool isSkipperFree,
    String? skipperFreeScope,
  }) async {
    final crew = await tripDao.db.select(tripDao.db.crewMembers).get();
    final member = crew.where((c) => c.id == memberId).firstOrNull;
    if (member == null) return false;

    final jsonMap = participation.map((k, v) => MapEntry(k.rawValue, v));
    final updated = member.copyWith(
      categoryParticipation: json.encode(jsonMap),
      isSkipperFree: isSkipperFree,
      skipperFreeScope: Value(skipperFreeScope),
    );
    return tripDao.updateCrewMember(updated);
  }

  /// Löscht eine Ausgabe.
  Future<int> deleteExpense(int id) => expenseDao.deleteExpense(id);

  /// Aktualisiert eine bestehende Ausgabe (FEEDBACK_R1 Punkt 8).
  Future<bool> updateExpense({
    required int id,
    required ExpenseInput input,
  }) {
    final euros = input.amountInCents / 100.0;
    String? splitJson;
    if (input.customSplitInCents != null) {
      final strMap = input.customSplitInCents!.map((k, v) => MapEntry(k.toString(), v));
      splitJson = json.encode(strMap);
    }

    return expenseDao.updateExpense(
      Expense(
        id: id,
        tripId: input.tripId,
        amount: euros,
        currency: 'EUR',
        category: input.category,
        paidByCrewMemberId: input.paidByMemberId,
        isPaidFromKitty: input.isPaidFromKitty,
        customSplit: splitJson,
        note: input.title,
        createdAt: input.createdAt ?? DateTime.now(),
      ),
    );
  }

  /// Stellt eine gelöschte Ausgabe wieder her (Rückgängig-Funktion).
  Future<int> restoreExpense(KittyExpense exp) {
    return expenseDao.addExpense(
      ExpensesCompanion.insert(
        id: Value(exp.id),
        tripId: exp.tripId,
        amount: exp.amountInCents / 100.0,
        category: exp.category,
        note: Value(exp.title),
        isPaidFromKitty: Value(exp.isPaidFromKitty),
        paidByCrewMemberId: Value(exp.paidByMemberId),
        customSplit: Value(
          exp.customSplitInCents != null
              ? json.encode(exp.customSplitInCents!.map((k, v) => MapEntry(k.toString(), v)))
              : null,
        ),
        createdAt: Value(exp.createdAt),
      ),
    );
  }

  /// Aktualisiert die Zahlungsdaten eines Crew-Mitglieds (FEEDBACK_R1 Punkt 10).
  Future<bool> updateMemberPaymentDetails({
    required int memberId,
    String? iban,
    String? paypalLink,
    String? revolutLink,
  }) {
    return tripDao.updateCrewMemberPaymentDetails(
      memberId: memberId,
      iban: iban,
      paypalLink: paypalLink,
      revolutLink: revolutLink,
    );
  }

  /// Löscht eine Einzahlung.
  Future<int> deleteDeposit(int id) => expenseDao.deleteKittyPayment(id);

  /// Archiviert den Törn nach erfolgreicher Kassenabrechnung.
  Future<bool> archiveTrip(int tripId) async {
    final trip = await tripDao.getTripById(tripId);
    if (trip == null) return false;
    return tripDao.updateTrip(
      trip.copyWith(
        isArchived: true,
        phase: TripPhase.conclusion,
      ),
    );
  }
}
