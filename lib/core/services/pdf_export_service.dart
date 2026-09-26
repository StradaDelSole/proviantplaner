/// PDF-Exportdienst für Einkaufsliste und Bordkassenabrechnung (Slice S8).
/// Verwendet Standard-PostScript-Schriften (Helvetica, Courier) für 100% Offline-Unterstützung.
library;

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/features/kitty/data/kitty_service.dart';
import 'package:proviantplaner/features/shopping_list/data/delivery_order_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';

/// Dienst zur Generierung und zum Drucken/Teilen von PDF-Dokumenten.
class PdfExportService {
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

    final totalExpensesCents = data.expenses.fold<int>(0, (sum, e) => sum + e.amountInCents);
    final totalDepositsCents = data.deposits.fold<int>(0, (sum, d) => sum + d.amountInCents);
    final balanceCents = totalDepositsCents - totalExpensesCents;

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
                    value: _formatCents(totalExpensesCents),
                    fontBold: fontBold,
                    fontRegular: fontRegular,
                    fontMono: fontMonoBold,
                  ),
                  _buildSummaryItem(
                    label: 'Einzahlungen',
                    value: _formatCents(totalDepositsCents),
                    fontBold: fontBold,
                    fontRegular: fontRegular,
                    fontMono: fontMonoBold,
                  ),
                  _buildSummaryItem(
                    label: 'Kassen-Endstand',
                    value: _formatCents(balanceCents),
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

          if (data.transfers.isEmpty) {
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
                  for (final t in data.transfers)
                    pw.TableRow(
                      children: [
                        _buildTableCell(t.fromMember.name, fontRegular),
                        _buildTableCell(t.toMember.name, fontRegular),
                        _buildTableCell(_formatCents(t.amountInCents), fontMono, alignRight: true),
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
                for (final balance in data.balances)
                  pw.TableRow(
                    children: [
                      _buildTableCell(balance.member.name, fontRegular),
                      _buildTableCell(_formatCents(balance.paidInCents), fontMono, alignRight: true),
                      _buildTableCell(_formatCents(balance.costShareInCents), fontMono, alignRight: true),
                      _buildTableCell(
                        (balance.netBalanceInCents >= 0 ? '+' : '') + _formatCents(balance.netBalanceInCents),
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

  String _formatCents(int cents) {
    final euros = cents ~/ 100;
    final rest = (cents % 100).abs();
    return '$euros,${rest.toString().padLeft(2, '0')} EUR';
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
}
