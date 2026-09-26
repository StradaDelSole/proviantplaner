/// Vollbild-Sheet zum Abhaken einer empfangenen Lieferung (Slice UX-B / UX-Konzept 2.4a).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/features/shopping_list/data/delivery_order_service.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';

class DeliveryReceivedSheet extends ConsumerStatefulWidget {
  final Trip trip;
  final ShoppingStop stop;
  final List<ShoppingStop> allStops;
  final List<ShoppingListItemView> items;
  final VoidCallback? onReceived;

  const DeliveryReceivedSheet({
    super.key,
    required this.trip,
    required this.stop,
    required this.allStops,
    required this.items,
    this.onReceived,
  });

  static Future<void> show(
    BuildContext context, {
    required Trip trip,
    required ShoppingStop stop,
    required List<ShoppingStop> allStops,
    required List<ShoppingListItemView> items,
    VoidCallback? onReceived,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DeliveryReceivedSheet(
        trip: trip,
        stop: stop,
        allStops: allStops,
        items: items,
        onReceived: onReceived,
      ),
    );
  }

  @override
  ConsumerState<DeliveryReceivedSheet> createState() => _DeliveryReceivedSheetState();
}

class _DeliveryReceivedSheetState extends ConsumerState<DeliveryReceivedSheet> {
  final Set<int> _receivedItemIds = {};

  @override
  void initState() {
    super.initState();
    // Standardmäßig alle als geliefert initialisieren
    for (final it in widget.items) {
      _receivedItemIds.add(it.item.id);
    }
  }

  Future<void> _moveMissingToStop(ShoppingListItemView it) async {
    final otherStops = widget.allStops.where((s) => s.id != widget.stop.id).toList();
    if (otherStops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine weiteren Stopps vorhanden.')),
      );
      return;
    }

    final targetStop = await showDialog<ShoppingStop>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('${it.name}: Auf welchen Stopp verschieben?'),
        children: otherStops
            .map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(s),
                  child: Text('Tag ${s.dayNumber} · ${s.name}'),
                ))
            .toList(),
      ),
    );

    if (targetStop != null && mounted) {
      await ref.read(shoppingListServiceProvider).movePackagesBetweenStops(
            it: it,
            fromStopId: widget.stop.id,
            toStopId: targetStop.id,
            packagesCount: it.effectivePackages,
          );
      ref.invalidate(tripShoppingListProvider(widget.trip.id));
      setState(() => _receivedItemIds.remove(it.item.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${it.name} auf Stopp "${targetStop.name}" verschoben.')),
        );
      }
    }
  }

  Future<void> _finishDelivery() async {
    // Lieferung als empfangen markieren
    await ref.read(deliveryOrderServiceProvider).markAsDelivered(widget.stop.id);
    ref.invalidate(stopDeliveryOrderProvider(widget.stop.id));
    widget.onReceived?.call();

    if (!mounted) return;
    Navigator.of(context).pop();

    // Angebot: "Jetzt einlagern?" (UX-Konzept 2.4a & 2.5)
    final storeNow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lieferung erhalten'),
        content: const Text('Möchtet ihr die gelieferten Vorräte jetzt direkt einlagern?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Später'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Jetzt einlagern'),
          ),
        ],
      ),
    );

    if (storeNow == true && mounted) {
      context.push('/trips/${widget.trip.id}/storage');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lieferung prüfen'),
            Text(
              'Stopp: ${widget.stop.name}',
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
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: widget.items.length,
        itemBuilder: (ctx, i) {
          final it = widget.items[i];
          final isChecked = _receivedItemIds.contains(it.item.id);
          final size = it.effectivePackSize;
          final sizeFormatted = (size % 1 == 0) ? size.toInt().toString() : size.toStringAsFixed(1);
          final packUnit = it.variant?.pack.unit ?? it.unit;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Checkbox(
                value: isChecked,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _receivedItemIds.add(it.item.id);
                    } else {
                      _receivedItemIds.remove(it.item.id);
                    }
                  });
                },
              ),
              title: Text(
                it.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: isChecked ? null : TextDecoration.lineThrough,
                  color: isChecked ? theme.colorScheme.onSurface : theme.colorScheme.error,
                ),
              ),
              subtitle: Text('${it.effectivePackages} × $sizeFormatted $packUnit'),
              trailing: !isChecked
                  ? TextButton.icon(
                      icon: const Icon(Icons.redo, size: 16),
                      label: const Text('Verschieben'),
                      onPressed: () => _moveMissingToStop(it),
                    )
                  : const Chip(
                      label: Text('OK', style: TextStyle(fontSize: 12)),
                      padding: EdgeInsets.zero,
                    ),
            ),
          );
        },
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
            icon: const Icon(Icons.done_all),
            label: const Text('Lieferung bestätigen'),
            onPressed: _finishDelivery,
          ),
        ),
      ),
    );
  }
}
