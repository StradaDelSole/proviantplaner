/// PDF-Exportdienst für Einkaufsliste und Bordkassenabrechnung (Slice S8).
/// Verwendet Standard-PostScript-Schriften (Helvetica, Courier) für 100% Offline-Unterstützung.
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/services/receipt_file_service.dart';
import 'package:proviantplaner/features/kitty/data/kitty_service.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/kitty/domain/models/receipt_models.dart';
import 'package:proviantplaner/features/shopping_list/data/delivery_order_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'package:share_plus/share_plus.dart';

/// Einzelne benannte PDF-Datei.
class NamedPdf {
  final String fileName;
  final Uint8List bytes;

  const NamedPdf({
    required this.fileName,
    required this.bytes,
  });
}

/// Exception wenn ein Belegbild nicht geladen werden kann oder auf der Festplatte fehlt (Finding B).
class ReceiptImageMissingException implements Exception {
  final String expenseTitle;
  final int receiptId;
  final String filePath;

  const ReceiptImageMissingException({
    required this.expenseTitle,
    required this.receiptId,
    required this.filePath,
  });

  @override
  String toString() =>
      'ReceiptImageMissingException: Belegbild $receiptId für Ausgabe "$expenseTitle" fehlt ($filePath).';
}

/// Exception wenn ein Belegbild beschädigt ist und nicht gerendert werden kann (Finding B).
class ReceiptImageCorruptException implements Exception {
  final String expenseTitle;
  final int receiptId;
  final String cause;

  const ReceiptImageCorruptException({
    required this.expenseTitle,
    required this.receiptId,
    required this.cause,
  });

  @override
  String toString() =>
      'ReceiptImageCorruptException: Belegbild $receiptId für Ausgabe "$expenseTitle" ist beschädigt: $cause.';
}

/// Exception wenn ein einzelnes Belegbild größer als das Chunk-Limit ist (Finding F).
class PdfReceiptOversizedException implements Exception {
  final String expenseTitle;
  final int receiptId;
  final int byteSize;
  final int maxBytes;

  const PdfReceiptOversizedException({
    required this.expenseTitle,
    required this.receiptId,
    required this.byteSize,
    required this.maxBytes,
  });

  @override
  String toString() =>
      'PdfReceiptOversizedException: Belegbild $receiptId für "$expenseTitle" ist mit $byteSize Bytes größer als das Chunk-Limit ($maxBytes Bytes).';
}

/// Exception wenn ein generierter Belege-PDF-Chunk die 15-MB-Grenze überschreitet (Finding F).
class PdfChunkOversizedException implements Exception {
  final String fileName;
  final int byteSize;
  final int maxBytes;

  const PdfChunkOversizedException({
    required this.fileName,
    required this.byteSize,
    required this.maxBytes,
  });

  @override
  String toString() =>
      'PdfChunkOversizedException: PDF-Chunk "$fileName" ist mit $byteSize Bytes größer als das Limit von $maxBytes Bytes.';
}

/// Vollständiges Versandpaket für die Endabrechnung (RECEIPT1).
class SettlementPackage {
  final NamedPdf settlementPdf;
  final List<NamedPdf> receiptPdfs;

  const SettlementPackage({
    required this.settlementPdf,
    required this.receiptPdfs,
  });

  /// Alle enthaltenen PDF-Dateien.
  List<NamedPdf> get allPdfs => [settlementPdf, ...receiptPdfs];

  /// Gibt an, ob die Belege auf mehrere Dateien aufgeteilt werden mussten.
  bool get wasSplit => receiptPdfs.length > 1;
}

/// Aggregierte Zusammenfassung für den Export der Bordkassenabrechnung (FIX-B Finding E / S5).
class SettlementPdfSummary {

  final int totalExpensesCents;
  final int totalDepositsCents;
  final int? kittyCashCents;
  final List<MemberBalance> memberBalances;
  final List<PaymentTransfer> transfers;
  final KittyMember? treasurer;
  final KittyModel model;

