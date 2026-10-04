import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Zentraler Dienst für lokalisierte Formatierung von Zahlen, Währung und Datum (Slice S9).
abstract final class AppFormatters {
  /// Ermittelt den effektiven Locale-Tag (z. B. 'de', 'en', 'fr').
  static String _resolveLocale(BuildContext context, String? overrideLocale) {
    if (overrideLocale != null && overrideLocale.isNotEmpty) {
      return overrideLocale;
    }
    return Localizations.localeOf(context).languageCode;
  }

  /// Formatiert einen Cent-Betrag als Währungsstring (z. B. 1250 Cent -> "12,50 €" oder "€12.50").
  static String formatCurrency(
    BuildContext context,
    int amountInCents, {
    String? locale,
  }) {
    final effectiveLocale = _resolveLocale(context, locale);
    final euros = amountInCents / 100.0;
    final format = NumberFormat.currency(
      locale: effectiveLocale,
      symbol: '€',
      decimalDigits: (amountInCents % 100 == 0) ? 0 : 2,
    );
    return format.format(euros);
  }

  /// Formatiert eine Dezimalzahl nach den Regeln der jeweiligen Sprache (Komma vs. Punkt).
  static String formatDecimal(
    BuildContext context,
    double value, {
    String? locale,
    int? decimalDigits,
  }) {
    final effectiveLocale = _resolveLocale(context, locale);
    final format = NumberFormat.decimalPattern(effectiveLocale);
    if (decimalDigits != null) {
      format.minimumFractionDigits = decimalDigits;
      format.maximumFractionDigits = decimalDigits;
    } else if (value % 1 == 0) {
      format.maximumFractionDigits = 0;
    } else {
      format.maximumFractionDigits = 2;
    }
    return format.format(value);
  }

  /// Formatiert ein Datum kurz (z. B. "04.10.2026" bzw. "10/4/2026").
  static String formatDate(
    BuildContext context,
    DateTime date, {
    String? locale,
  }) {
    final effectiveLocale = _resolveLocale(context, locale);
    final format = DateFormat.yMd(effectiveLocale);
    return format.format(date);
  }

  /// Formatiert ein Datum lang (z. B. "4. Oktober 2026").
  static String formatDateLong(
    BuildContext context,
    DateTime date, {
    String? locale,
  }) {
    final effectiveLocale = _resolveLocale(context, locale);
    final format = DateFormat.yMMMMd(effectiveLocale);
    return format.format(date);
  }
}
