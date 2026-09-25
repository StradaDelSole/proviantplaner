/// Sicht "Planen" in der Vorratsliste: Kategorie → Gruppe → Varianten (SC-LST-01 / 5.2).
library;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/catalog_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'group_detail_sheet.dart';

class PlanningView extends StatefulWidget {
  final TripShoppingListData data;

  const PlanningView({super.key, required this.data});

  @override
  State<PlanningView> createState() => _PlanningViewState();
}

class _PlanningViewState extends State<PlanningView> {
  final Set<String> _collapsedCategories = {};

  void _toggleCategory(String catId) {
    setState(() {
      if (_collapsedCategories.contains(catId)) {
        _collapsedCategories.remove(catId);
      } else {
        _collapsedCategories.add(catId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final categories = widget.data.categories;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: categories.length,
      itemBuilder: (ctx, i) {
        final catView = categories[i];
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
        // Kategoriekopf (sticky-Look, klickbar zum Ein-/Ausklappen)
        InkWell(
          onTap: () => _toggleCategory(catView.category.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            child: Row(
              children: [
                Icon(
                  isCollapsed ? Icons.chevron_right : Icons.expand_more,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    catView.category.nameDe,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${catView.groups.length} Gruppen · ${catView.openCount} offen',
                  style: theme.proviantTypography.numberSmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: catView.groups.map((groupView) {
                return _buildGroupCard(context, groupView, theme, l10n);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    ShoppingListGroupView groupView,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final selectedVariants = groupView.variants.where((v) => v.isSelected).toList();
    final names = selectedVariants.map((v) => v.name).join(' · ');
    final variantsSummary = names.isEmpty ? 'Keine Variante ausgewählt' : names;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => GroupDetailSheet.show(
          context,
          tripId: widget.data.trip.id,
          groupView: groupView,
          stops: widget.data.stops,
          isCharter: widget.data.trip.isCharter,
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      groupView.group.nameDe,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      variantsSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCoverageIndicator(groupView, theme, l10n),
                  const SizedBox(height: 4),
                  Text(
                    '${groupView.totalPackages} Pck.',
                    style: theme.proviantTypography.numberMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverageIndicator(
    ShoppingListGroupView groupView,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    if (groupView.group.mode == GroupMode.check) {
      return Text(
        '${groupView.checkedCount} von ${groupView.variants.length} geprüft',
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
      );
    }

    final (label, color, icon) = switch (groupView.coverageStatus) {
      GroupCoverageStatus.covered => (l10n.covered, theme.colorScheme.secondary, Icons.check_circle),
      GroupCoverageStatus.scarce => (l10n.scarce, Colors.amber.shade700, Icons.warning_amber),
      GroupCoverageStatus.noneSelected => (l10n.noneSelected, theme.colorScheme.onSurfaceVariant, Icons.remove_circle_outline),
      GroupCoverageStatus.checklist => ('', theme.colorScheme.primary, Icons.check),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