  const SettlementPdfSummary({
    required this.totalExpensesCents,
    required this.totalDepositsCents,
    required this.kittyCashCents,
    required this.memberBalances,
    required this.transfers,
    this.treasurer,
    required this.model,
  });

  factory SettlementPdfSummary.fromTripKittyData(TripKittyData data) {
    final isShared = data.model == KittyModel.sharedKitty;
    final totalExpenses = data.sharedResult?.totalExpensesInCents ??
        data.individualResult?.totalExpensesInCents ??
        data.expenses.fold<int>(0, (sum, e) => sum + e.amountInCents);

    final totalDeposits = data.sharedResult?.totalDepositsInCents ??
        data.individualResult?.totalDepositsInCents ??
        data.deposits.fold<int>(0, (sum, d) => sum + d.amountInCents);

    final int? kittyCash;
    if (isShared) {
      kittyCash = data.sharedResult?.currentBalanceInCents ?? data.cashBalanceCents;
    } else {
      final depositsCount = data.deposits.length;
      final kittyPaidCount = data.expenses.where((e) => e.isPaidFromKitty).length;
      if (depositsCount > 0 || kittyPaidCount > 0) {
        kittyCash = data.individualResult?.currentBalanceInCents ?? data.cashBalanceCents;
      } else {
        // Im reinen Einzelabrechnungsmodus ohne Einzahlungen/Kassenausgaben existiert kein Kassenbestand
        kittyCash = null;
      }
    }

    return SettlementPdfSummary(
      totalExpensesCents: totalExpenses,
      totalDepositsCents: totalDeposits,
      kittyCashCents: kittyCash,
      memberBalances: data.balances,
      transfers: data.transfers,
      treasurer: data.treasurer,
      model: data.model,
    );
  }
}

/// Dienst zur Generierung und zum Drucken/Teilen von PDF-Dokumenten.
class PdfExportService {
  static int _exportNonce = 0;

