/// Domänenmodelle für die Bordkasse und Kostenteilung (Slice S5).
library;

import 'package:flutter/material.dart';

/// Die zwei Bordkassenmodelle laut PRD und SLICES_v0.12.
enum KittyModel {
  sharedKitty('shared_kitty'),
  individualSettlement('individual_settlement');

  final String rawValue;
  const KittyModel(this.rawValue);

  static KittyModel fromString(String val) {
    for (final m in values) {
      if (m.rawValue == val) return m;
    }
    return sharedKitty;
  }
}

/// Die 7 Ausgabenkategorien für die Bordkasse (Design-Brief Abschnitt 2).
enum ExpenseCategory {
  provisions('provisions'),
  drinks('drinks'),
  marinaBerth('marina_berth'),
  fuel('fuel'),
  charterDeposit('charter_deposit'),
  restaurant('restaurant'),
  other('other');

  final String rawValue;
  const ExpenseCategory(this.rawValue);

  static ExpenseCategory fromString(String val) {
    for (final c in values) {
      if (c.rawValue == val) return c;
    }
    return other;
  }

  /// Deutscher Anzeigename der Kategorie.
  String get displayName => switch (this) {
        provisions => 'Proviant',
        drinks => 'Getränke',
        marinaBerth => 'Hafen und Liegeplatz',
        fuel => 'Diesel',
        charterDeposit => 'Charter und Kaution',
        restaurant => 'Restaurant',
        other => 'Sonstiges',
      };

  /// Icon gemäß Design-Brief (Hafen: location_on, Diesel: local_gas_station, Charter: receipt_long).
  IconData get icon => switch (this) {
        provisions => Icons.shopping_basket_outlined,
        drinks => Icons.local_drink_outlined,
        marinaBerth => Icons.location_on_outlined,
        fuel => Icons.local_gas_station_outlined,
        charterDeposit => Icons.receipt_long_outlined,
        restaurant => Icons.restaurant_outlined,
        other => Icons.more_horiz_outlined,
      };
}

/// Schnellauswahl-Profile für die Kategorie-Beteiligung (SC-KAS-04).
enum ParticipationProfile {
  all,
  skipperFreeFull,
  skipperFreePartial,
  noAlcohol,
  custom;

  /// Ermittelt die Standard-Kategoriebeteiligung für dieses Profil.
  Map<ExpenseCategory, bool> toParticipationMap() {
    return switch (this) {
      all => {for (final c in ExpenseCategory.values) c: true},
      skipperFreeFull => {for (final c in ExpenseCategory.values) c: false},
      skipperFreePartial => {
          ExpenseCategory.provisions: true,
          ExpenseCategory.drinks: true,
          ExpenseCategory.restaurant: true,
          ExpenseCategory.other: true,
          ExpenseCategory.charterDeposit: false,
          ExpenseCategory.marinaBerth: false,
          ExpenseCategory.fuel: false,
        },
      noAlcohol => {
          for (final c in ExpenseCategory.values) c: c != ExpenseCategory.drinks,
        },
      custom => {for (final c in ExpenseCategory.values) c: true},
    };
  }
}

/// Person für die Kassenberechnung mit Beteiligungsregeln.
class KittyMember {
  final int id;
  final String name;
  final bool isSkipperFree;
  final String? skipperFreeScope;
  final Map<ExpenseCategory, bool> categoryParticipation;

  const KittyMember({
    required this.id,
    required this.name,
    this.isSkipperFree = false,
    this.skipperFreeScope,
    required this.categoryParticipation,
  });

  /// Prüft, ob die Person an einer Kategorie beteiligt ist.
  bool participatesIn(ExpenseCategory category) {
    if (isSkipperFree) {
      if (skipperFreeScope == 'all') return false;
      if (skipperFreeScope == 'exclude_food') {
        return category == ExpenseCategory.provisions ||
            category == ExpenseCategory.drinks ||
            category == ExpenseCategory.restaurant ||
            category == ExpenseCategory.other;
      }
    }
    return categoryParticipation[category] ?? true;
  }
}

