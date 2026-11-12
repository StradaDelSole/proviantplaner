/// Sortierte Vorratsliste "Nach Supermarkt-Abteilung" (flach, Ladenreihenfolge) (FEEDBACK_R1 Punkt 5 & 7).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/services/catalog_localization_service.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'empty_shopping_list_view.dart';
import 'item_row_widget.dart';

class ShoppingView extends ConsumerWidget {
  final TripShoppingListData data;
  final int? selectedStopId;

  const ShoppingView({
    super.key,
    required this.data,
    this.selectedStopId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final departments = data.departments;

    final totalOnList = data.allItems.where((it) => it.isOnList).length;
    if (totalOnList == 0) {
      return EmptyShoppingListView(data: data);
    }

    final categoryLabels = <String, String>{
      for (final catView in data.categories)
        catView.category.id: catView.category.localizedName(context),
    };

    return ListView.builder(
      key: PageStorageKey<String>('shopping_view_list_${data.trip.id}'),
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: departments.length,
      itemBuilder: (ctx, i) {
        final deptView = departments[i];
        final filteredItems = _filterItems(deptView.items);
        if (filteredItems.isEmpty) return const SizedBox.shrink();

        return _buildDepartmentSection(context, ref, deptView, filteredItems, categoryLabels, theme, l10n);
      },
    );
  }

  List<ShoppingListItemView> _filterItems(List<ShoppingListItemView> items) {
    if (selectedStopId == null) {
      return items.where((it) => it.isOnList).toList();
    }

    final isFirstStop = data.stops.firstOrNull?.id == selectedStopId;
    return items.where((it) {
      if (!it.isOnList) return false;
      final totalOtherAlloc = it.allocationsByStop.entries
          .where((e) => e.key != selectedStopId)
          .fold<int>(0, (sum, e) => sum + e.value.allocatedPackages);
      final count = it.packagesAtStop(
        selectedStopId!,
        isFirstStop: isFirstStop,
        totalOtherAllocated: totalOtherAlloc,
      );
      return count > 0;
    }).toList();
  }

  Widget _buildDepartmentSection(
    BuildContext context,
    WidgetRef ref,
    ShoppingListDepartmentView deptView,
    List<ShoppingListItemView> items,
    Map<String, String> categoryLabels,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Neutraler Abteilungskopf (eine Abteilung kann mehrere Provy-Kategorien enthalten)
        Container(
          key: ValueKey('dept_header_${deptView.department.name}'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(deptView.icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  deptView.department.localizedName(context).toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                l10n.itemCountLabel(items.length),
                style: theme.proviantTypography.numberSmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Postenliste mit konsistenter Kategorie-Farbmarkierung
        ...items.map((it) => ShoppingListItemRow(
              data: data,
              item: it,
              showCategoryAccent: true,
              categoryLabel: categoryLabels[it.categoryId],
            )),
      ],
    );
  }
}
