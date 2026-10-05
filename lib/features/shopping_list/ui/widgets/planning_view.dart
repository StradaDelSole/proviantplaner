/// Sortierte Vorratsliste "Nach Kategorie" (Kategorie → Bedarfsgruppe → Variante) (Slice UX-B / UX-Konzept 2.4).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/services/catalog_localization_service.dart';
import 'package:proviantplaner/core/util/formatters.dart';
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
    final wv = widget.data.weightAndVolume;

    return Column(
      children: [
        // Gesamtgewicht und -volumen über der Liste (FEEDBACK_R2 v0.3 Punkt 6)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          child: Row(
            children: [
              Icon(Icons.scale_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.totalWeightVolumeSummary(
                    AppFormatters.formatDecimal(context, wv.totalWeightKg),
                    AppFormatters.formatDecimal(context, wv.totalVolumeLiters),
                    wv.hasItemsWithoutWeight ? ' (+ ${l10n.unitPiece})' : '',
                  ),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
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
                  l10n.planningListEmptyTitle,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.planningListEmptySubtitle,
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
                      label: Text(l10n.adoptAllSuggestions),
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
                      child: Text(l10n.orSelectIndividually),
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
    ),
  ),
],
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
              Expanded(
                child: InkWell(
                  onTap: () => _toggleCategory(catView.category.id),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        Icon(
                          isCollapsed ? Icons.chevron_right : Icons.expand_more,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            catView.category.localizedName(context),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.playlist_add_check, size: 16),
                    const SizedBox(width: 4),
                    Text(l10n.categorySuggestions),
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
                          groupView.group.localizedName(context),
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (groupView.group.mode == GroupMode.check)
                          Text(
                            l10n.groupCheckedStatus(groupView.checkedCount, groupView.variants.length),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          )
                        else if (groupView.group.need != null)
                          Text(
                            l10n.suggestionTotal(AppFormatters.formatDecimal(context, groupView.group.need!.amount), groupView.group.need!.unit),
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
