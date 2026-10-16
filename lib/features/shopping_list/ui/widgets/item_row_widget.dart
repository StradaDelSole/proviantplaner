/// Einheitliches Zeilen-Widget für Vorratspositionen (Slice UX-B / UX-Konzept 2.4).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/services/catalog_localization_service.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'add_or_edit_item_sheet.dart';

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

  Future<void> _showStopSelection(BuildContext context) async {
    final stops = widget.data.stops;
    if (stops.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final itemName = widget.item.localizedName(context);

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
                l10n.selectStopTitle(itemName),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stops.map((stop) {
                  return ActionChip(
                    avatar: const Icon(Icons.storefront_outlined, size: 16),
                    label: Text(l10n.stopDayPort(stop.dayNumber, stop.name)),
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
                          SnackBar(content: Text(l10n.itemAssignedToStop(itemName, stop.name))),
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final item = widget.item;
    final isOnList = item.isOnList;

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
              l10n.selectStop,
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
                // Text-Spalte (Name, Vorschlag / Bedarf, Badges) - Tap öffnet AddOrEditItemSheet
                Expanded(
                  child: InkWell(
                    key: ValueKey('item_tap_${item.item.id}'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      AddOrEditItemSheet.show(
                        context,
                        data: widget.data,
                        item: item,
                        isAdding: !isOnList,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.localizedName(context),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.storageNotice != null || (widget.data.trip.fridgeCapacity <= 0 && item.isCooled)) ...[
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (item.storageNotice?.contains('einfrieren') == true)
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.storageNotice ?? l10n.needsCooling,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: (item.storageNotice?.contains('einfrieren') == true)
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 2),
                          if (!isOnList) ...[
                            Text(
                              item.suggestionDisplayLocalized(l10n),
                              style: theme.proviantTypography.numberSmall.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ] else ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  item.demandDisplayLocalized(l10n),
                                  style: theme.proviantTypography.numberSmall.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (item.calculatedPackages > 0 && !item.assistType.isPreferenceBased)
                                  Text(
                                    '(${item.shortSuggestionDisplayLocalized(l10n)})',
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
                  ),
                ),
                const SizedBox(width: 8),
                // Aktions- / Mengen-Spalte (PIVOT1: Kein direkter Adopt-Bypass, immer über AddOrEditItemSheet)
                if (!isOnList) ...[
                  FilledButton.tonal(
                    key: ValueKey('item_add_btn_${item.item.id}'),
                    onPressed: () {
                      AddOrEditItemSheet.show(
                        context,
                        data: widget.data,
                        item: item,
                        isAdding: true,
                      );
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(90, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 18),
                        const SizedBox(width: 4),
                        Text(l10n.takeOver),
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
                            tooltip: l10n.decreaseQuantity,
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
                            tooltip: l10n.increaseQuantity,
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
            if (item.remainderNotice != null) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.remainderNotice!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
