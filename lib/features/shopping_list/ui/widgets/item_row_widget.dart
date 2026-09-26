/// Einheitliches Zeilen-Widget für Vorratspositionen (FEEDBACK_R1 Punkt 5 & 7).
///
/// Sieht in beiden Sortierungen ("Nach Kategorie" und "Nach Abteilung") identisch aus
/// und verhält sich identisch:
/// - Nicht übernommene Artikel zeigen "Vorschlag: X × Y" und "+ übernehmen"
/// - Übernommene Artikel zeigen die Menge mit Stepper (−, Zahl, +) und kleinem Vorschlag daneben
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'group_detail_sheet.dart';

class ShoppingListItemRow extends ConsumerWidget {
  final TripShoppingListData data;
  final ShoppingListItemView item;

  const ShoppingListItemRow({
    super.key,
    required this.data,
    required this.item,
  });

  void _openDetail(BuildContext context) {
    if (item.isCustom) return;

    for (final cat in data.categories) {
      for (final g in cat.groups) {
        if (g.variants.any((v) => v.id == item.id)) {
          GroupDetailSheet.show(
            context,
            tripId: data.trip.id,
            groupView: g,
            stops: data.stops,
            isCharter: data.trip.isCharter,
          );
          return;
        }
      }
    }
  }

  Future<void> _showDirectQuantityDialog(
    BuildContext context,
    WidgetRef ref,
    ShoppingListItemView it,
  ) async {
    final controller = TextEditingController(text: it.effectivePackages.toString());
    final count = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${it.name}: Menge anpassen'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Anzahl Packungen (0 zum Entfernen)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              Navigator.of(ctx).pop(parsed);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (count != null) {
      await ref.read(shoppingListServiceProvider).setPackages(it, count);
      ref.invalidate(tripShoppingListProvider(data.trip.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOnList = item.isOnList;

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text-Spalte (Name, Vorschlag / Bedarf, Badges)
          Expanded(
            child: InkWell(
              onTap: () => _openDetail(context),
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
                  if (data.trip.fridgeCapacity <= 0 && item.isCooled) ...[
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
                    if (item.hasSuggestionDifference) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Abweichung: Vorschlag ${item.calculatedPackages}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Aktions- / Mengen-Spalte
          if (!isOnList) ...[
            FilledButton.tonal(
              onPressed: () async {
                await ref.read(shoppingListServiceProvider).adoptItem(
                      tripId: data.trip.id,
                      listItemId: item.item.id,
                    );
                ref.invalidate(tripShoppingListProvider(data.trip.id));
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(110, 48),
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
                Text(
                  item.packDisplay,
                  style: theme.proviantTypography.numberLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      tooltip: 'Menge verringern',
                      onPressed: () async {
                        await ref.read(shoppingListServiceProvider).decrementPackages(item);
                        ref.invalidate(tripShoppingListProvider(data.trip.id));
                      },
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => _showDirectQuantityDialog(context, ref, item),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 48),
                        alignment: Alignment.center,
                        child: Text(
                          '${item.effectivePackages}',
                          style: theme.proviantTypography.numberMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      tooltip: 'Menge erhöhen',
                      onPressed: () async {
                        await ref.read(shoppingListServiceProvider).incrementPackages(item);
                        ref.invalidate(tripShoppingListProvider(data.trip.id));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