  /// Generiert ein mehrseitiges PDF der Einkaufsliste, gegliedert nach Abteilungen.
  Future<Uint8List> generateShoppingListPdf({
    required Trip trip,
    required List<ShoppingListItemView> items,
    ShoppingStop? currentStop,
  }) async {
    final doc = pw.Document(
      title: 'Einkaufsliste - ${trip.name}',
      author: 'Proviantplaner - powered by HullQ',
    );

    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final fontMono = pw.Font.courier();

    final dateFormat = DateFormat('dd.MM.yyyy');
    final formattedDate = dateFormat.format(trip.startDate);

    // Gruppierung nach Abteilungen
    final departmentMap = <String, List<ShoppingListItemView>>{};
    for (final item in items) {
      if (!item.isSelected) continue;
      final deptName = item.department.displayName;
      departmentMap.putIfAbsent(deptName, () => []).add(item);
    }

    final stopSuffix = currentStop != null ? ' | Stopp: ${currentStop.name}' : '';
    final subtitleText = 'Start: $formattedDate | Dauer: ${trip.daysCount} Tage$stopSuffix';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          title: 'Einkaufsliste',
          tripName: trip.name,
          subtitle: subtitleText,
          fontBold: fontBold,
          fontRegular: fontRegular,
        ),
        footer: (context) => _buildFooter(context, fontRegular),
        build: (context) {
          final widgets = <pw.Widget>[];

          if (departmentMap.isEmpty) {
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 20),
                child: pw.Text('Keine Positionen ausgewählt.', style: pw.TextStyle(font: fontRegular)),
              ),
            );
            return widgets;
          }

          for (final entry in departmentMap.entries) {
            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  entry.key.toUpperCase(),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 11,
                    color: PdfColors.blueGrey800,
                  ),
                ),
              ),
            );

            for (final item in entry.value) {
              final effectivePackages = item.effectivePackages;
              final name = item.name;
              final unit = item.unit;
              final size = '${item.customPackageSize} $unit';

              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 12,
                        height: 12,
                        margin: const pw.EdgeInsets.only(right: 8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey700, width: 1),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                        ),
                      ),
                      pw.SizedBox(
                        width: 75,
                        child: pw.Text(
                          '$effectivePackages × $size'.trim(),
                          style: pw.TextStyle(font: fontMono, fontSize: 10),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          name,
                          style: pw.TextStyle(font: fontRegular, fontSize: 10),
                        ),
                      ),
                      if (item.isCustom)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: pw.Text(
                            'eigen',
                            style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }
          }

          return widgets;
        },
      ),
    );

    return doc.save();
  }

  /// Generiert ein PDF der Bordkassenabrechnung ("Wer zahlt wem", Salden, Ausgaben).
  Future<Uint8List> generateSettlementPdf({
    required TripKittyData data,
  }) async {
    final trip = data.trip;
    final summary = SettlementPdfSummary.fromTripKittyData(data);
    final currency = trip.currency;

    final doc = pw.Document(
      title: 'Bordkassenabrechnung - ${trip.name}',
      author: 'Proviantplaner - powered by HullQ',
    );

    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final fontMono = pw.Font.courier();
    final fontMonoBold = pw.Font.courierBold();

    final dateFormat = DateFormat('dd.MM.yyyy');
    final formattedDate = dateFormat.format(trip.startDate);

    final totalExpensesCents = summary.totalExpensesCents;
    final totalDepositsCents = summary.totalDepositsCents;
    final balanceCents = summary.kittyCashCents;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          title: 'Bordkassenabrechnung',
          tripName: trip.name,
          subtitle: 'Start: $formattedDate | Dauer: ${trip.daysCount} Tage | Modell: ${trip.kittyModel.rawValue}',
          fontBold: fontBold,
          fontRegular: fontRegular,
        ),
        footer: (context) => _buildFooter(context, fontRegular),
        build: (context) {
          final widgets = <pw.Widget>[];

          // 1. Zusammenfassung Bento Card
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              margin: const pw.EdgeInsets.only(bottom: 16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blueGrey200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                color: PdfColors.blueGrey50,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    label: 'Gesamtausgaben',
                    value: _formatCents(totalExpensesCents, currency),
                    fontBold: fontBold,
                    fontRegular: fontRegular,
                    fontMono: fontMonoBold,
                  ),
                  _buildSummaryItem(
                    label: 'Einzahlungen',
                    value: _formatCents(totalDepositsCents, currency),
                    fontBold: fontBold,
                    fontRegular: fontRegular,
                    fontMono: fontMonoBold,
                  ),
                  _buildSummaryItem(
                    label: balanceCents != null ? 'Kassen-Endstand' : 'Abrechnungsmodell',
                    value: balanceCents != null ? _formatCents(balanceCents, currency) : 'Einzeln',
                    fontBold: fontBold,
                    fontRegular: fontRegular,
                    fontMono: fontMonoBold,
                  ),
                ],
              ),
            ),
          );

          // 2. Wer zahlt wem (Minimale Überweisungen)
          widgets.add(_buildSectionTitle('WER ZAHLT WEM (AUSGLEICH)', fontBold));

          if (summary.transfers.isEmpty) {
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text('Alle Salden sind ausgeglichen. Keine Überweisungen nötig.',
                    style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.green800)),
              ),
            );
          } else {
            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Zahler', fontBold, isHeader: true),
                      _buildTableCell('Empfänger', fontBold, isHeader: true),
                      _buildTableCell('Betrag', fontBold, isHeader: true, alignRight: true),
                    ],
                  ),
                  for (final t in summary.transfers)
                    pw.TableRow(
                      children: [
                        _buildTableCell(t.fromMember.name, fontRegular),
                        _buildTableCell(t.toMember.name, fontRegular),
                        _buildTableCell(_formatCents(t.amountInCents, currency), fontMono, alignRight: true),
                      ],
                    ),
                ],
              ),
            );
          }

          widgets.add(pw.SizedBox(height: 16));

          // 3. Salden-Tabelle
          widgets.add(_buildSectionTitle('SALDEN-ÜBERSICHT', fontBold));

          widgets.add(
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Name', fontBold, isHeader: true),
                    _buildTableCell('Gezahlt / Auslagen', fontBold, isHeader: true, alignRight: true),
                    _buildTableCell('Kostenanteil', fontBold, isHeader: true, alignRight: true),
                    _buildTableCell('Saldo', fontBold, isHeader: true, alignRight: true),
                  ],
                ),
                for (final balance in summary.memberBalances)
                  pw.TableRow(
                    children: [
                      _buildTableCell(balance.member.name, fontRegular),
                      _buildTableCell(_formatCents(balance.paidInCents, currency), fontMono, alignRight: true),
                      _buildTableCell(_formatCents(balance.costShareInCents, currency), fontMono, alignRight: true),
                      _buildTableCell(
                        (balance.netBalanceInCents >= 0 ? '+' : '') + _formatCents(balance.netBalanceInCents, currency),
                        fontMonoBold,
                        alignRight: true,
                        textColor: balance.netBalanceInCents >= 0 ? PdfColors.green800 : PdfColors.red800,
                      ),
                    ],
                  ),
              ],
            ),
          );

          return widgets;
        },
      ),
    );

    return doc.save();
  }

  /// Generiert ein mehrseitiges PDF für eine Proviant-Bestellung an einen Lieferanten (Slice UX-B).
  Future<Uint8List> generateDeliveryOrderPdf({
    required Trip trip,
    required DeliveryOrder order,
    required List<ShoppingListItemView> items,
    bool isSupplement = false,
  }) async {
    final title = isSupplement ? 'Bestellung (Nachtrag)' : 'Proviantbestellung';
    final doc = pw.Document(
      title: '$title - ${trip.name}',
      author: 'Proviantplaner - powered by HullQ',
    );

    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final fontMono = pw.Font.courier();

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final deliveryTimeStr = order.deliveryDateTime != null
        ? 'Liefertermin: ${dateFormat.format(order.deliveryDateTime!)} Uhr'
        : 'Liefertermin: Nicht angegeben';

    // Gruppierung nach Abteilungen
    final departmentMap = <String, List<ShoppingListItemView>>{};
    for (final item in items) {
      final deptName = item.department.displayName;
      departmentMap.putIfAbsent(deptName, () => []).add(item);
    }

    final subtitleParts = <String>[];
    if (order.supplier != null) subtitleParts.add('Lieferant: ${order.supplier!.name}');
    if (order.marina != null && order.marina!.isNotEmpty) subtitleParts.add('Marina: ${order.marina}');
    if (order.berth != null && order.berth!.isNotEmpty) subtitleParts.add('Liegeplatz: ${order.berth}');
    if (order.boatName != null && order.boatName!.isNotEmpty) subtitleParts.add('Boot: ${order.boatName}');
    final subtitleText = '$deliveryTimeStr | ${subtitleParts.join(' | ')}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          title: title,
          tripName: trip.name,
          subtitle: subtitleText,
          fontBold: fontBold,
          fontRegular: fontRegular,
        ),
        footer: (context) => _buildFooter(context, fontRegular),
        build: (context) {
          final widgets = <pw.Widget>[];

          if (order.contactName != null && order.contactName!.isNotEmpty) {
            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  'Ansprechpartner: ${order.contactName}${order.contactPhone != null ? " (${order.contactPhone})" : ""}',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
              ),
            );
          }

          if (order.notes != null && order.notes!.isNotEmpty) {
            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(8),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.amber50,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'Hinweis für den Lieferanten: ${order.notes}',
                  style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.brown900),
                ),
              ),
            );
          }

          for (final entry in departmentMap.entries) {
            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 10, bottom: 4),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  entry.key.toUpperCase(),
                  style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blueGrey800),
                ),
              ),
            );

            for (final item in entry.value) {
              final size = item.effectivePackSize;
              final sizeFormatted = (size % 1 == 0) ? size.toInt().toString() : size.toStringAsFixed(1);
              final packUnit = item.variant?.pack.unit ?? item.unit;

              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 90,
                        child: pw.Text(
                          '${item.effectivePackages} × $sizeFormatted $packUnit',
                          style: pw.TextStyle(font: fontMono, fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          item.name,
                          style: pw.TextStyle(font: fontRegular, fontSize: 9),
                        ),
                      ),
                      if (item.isCustom)
                        pw.Text(
                          '(eigene Position)',
                          style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
                        ),
                    ],
                  ),
                ),
              );
            }
          }

          return widgets;
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader({
    required String title,
    required String tripName,
    required String subtitle,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey800, width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blueGrey900)),
              pw.Text(tripName, style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blueGrey700)),
              pw.SizedBox(height: 2),
              pw.Text(subtitle, style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          pw.Text(
            'PROVIANTPLANER',
            style: pw.TextStyle(font: fontBold, fontSize: 10, letterSpacing: 1.2, color: PdfColors.blueGrey400),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, pw.Font fontRegular) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Erstellt mit Proviantplaner - powered by HullQ',
            style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Seite ${context.pageNumber} von ${context.pagesCount}',
            style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(font: fontBold, fontSize: 10, letterSpacing: 0.5, color: PdfColors.blueGrey800),
      ),
    );
  }

  pw.Widget _buildSummaryItem({
    required String label,
    required String value,
    required pw.Font fontBold,
    required pw.Font fontRegular,
    required pw.Font fontMono,
  }) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(font: fontMono, fontSize: 13, color: PdfColors.blueGrey900)),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    bool alignRight = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 9 : 8.5,
          color: textColor ?? (isHeader ? PdfColors.black : PdfColors.grey800),
        ),
      ),
    );
  }

  String _formatCents(int cents, [String currency = 'EUR']) {
    final whole = cents ~/ 100;
    final rest = (cents % 100).abs();
    return '$whole,${rest.toString().padLeft(2, '0')} $currency';
  }

  /// Druckt oder teilt das PDF-Dokument über Standard-Systemdialoge.
  Future<void> shareOrPrintPdf({
    required Uint8List bytes,
    required String filename,
    required String subject,
  }) async {
    await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
      subject: subject,
    );
  }

  /// Baut und rendert ein Belege-PDF-Dokument für die übergebenen [_ReceiptPageEntry]-Einträge.
  Future<Uint8List> _renderReceiptDocument({
    required String tripName,
    required List<_ReceiptPageEntry> chunkEntries,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    required pw.Font fontMono,
    required pw.Font fontMonoBold,
    required DateFormat dateFormat,
  }) async {
    final doc = pw.Document(
      title: 'Belege - $tripName',
      author: 'Proviantplaner - powered by HullQ',
    );

    for (final entry in chunkEntries) {
      final pw.MemoryImage memImage;
      try {
        memImage = pw.MemoryImage(entry.imageBytes);
      } catch (e) {
        throw ReceiptImageCorruptException(
          expenseTitle: entry.expense.title,
          receiptId: entry.receipt.id,
          cause: e.toString(),
        );
      }

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          tripName,
                          style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.blueGrey800),
                        ),
                        pw.Text(
                          'Beleg zur Ausgabe: ${entry.expense.title}',
                          style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Text(
                      dateFormat.format(entry.expense.createdAt),
                      style: pw.TextStyle(font: fontMono, fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blueGrey50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: PdfColors.blueGrey200, width: 0.5),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Kategorie: ${entry.expense.category.displayName}',
                        style: pw.TextStyle(font: fontRegular, fontSize: 9.5),
                      ),
                      pw.Text(
                        'Bezahlt von: ${entry.payerName}',
                        style: pw.TextStyle(font: fontRegular, fontSize: 9.5),
                      ),
                      pw.Text(
                        'Betrag: ${_formatCents(entry.expense.amountInCents, entry.expense.currency)}',
                        style: pw.TextStyle(font: fontMonoBold, fontSize: 10),
                      ),
                      if (entry.totalPhotos > 1)
                        pw.Text(
                          'Foto ${entry.photoIndex} von ${entry.totalPhotos}',
                          style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey600),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Expanded(
                  child: pw.Container(
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Image(memImage, fit: pw.BoxFit.contain),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Proviantplaner - powered by HullQ',
                      style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey500),
                    ),
                    pw.Text(
                      'Seite ${context.pageNumber} von ${context.pagesCount}',
                      style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey500),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return doc.save();
  }

  /// Generiert ein oder mehrere Belege-PDFs (RECEIPT1 & R4).
  /// Falls entweder die Rohbild-Summe ([maxBytesPerChunk]) oder das tatsächlich erzeugte
  /// PDF-Dokument ([maxPdfBytes], Standard: 15 MB) das Limit überschreitet, wird die
  /// Sammlung automatisch und ohne fehlende oder doppelte Seiten in nummerierte Dateien
  /// (`Belege_1.pdf`, `Belege_2.pdf`, ...) aufgeteilt.
  /// Überschreitet bereits ein einzelner, nicht weiter teilbarer Beleg für sich allein
  /// [maxPdfBytes], schlägt der Export mit [PdfChunkOversizedException] bzw. [PdfReceiptOversizedException] fehl.
  Future<List<NamedPdf>> generateReceiptsPdfs({
    required TripKittyData data,
    required ReceiptFileService receiptFileService,
    int maxBytesPerChunk = 15 * 1024 * 1024,
    int maxPdfBytes = 15 * 1024 * 1024,
  }) async {
    final expensesWithReceipts = data.expenses.where((e) => e.receipts.isNotEmpty).toList();
    if (expensesWithReceipts.isEmpty) {
      return const [];
    }

    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final fontMono = pw.Font.courier();
    final fontMonoBold = pw.Font.courierBold();
    final dateFormat = DateFormat('dd.MM.yyyy');

    // Sammle alle Beleg-Einträge mit ihren zugehörigen Daten
    final allReceiptEntries = <_ReceiptPageEntry>[];
    for (final exp in expensesWithReceipts) {
      final payerName = exp.isPaidFromKitty
          ? 'Bordkasse'
          : (data.members.where((m) => m.id == exp.paidByMemberId).firstOrNull?.name ?? 'Crew');

      for (var i = 0; i < exp.receipts.length; i++) {
        final receipt = exp.receipts[i];
        final bytes = await receiptFileService.readReceiptBytes(receipt.filePath);
        if (bytes == null || bytes.isEmpty) {
          throw ReceiptImageMissingException(
            expenseTitle: exp.title,
            receiptId: receipt.id,
            filePath: receipt.filePath,
          );
        }
        if (bytes.length > maxPdfBytes) {
          throw PdfReceiptOversizedException(
            expenseTitle: exp.title,
            receiptId: receipt.id,
            byteSize: bytes.length,
            maxBytes: maxPdfBytes,
          );
        }
        allReceiptEntries.add(
          _ReceiptPageEntry(
            expense: exp,
            receipt: receipt,
            imageBytes: bytes,
            photoIndex: i + 1,
            totalPhotos: exp.receipts.length,
            payerName: payerName,
          ),
        );
      }
    }

    if (allReceiptEntries.isEmpty) {
      return const [];
    }

    // 1. Vor-Chunking anhand der Rohbild-Bytes (maxBytesPerChunk)
    final initialChunks = <List<_ReceiptPageEntry>>[];
    var currentChunk = <_ReceiptPageEntry>[];
    var currentChunkBytes = 0;

    for (final entry in allReceiptEntries) {
      if (currentChunk.isNotEmpty && (currentChunkBytes + entry.imageBytes.length > maxBytesPerChunk)) {
        initialChunks.add(currentChunk);
        currentChunk = [entry];
        currentChunkBytes = entry.imageBytes.length;
      } else {
        currentChunk.add(entry);
        currentChunkBytes += entry.imageBytes.length;
      }
    }
    if (currentChunk.isNotEmpty) {
      initialChunks.add(currentChunk);
    }

    // 2. Rendern & automatisches Nach-Splitten anhand der tatsächlichen PDF-Bytes (maxPdfBytes, R4)
    final renderedChunksBytes = <Uint8List>[];

    Future<void> renderAndSplitIfNeeded(List<_ReceiptPageEntry> entries) async {
      final bytes = await _renderReceiptDocument(
        tripName: data.trip.name,
        chunkEntries: entries,
        fontRegular: fontRegular,
        fontBold: fontBold,
        fontMono: fontMono,
        fontMonoBold: fontMonoBold,
        dateFormat: dateFormat,
      );

      if (bytes.length <= maxPdfBytes) {
        renderedChunksBytes.add(bytes);
        return;
      }

      if (entries.length == 1) {
        throw PdfChunkOversizedException(
          fileName: 'Belege.pdf',
          byteSize: bytes.length,
          maxBytes: maxPdfBytes,
        );
      }

      // Finde das größte Präfix (mindestens 1 Eintrag), dessen gerendertes PDF <= maxPdfBytes ist
      int low = 1;
      int high = entries.length - 1;
      int bestEnd = 0;
      Uint8List? bestBytes;

      while (low <= high) {
        final mid = (low + high) ~/ 2;
        final candidateEntries = entries.sublist(0, mid);
        final candidateBytes = await _renderReceiptDocument(
          tripName: data.trip.name,
          chunkEntries: candidateEntries,
          fontRegular: fontRegular,
          fontBold: fontBold,
          fontMono: fontMono,
          fontMonoBold: fontMonoBold,
          dateFormat: dateFormat,
        );
        if (candidateBytes.length <= maxPdfBytes) {
          bestEnd = mid;
          bestBytes = candidateBytes;
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      }

      if (bestEnd == 0 || bestBytes == null) {
        // Selbst der allererste einzelne Beleg überschreitet als gerendertes 1-Seiten-PDF maxPdfBytes
        final singleBytes = await _renderReceiptDocument(
          tripName: data.trip.name,
          chunkEntries: [entries.first],
          fontRegular: fontRegular,
          fontBold: fontBold,
          fontMono: fontMono,
          fontMonoBold: fontMonoBold,
          dateFormat: dateFormat,
        );
        throw PdfChunkOversizedException(
          fileName: 'Belege.pdf',
          byteSize: singleBytes.length,
          maxBytes: maxPdfBytes,
        );
      }

      renderedChunksBytes.add(bestBytes);
      await renderAndSplitIfNeeded(entries.sublist(bestEnd));
    }

    for (final chunkEntries in initialChunks) {
      await renderAndSplitIfNeeded(chunkEntries);
    }

    final isMultiChunk = renderedChunksBytes.length > 1;
    final resultList = <NamedPdf>[];
    for (var i = 0; i < renderedChunksBytes.length; i++) {
      final chunkNum = i + 1;
      final fileName = isMultiChunk ? 'Belege_$chunkNum.pdf' : 'Belege.pdf';
      resultList.add(NamedPdf(fileName: fileName, bytes: renderedChunksBytes[i]));
    }

    return resultList;
  }

  /// Erzeugt das vollständige Abrechnungspaket (RECEIPT1).
  Future<SettlementPackage> generateSettlementPackage({
    required TripKittyData data,
    required ReceiptFileService receiptFileService,
    int maxBytesPerChunk = 15 * 1024 * 1024,
    int maxPdfBytes = 15 * 1024 * 1024,
    String settlementFilename = 'Abrechnung.pdf',
  }) async {
    final settlementBytes = await generateSettlementPdf(data: data);
    final settlementPdf = NamedPdf(fileName: settlementFilename, bytes: settlementBytes);

    final receiptPdfs = await generateReceiptsPdfs(
      data: data,
      receiptFileService: receiptFileService,
      maxBytesPerChunk: maxBytesPerChunk,
      maxPdfBytes: maxPdfBytes,
    );

    return SettlementPackage(
      settlementPdf: settlementPdf,
      receiptPdfs: receiptPdfs,
    );
  }

  /// Bereinigt frühere temporäre `settlement_export_*`-Verzeichnisse im Temp-Ordner (R4).
  /// Dadurch bleiben die Dateien des aktuellen Share-Vorgangs für das native OS-Share-Sheet
  /// verfügbar, während frühere Exporte deterministisch aufgeräumt werden und sich nicht ansammeln.
  Future<void> cleanupTemporaryExportDirectories({
    Directory? baseTempDir,
    Duration maxAge = Duration.zero,
    DateTime? now,
  }) async {
    final tempDir = baseTempDir ?? await getTemporaryDirectory();
    if (!await tempDir.exists()) return;

    final effectiveNow = now ?? DateTime.now();
    await for (final entity in tempDir.list(recursive: false)) {
      if (entity is Directory && p.basename(entity.path).startsWith('settlement_export_')) {
        try {
          if (maxAge <= Duration.zero) {
            await entity.delete(recursive: true);
          } else {
            final stat = await entity.stat();
            if (effectiveNow.difference(stat.modified) >= maxAge) {
              await entity.delete(recursive: true);
            }
          }
        } catch (_) {}
      }
    }
  }

  /// Schreibt das Abrechnungspaket temporär auf das Dateisystem, bereinigt vorherige
  /// temporäre Export-Verzeichnisse und öffnet den nativen Share-/Mail-Composer über `share_plus` (RECEIPT1 & R4).
  Future<Directory> prepareSettlementExportDirectory({
    required SettlementPackage package,
    Future<Directory> Function()? tempDirProvider,
    Duration cleanupMaxAge = Duration.zero,
  }) async {
    final tempDir = await (tempDirProvider ?? getTemporaryDirectory)();
    await cleanupTemporaryExportDirectories(
      baseTempDir: tempDir,
      maxAge: cleanupMaxAge,
    );

    _exportNonce++;
    final exportDir = Directory(
      p.join(tempDir.path, 'settlement_export_${DateTime.now().millisecondsSinceEpoch}_$_exportNonce'),
    );
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    for (final pdf in package.allPdfs) {
      final file = File(p.join(exportDir.path, pdf.fileName));
      await file.writeAsBytes(pdf.bytes, flush: true);
    }

    return exportDir;
  }

  /// Schreibt das Abrechnungspaket temporär auf das Dateisystem und öffnet
  /// den nativen Share-/Mail-Composer über `share_plus` (RECEIPT1 & R4).
  Future<void> shareSettlementPackage({
    required SettlementPackage package,
    required String subject,
    required String bodyText,
    Future<Directory> Function()? tempDirProvider,
  }) async {
    final exportDir = await prepareSettlementExportDirectory(
      package: package,
      tempDirProvider: tempDirProvider,
    );

    final xFiles = <XFile>[];
    for (final pdf in package.allPdfs) {
      final file = File(p.join(exportDir.path, pdf.fileName));
      xFiles.add(XFile(file.path, name: pdf.fileName, mimeType: 'application/pdf'));
    }

    await Share.shareXFiles(
      xFiles,
      subject: subject,
      text: bodyText,
    );
  }
}

class _ReceiptPageEntry {
  final KittyExpense expense;
  final ExpenseReceiptItem receipt;
  final Uint8List imageBytes;
  final int photoIndex;
  final int totalPhotos;
  final String payerName;

  _ReceiptPageEntry({
    required this.expense,
    required this.receipt,
    required this.imageBytes,
    required this.photoIndex,
    required this.totalPhotos,
    required this.payerName,
  });
}
