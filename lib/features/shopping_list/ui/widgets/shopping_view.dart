/// Sicht "Einkaufen" in der Vorratsliste: Feste Ladenreihenfolge nach Abteilungen (SC-LST-01 / 5.3).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'group_detail_sheet.dart';

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

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: departments.length,
      itemBuilder: (ctx, i) {
        final deptView = departments[i];
        final filteredItems = _filterItems(deptView.items);
        if (filteredItems.isEmpty) return const SizedBox.shrink();

        return _buildDepartmentSection(context, ref, deptView, filteredItems, theme, l10n);
      },
    );
  }

  List<ShoppingListItemView> _filterItems(List<ShoppingListItemView> items) {
    if (selectedStopId == null) {
      return items.where((it) => it.isSelected).toList();
    }

    final isFirstStop = data.stops.firstOrNull?.id == selectedStopId;
    return items.where((it) {
      if (!it.isSelected) return false;
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
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Abteilungskopf
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
          child: Row(
            children: [
              Icon(deptView.icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  deptView.displayName.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Text(
                '${items.length} Posten',
                style: theme.proviantTypography.numberSmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Postenliste
        ...items.map((it) => _buildVariantRow(context, ref, it, theme, l10n)),
      ],
    );
  }

  Widget _buildVariantRow(
    BuildContext context,
    WidgetRef ref,
    ShoppingListItemView it,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text-Spalte (Name, Bedarf, Badges)
          Expanded(
            child: InkWell(
              onTap: () => _openGroupDetail(context, it),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Zeile 1: Name
                  Text(
                    it.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  // Zeile 2: Bedarf & Reserve
                  Text(
                    it.demandDisplay,
                    style: theme.proviantTypography.numberSmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Zeile 3: Badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _buildBadges(it, ref, theme, l10n),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Stepper-Spalte (Packungsangabe & Stepper)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                it.packDisplay,
                style: theme.proviantTypography.numberLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () async {
                      await ref.read(shoppingListServiceProvider).decrementPackages(it);
                      ref.invalidate(tripShoppingListProvider(data.trip.id));
                    },
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 28),
                    alignment: Alignment.center,
                    child: Text(
                      '${it.effectivePackages}',
                      style: theme.proviantTypography.numberMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () async {
                      await ref.read(shoppingListServiceProvider).incrementPackages(it);
                      ref.invalidate(tripShoppingListProvider(data.trip.id));
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBadges(
    ShoppingListItemView it,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final badges = <Widget>[];

    if (it.isCustom) {
      badges.add(_badge(theme, Icons.star_outline, l10n.customItemBadge, theme.colorScheme.primary));
    }
    if (it.isCooled) {
      badges.add(_badge(theme, Icons.ac_unit, l10n.cooled, theme.colorScheme.secondary));
    }
    if (it.shelfLifeDays > 0 && it.shelfLifeDays <= 3) {
      badges.add(_badge(theme, Icons.schedule, 'hält ${it.shelfLifeDays} T.', Colors.amber.shade800));
    }
    if (it.isOverridden) {
      badges.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _badge(theme, Icons.edit_outlined, l10n.overridden, theme.colorScheme.error),
            const SizedBox(width: 4),
            InkWell(
              onTap: () async {
                await ref.read(shoppingListServiceProvider).resetOverride(it);
                ref.invalidate(tripShoppingListProvider(data.trip.id));
              },
              child: Text(
                l10n.resetOverride,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return badges;
  }

  Widget _badge(ThemeData theme, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _openGroupDetail(BuildContext context, ShoppingListItemView it) {
    if (it.isCustom || it.variant == null) return;
    for (final cat in data.categories) {
      for (final grp in cat.groups) {
        if (grp.group.id == it.variant!.group) {
          GroupDetailSheet.show(
            context,
            tripId: data.trip.id,
            groupView: grp,
            stops: data.stops,
            isCharter: data.trip.isCharter,
          );
          return;
        }
      }
    }
  }
}