/// Repräsentiert eine Ausgabe mit Betrag in Cent.
class KittyExpense {
  final int id;
  final int tripId;
  final String title;
  final int amountInCents;
  final String currency;
  final ExpenseCategory category;
  final int? paidByMemberId;
  final bool isPaidFromKitty;
  final DateTime createdAt;
  final Map<int, int>? customSplitInCents;

  const KittyExpense({
    required this.id,
    required this.tripId,
    required this.title,
    required this.amountInCents,
    this.currency = 'EUR',
    required this.category,
    this.paidByMemberId,
    this.isPaidFromKitty = false,
    required this.createdAt,
    this.customSplitInCents,
  });
}

/// Repräsentiert eine Einzahlung in die Bordkasse (in Cent).
class KittyDeposit {
  final int id;
  final int tripId;
  final int memberId;
  final int amountInCents;
  final DateTime paidAt;

  const KittyDeposit({
    required this.id,
    required this.tripId,
    required this.memberId,
    required this.amountInCents,
    required this.paidAt,
  });
}

/// Saldo einer einzelnen Person.
class MemberBalance {
  final KittyMember member;
  final int paidInCents;
  final int costShareInCents;

  const MemberBalance({
    required this.member,
    required this.paidInCents,
    required this.costShareInCents,
  });

  /// Netto-Saldo: Positiv = bekommt Geld zurück, Negativ = muss zahlen.
  int get netBalanceInCents => paidInCents - costShareInCents;

  /// Formatierte Anzeige des Betrags in Euro (z. B. "18,00 €").
  String get formattedNetBalance {
    final absCents = netBalanceInCents.abs();
    final euros = absCents ~/ 100;
    final cents = absCents % 100;
    final formatted = '$euros,${cents.toString().padLeft(2, '0')} €';
    if (netBalanceInCents > 0) return 'bekommt $formatted';
    if (netBalanceInCents < 0) return 'zahlt $formatted';
    return 'ausgeglichen';
  }
}

/// Ausgleichszahlung ("wer schuldet wem").
class PaymentTransfer {
  final KittyMember fromMember;
  final KittyMember toMember;
  final int amountInCents;
  final bool isSettled;

  const PaymentTransfer({
    required this.fromMember,
    required this.toMember,
    required this.amountInCents,
    this.isSettled = false,
  });

  /// Formatierter Euro-Betrag (z. B. "42,10 €").
  String get formattedAmount {
    final euros = amountInCents ~/ 100;
    final cents = amountInCents % 100;
    return '$euros,${cents.toString().padLeft(2, '0')} €';
  }

  PaymentTransfer copyWith({bool? isSettled}) {
    return PaymentTransfer(
      fromMember: fromMember,
      toMember: toMember,
      amountInCents: amountInCents,
      isSettled: isSettled ?? this.isSettled,
    );
  }
}

/// Datenstruktur für den EPC-QR-Code (GiroCode) gemäß EPC069-12.
class EpcQrPayload {
  final String beneficiaryName;
  final String iban;
  final String? bic;
  final int amountInCents;
  final String remittanceInformation;

  const EpcQrPayload({
    required this.beneficiaryName,
    required this.iban,
    this.bic,
    required this.amountInCents,
    required this.remittanceInformation,
  });

  /// Erzeugt die standardkonforme Byte-Zeichenkette für den GiroCode.
  String toEpcString() {
    final cleanIban = iban.replaceAll(' ', '').toUpperCase();
    final euros = amountInCents ~/ 100;
    final cents = amountInCents % 100;
    final amountStr = 'EUR$euros.${cents.toString().padLeft(2, '0')}';

    return [
      'BCD',
      '002',
      '1',
      'SCT',
      bic ?? '',
      beneficiaryName,
      cleanIban,
      amountStr,
      '',
      '',
      remittanceInformation,
    ].join('\n');
  }
}
