/// Sortierte Vorratsliste "Nach Kategorie" (Kategorie → Bedarfsgruppe → Variante) (Slice UX-B / UX-Konzept 2.4).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/catalog_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'item_row_widget.dart';

class PlanningView extends ConsumerStatefulWidget {
  final TripShoppingListData data;
  final int? selectedStopId;

  const PlanningView({
    super.key,
    required this.data,
    this.selectedStopId,
  });

  @override
  ConsumerState<PlanningView> createState() => _PlanningViewState();
}

class _PlanningViewState extends ConsumerState<PlanningView> {
  final Set<String> _collapsedCategories = {};
  final Set<String> _expandedGroupIds = {};

  void _toggleCategory(String catId) {
    setState(() {
      if (_collapsedCategories.contains(catId)) {
        _collapsedCategories.remove(catId);
      } else {
        _collapsedCategories.add(catId);
      }
    });
  }

  void _toggleGroup(String groupId) {
    setState(() {
      if (_expandedGroupIds.contains(groupId)) {
        _expandedGroupIds.remove(groupId);
      } else {
        _expandedGroupIds.add(groupId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final categories = widget.data.categories;
    final hasAdoptedItems = widget.data.allItems.any((it) => it.isOnList);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: categories.length + (hasAdoptedItems ? 0 : 1),
      itemBuilder: (ctx, index) {
        // Leere Liste beim ersten Öffnen (UX-Konzept 2.4)
        if (!hasAdoptedItems && index == 0) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(
                  'Eure Vorratsliste ist noch leer.',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ihr könnt alle empfohlenen Grundvorräte mit einem Klick übernehmen oder einzelne Gruppen aufklappen.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.playlist_add_check),
                      label: const Text('Alle Vorschläge übernehmen'),
                      onPressed: () async {
                        await ref
                            .read(shoppingListServiceProvider)
                            .adoptAllSuggestions(widget.data.trip.id);
                        ref.invalidate(tripShoppingListProvider(widget.data.trip.id));
                      },
                    ),
                    OutlinedButton(
                      onPressed: () {
                        // Alle Gruppen aufklappen
                        setState(() {
                          for (final cat in categories) {
                            for (final g in cat.groups) {
                              _expandedGroupIds.add(g.group.id);
                            }
                          }
                        });
                      },
                      child: const Text('oder einzeln auswählen'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final catIndex = hasAdoptedItems ? index : index - 1;
        final catView = categories[catIndex];
        final isCollapsed = _collapsedCategories.contains(catView.category.id);
        return _buildCategorySection(context, catView, isCollapsed, theme, l10n);
      },
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    ShoppingListCategoryView catView,
    bool isCollapsed,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kategoriekopf (Ein-/Ausklappen & Vorschläge übernehmen)
        Container(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              InkWell(
                onTap: () => _toggleCategory(catView.category.id),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCollapsed ? Icons.chevron_right : Icons.expand_more,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        catView.category.nameDe,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(120, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () async {
                  await ref.read(shoppingListServiceProvider).adoptCategorySuggestions(
                        tripId: widget.data.trip.id,
                        categoryId: catView.category.id,
                      );
                  ref.invalidate(tripShoppingListProvider(widget.data.trip.id));
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.playlist_add_check, size: 16),
                    SizedBox(width: 4),
                    Text('Vorschläge dieser Kategorie'),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: catView.groups.map((groupView) {
                return _buildGroupSection(context, groupView, theme, l10n);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildGroupSection(
    BuildContext context,
    ShoppingListGroupView groupView,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final variants = _filterVariants(groupView.variants);
    if (variants.isEmpty && widget.selectedStopId != null) {
      return const SizedBox.shrink();
    }

    final hasAdopted = groupView.variants.any((v) => v.isOnList);
    // Standardmäßig aufgeklappt wenn Posten übernommen sind oder explizit expandiert
    final isExpanded = _expandedGroupIds.contains(groupView.group.id) || hasAdopted;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gruppenkopf (Klick klappt Varianten direkt darunter auf – kein Sheet, UX-Konzept 2.4)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _toggleGroup(groupView.group.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupView.group.nameDe,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (groupView.group.mode == GroupMode.check)
                          Text(
                            '${groupView.checkedCount} von ${groupView.variants.length} geprüft',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          )
                        else if (groupView.group.need != null)
                          Text(
                            'Vorschlag gesamt: ca. ${groupView.group.need!.amount} ${groupView.group.need!.unit}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 22,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            // Varianten-Zeilen direkt unter der Gruppe
            ...variants.map((v) => ShoppingListItemRow(
                  data: widget.data,
                  item: v,
                )),
          ],
        ],
      ),
    );
  }

  List<ShoppingListItemView> _filterVariants(List<ShoppingListItemView> variants) {
    if (widget.selectedStopId == null) {
      return variants;
    }
    final isFirstStop = widget.data.stops.firstOrNull?.id == widget.selectedStopId;
    return variants.where((v) {
      if (!v.isOnList) return false;
      final totalOtherAlloc = v.allocationsByStop.entries
          .where((e) => e.key != widget.selectedStopId)
          .fold<int>(0, (sum, e) => sum + e.value.allocatedPackages);
      final count = v.packagesAtStop(
        widget.selectedStopId!,
        isFirstStop: isFirstStop,
        totalOtherAllocated: totalOtherAlloc,
      );
      return count > 0;
    }).toList();
  }
}
