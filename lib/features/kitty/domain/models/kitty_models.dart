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
    throw FormatException('Unbekanntes KittyModel: "$val"');
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
    throw FormatException('Unbekannte ExpenseCategory: "$val"');
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
  final String? iban;
  final String? paypalLink;
  final String? revolutLink;

  const KittyMember({
    required this.id,
    required this.name,
    this.isSkipperFree = false,
    this.skipperFreeScope,
    required this.categoryParticipation,
    this.iban,
    this.paypalLink,
    this.revolutLink,
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

/// Exception bei ungültigen Feldern im EPC-QR-Code (GiroCode).
class EpcValidationException implements Exception {
  final String field;
  final String reason;

  const EpcValidationException(this.field, this.reason);

  @override
  String toString() => 'EpcValidationException: Feld "$field" ungültig: $reason';
}

/// Prüfer für internationale Kontonummern (IBAN) nach ISO 13616 und Modulo-97-Prüfziffer.
class IbanValidator {
  /// Prüft, ob [iban] syntaktisch und rechnerisch (Modulo 97) valide ist.
  static bool isValid(String iban) {
    final clean = iban.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (clean.length < 15 || clean.length > 34) return false;
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]+$').hasMatch(clean)) return false;

    // Erste 4 Zeichen ans Ende verschieben (Ländercode + Prüfziffer)
    final rearranged = clean.substring(4) + clean.substring(0, 4);

    // Buchstaben durch zweistellige Zahlen ersetzen (A=10, ..., Z=35)
    final sb = StringBuffer();
    for (int i = 0; i < rearranged.length; i++) {
      final code = rearranged.codeUnitAt(i);
      if (code >= 65 && code <= 90) {
        sb.write(code - 55);
      } else {
        sb.writeCharCode(code);
      }
    }

    final digits = sb.toString();
    final bigInt = BigInt.tryParse(digits);
    if (bigInt == null) return false;
    return (bigInt % BigInt.from(97)) == BigInt.one;
  }
}

/// Datenstruktur für den EPC-QR-Code (GiroCode) gemäß EPC069-12.
class EpcQrPayload {
  final String beneficiaryName;
  final String iban;
  final String? bic;
  final int amountInCents;
  final String remittanceInformation;

  /// Erstellt und validiert die EPC-GiroCode Nutzlast strikt nach Standard EPC069-12.
  EpcQrPayload({
    required this.beneficiaryName,
    required this.iban,
    this.bic,
    required this.amountInCents,
    required this.remittanceInformation,
  }) {
    validate();
  }

  /// Führt alle Validierungsregeln gemäß EPC-Spezifikation durch.
  void validate() {
    if (beneficiaryName.trim().isEmpty) {
      throw const EpcValidationException('beneficiaryName', 'Name des Empfängers darf nicht leer sein.');
    }
    if (beneficiaryName.length > 70) {
      throw EpcValidationException(
        'beneficiaryName',
        'Name darf höchstens 70 Zeichen lang sein (aktuell: ${beneficiaryName.length}).',
      );
    }
    if (beneficiaryName.contains('\n') || beneficiaryName.contains('\r')) {
      throw const EpcValidationException('beneficiaryName', 'Name darf keine Zeilenumbrüche enthalten.');
    }

    final cleanIban = iban.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (!IbanValidator.isValid(cleanIban)) {
      throw EpcValidationException('iban', 'IBAN "$iban" ist ungültig (Modulo-97 Prüfsummenfehler oder falsches Format).');
    }
    if (iban.contains('\n') || iban.contains('\r')) {
      throw const EpcValidationException('iban', 'IBAN darf keine Zeilenumbrüche enthalten.');
    }

    if (bic != null && bic!.isNotEmpty) {
      if (bic!.length > 11) {
        throw const EpcValidationException('bic', 'BIC darf höchstens 11 Zeichen lang sein.');
      }
      if (bic!.contains('\n') || bic!.contains('\r')) {
        throw const EpcValidationException('bic', 'BIC darf keine Zeilenumbrüche enthalten.');
      }
    }

    if (amountInCents < 1 || amountInCents > 99999999999) {
      throw EpcValidationException(
        'amountInCents',
        'Betrag muss zwischen 0,01 € (1 Cent) und 999.999.999,99 € liegen (angegeben: $amountInCents Cents).',
      );
    }

    if (remittanceInformation.length > 140) {
      throw EpcValidationException(
        'remittanceInformation',
        'Verwendungszweck darf maximal 140 Zeichen lang sein (aktuell: ${remittanceInformation.length}).',
      );
    }
    if (remittanceInformation.contains('\n') || remittanceInformation.contains('\r')) {
      throw const EpcValidationException('remittanceInformation', 'Verwendungszweck darf keine Zeilenumbrüche enthalten.');
    }
  }

  /// Erzeugt die standardkonforme UTF-8 Byte-Zeichenkette für den GiroCode.
  String toEpcString() {
    validate();
    final cleanIban = iban.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final euros = amountInCents ~/ 100;
    final cents = amountInCents % 100;
    final amountStr = 'EUR$euros.${cents.toString().padLeft(2, '0')}';

    return [
      'BCD',
      '002',
      '1',
      'SCT',
      bic?.trim() ?? '',
      beneficiaryName.trim(),
      cleanIban,
      amountStr,
      '',
      '',
      remittanceInformation.trim(),
    ].join('\n');
  }
}
