/// Einheitliches Zeilen-Widget für Vorratspositionen (Slice UX-B / UX-Konzept 2.4).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';

class ShoppingListItemRow extends ConsumerStatefulWidget {
  final TripShoppingListData data;
  final ShoppingListItemView item;

  const ShoppingListItemRow({
    super.key,
    required this.data,
    required this.item,
  });

  @override
  ConsumerState<ShoppingListItemRow> createState() => _ShoppingListItemRowState();
}

class _ShoppingListItemRowState extends ConsumerState<ShoppingListItemRow> {
  bool _isEditingInline = false;
  late final TextEditingController _inlineController;

  @override
  void initState() {
    super.initState();
    _inlineController = TextEditingController(text: widget.item.effectivePackages.toString());
  }

  @override
  void didUpdateWidget(covariant ShoppingListItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingInline) {
      _inlineController.text = widget.item.effectivePackages.toString();
    }
  }

  @override
  void dispose() {
    _inlineController.dispose();
    super.dispose();
  }

  Future<void> _submitInlineQuantity(String val) async {
    setState(() => _isEditingInline = false);
    final count = int.tryParse(val.trim());
    if (count != null && count >= 0) {
      await ref.read(shoppingListServiceProvider).setPackages(widget.item, count);
      ref.invalidate(tripShoppingListProvider(widget.data.trip.id));
    }
  }

  Future<void> _applyWaterBonus(double factor) async {
    final current = widget.item.effectivePackages;
    final bonus = (current * factor).ceil();
    final newCount = current + (bonus > 0 ? bonus : 1);
    await ref.read(shoppingListServiceProvider).setPackages(widget.item, newCount);
    ref.invalidate(tripShoppingListProvider(widget.data.trip.id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wassermenge auf $newCount Packungen erhöht (+${(factor * 100).toInt()} %)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showStopSelection(BuildContext context) async {
    final stops = widget.data.stops;
    if (stops.isEmpty) return;

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stopp wählen: ${widget.item.name}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stops.map((stop) {
                  return ActionChip(
                    avatar: const Icon(Icons.storefront_outlined, size: 16),
                    label: Text('Tag ${stop.dayNumber} · ${stop.name}'),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await ref.read(shoppingListServiceProvider).allocateToStop(
                            tripId: widget.data.trip.id,
                            listItemId: widget.item.item.id,
                            shoppingStopId: stop.id,
                            packages: widget.item.effectivePackages,
                          );
                      ref.invalidate(tripShoppingListProvider(widget.data.trip.id));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${widget.item.name} zu "${stop.name}" zugeordnet.')),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final isOnList = item.isOnList;
    final isWater = item.id.contains('water') ||
        item.name.toLowerCase().contains('wasser') ||
        item.categoryId == 'wasser';

    return Dismissible(
      key: ValueKey('item_swipe_${item.item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        await _showStopSelection(context);
        return false; // Nie aus der Liste löschen, nur Zuordnungs-Menü öffnen
      },
      background: Container(
        color: theme.colorScheme.primaryContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Stopp wählen',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.storefront_outlined, color: theme.colorScheme.onPrimaryContainer),
          ],
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text-Spalte (Name, Vorschlag / Bedarf, Badges)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.data.trip.fridgeCapacity <= 0 && item.isCooled) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'braucht Kühlung',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      if (!isOnList) ...[
                        Text(
                          item.suggestionDisplay,
                          style: theme.proviantTypography.numberSmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Text(
                              item.demandDisplay,
                              style: theme.proviantTypography.numberSmall.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${item.shortSuggestionDisplay})',
                              style: theme.proviantTypography.numberSmall.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Aktions- / Mengen-Spalte
                if (!isOnList) ...[
                  FilledButton.tonal(
                    onPressed: () async {
                      await ref.read(shoppingListServiceProvider).adoptItem(
                            tripId: widget.data.trip.id,
                            listItemId: item.item.id,
                          );
                      ref.invalidate(tripShoppingListProvider(widget.data.trip.id));
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(90, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 18),
                        SizedBox(width: 4),
                        Text('übernehmen'),
                      ],
                    ),
                  ),
                ] else ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                            tooltip: 'Menge verringern',
                            onPressed: () async {
                              await ref.read(shoppingListServiceProvider).decrementPackages(item);
                              ref.invalidate(tripShoppingListProvider(widget.data.trip.id));
                            },
                          ),
                          if (_isEditingInline) ...[
                            SizedBox(
                              width: 56,
                              height: 44,
                              child: TextField(
                                controller: _inlineController,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: theme.proviantTypography.numberMedium.copyWith(fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: _submitInlineQuantity,
                                onEditingComplete: () => _submitInlineQuantity(_inlineController.text),
                              ),
                            ),
                          ] else ...[
                            InkWell(
                              key: ValueKey('qty_inkwell_${item.item.id}'),
                              borderRadius: BorderRadius.circular(4),
                              onTap: () {
                                setState(() {
                                  _isEditingInline = true;
                                  _inlineController.text = item.effectivePackages.toString();
                                });
                              },
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
                                alignment: Alignment.center,
                                child: Text(
                                  '${item.effectivePackages}',
                                  style: theme.proviantTypography.numberMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.add),
                            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                            tooltip: 'Menge erhöhen',
                            onPressed: () async {
                              await ref.read(shoppingListServiceProvider).incrementPackages(item);
                              ref.invalidate(tripShoppingListProvider(widget.data.trip.id));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
            // Wasser-Schnellwahl (UX-Konzept 2.4: "+25 % warm" und "+50 % heiß/Tropen")
            if (isOnList && isWater) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.wb_sunny_outlined, size: 14),
                    label: const Text('+25 % warm', style: TextStyle(fontSize: 12)),
                    onPressed: () => _applyWaterBonus(0.25),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.local_fire_department_outlined, size: 14),
                    label: const Text('+50 % heiß/Tropen', style: TextStyle(fontSize: 12)),
                    onPressed: () => _applyWaterBonus(0.50),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
