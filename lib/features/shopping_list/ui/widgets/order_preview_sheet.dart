/// Vorschau- und Freigabe-Sheet für Lieferbestellungen (Slice UX-B / UX-Konzept 2.4a).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/services/pdf_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/delivery_order_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/delivery_config_sheet.dart';

class OrderPreviewSheet extends ConsumerStatefulWidget {
  final Trip trip;
  final ShoppingStop stop;
  final DeliveryOrder order;
  final List<ShoppingListItemView> items;
  final VoidCallback? onOrderSent;

  const OrderPreviewSheet({
    super.key,
    required this.trip,
    required this.stop,
    required this.order,
    required this.items,
    this.onOrderSent,
  });

  static Future<void> show(
    BuildContext context, {
    required Trip trip,
    required ShoppingStop stop,
    required DeliveryOrder order,
    required List<ShoppingListItemView> items,
    VoidCallback? onOrderSent,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => OrderPreviewSheet(
        trip: trip,
        stop: stop,
        order: order,
        items: items,
        onOrderSent: onOrderSent,
      ),
    );
  }

  @override
  ConsumerState<OrderPreviewSheet> createState() => _OrderPreviewSheetState();
}

class _OrderPreviewSheetState extends ConsumerState<OrderPreviewSheet> {
  late DeliveryOrder _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  Future<void> _editDeliveryConfig() async {
    final updated = await DeliveryConfigSheet.show(
      context,
      tripId: widget.trip.id,
      stopId: widget.stop.id,
      stopName: widget.stop.name,
      initialOrder: _currentOrder,
      defaultDate: _currentOrder.deliveryDateTime ?? widget.trip.startDate,
    );
    if (updated != null && mounted) {
      setState(() => _currentOrder = updated);
    }
  }

  Future<void> _shareWhatsApp() async {
    final text = _currentOrder.formatOrderText(
      tripName: widget.trip.name,
      items: widget.items,
      isSupplement: _currentOrder.orderedAt != null,
    );
    final phone = _currentOrder.supplier?.phone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
    final urlStr = phone.isNotEmpty
        ? 'https://wa.me/$phone?text=${Uri.encodeComponent(text)}'
        : 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await Share.share(text, subject: 'Bestellung: ${widget.trip.name}');
    }
  }

  Future<void> _shareText() async {
    final text = _currentOrder.formatOrderText(
      tripName: widget.trip.name,
      items: widget.items,
      isSupplement: _currentOrder.orderedAt != null,
    );
    await Share.share(text, subject: 'Bestellung: ${widget.trip.name}');
  }

  Future<void> _sharePdf() async {
    final pdfService = ref.read(pdfExportServiceProvider);
    final pdfBytes = await pdfService.generateDeliveryOrderPdf(
      trip: widget.trip,
      order: _currentOrder,
      items: widget.items,
      isSupplement: _currentOrder.orderedAt != null,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Bestellung_${widget.stop.name.replaceAll(' ', '_')}.pdf',
    );
  }

  Future<void> _markAsSent() async {
    await ref.read(deliveryOrderServiceProvider).markAsOrdered(
          widget.stop.id,
          itemCount: widget.items.length,
        );
    ref.invalidate(stopDeliveryOrderProvider(widget.stop.id));
    widget.onOrderSent?.call();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bestellung als gesendet markiert.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd.MM.yyyy HH:mm');

    // Gruppierung nach Abteilung
    final byDept = <String, List<ShoppingListItemView>>{};
    for (final it in widget.items) {
      byDept.putIfAbsent(it.department.displayName, () => []).add(it);
    }

    final hasSentBefore = _currentOrder.orderedAt != null;
    final countChanged = hasSentBefore && _currentOrder.lastOrderedItemCount != widget.items.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bestellung prüfen & senden'),
            Text(
              '${widget.trip.name} · Stopp: ${widget.stop.name}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          // Lieferdetails Card
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lieferdetails',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Bearbeiten'),
                        onPressed: _editDeliveryConfig,
                      ),
                    ],
                  ),
                  const Divider(),
                  if (_currentOrder.deliveryDateTime != null)
                    _buildInfoRow('Liefertermin', '${df.format(_currentOrder.deliveryDateTime!)} Uhr'),
                  if (_currentOrder.supplier != null)
                    _buildInfoRow('Lieferant', _currentOrder.supplier!.name),
                  if (_currentOrder.marina != null && _currentOrder.marina!.isNotEmpty)
                    _buildInfoRow('Marina', _currentOrder.marina!),
                  if (_currentOrder.berth != null && _currentOrder.berth!.isNotEmpty)
                    _buildInfoRow('Liegeplatz', _currentOrder.berth!),
                  if (_currentOrder.boatName != null && _currentOrder.boatName!.isNotEmpty)
                    _buildInfoRow('Boot', _currentOrder.boatName!),
                  if (_currentOrder.contactName != null && _currentOrder.contactName!.isNotEmpty)
                    _buildInfoRow(
                      'Ansprechpartner',
                      '${_currentOrder.contactName}${_currentOrder.contactPhone != null ? " (${_currentOrder.contactPhone})" : ""}',
                    ),
                  if (_currentOrder.notes != null && _currentOrder.notes!.isNotEmpty)
                    _buildInfoRow('Hinweise', _currentOrder.notes!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status-Banner wenn bereits gesendet
          if (hasSentBefore)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: countChanged ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        countChanged ? Icons.warning_amber : Icons.check_circle,
                        color: countChanged ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bereits bestellt am ${df.format(_currentOrder.orderedAt!)} Uhr',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: countChanged ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  if (countChanged) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Seit der letzten Bestellung hat sich die Anzahl der Positionen geändert (${_currentOrder.lastOrderedItemCount} ➔ ${widget.items.length}). Dieser Versand wird als Nachtrag gewertet.',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onErrorContainer),
                    ),
                  ],
                ],
              ),
            ),

          // Teilen Aktionen (WhatsApp als 1. Option laut FEEDBACK_R2 v0.3)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text('Per WhatsApp senden'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
              onPressed: _shareWhatsApp,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Text teilen'),
                  onPressed: _shareText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF teilen'),
                  onPressed: _sharePdf,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Enthaltene Positionen (${widget.items.length})',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Artikelliste gruppiert nach Abteilungen
          for (final entry in byDept.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                entry.key.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entry.value.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final it = entry.value[i];
                  final size = it.effectivePackSize;
                  final sizeFormatted = (size % 1 == 0) ? size.toInt().toString() : size.toStringAsFixed(1);
                  final packUnit = it.variant?.pack.unit ?? it.unit;
                  return ListTile(
                    dense: true,
                    title: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Text(
                      '${it.effectivePackages} × $sizeFormatted $packUnit',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            icon: const Icon(Icons.send_rounded),
            label: Text(hasSentBefore ? 'Bestellung erneut als gesendet markieren' : 'Bestellung als gesendet markieren'),
            onPressed: _markAsSent,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
