/// Gruppen-Detail-Sheet zur Auswahl von Varianten und Anteilen (SC-LST-02).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/catalog_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/package_size_dialog.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/stop_allocation_sheet.dart';

class GroupDetailSheet extends ConsumerStatefulWidget {
  final int tripId;
  final ShoppingListGroupView groupView;
  final List<ShoppingStop> stops;
  final bool isCharter;

  const GroupDetailSheet({
    super.key,
    required this.tripId,
    required this.groupView,
    required this.stops,
    required this.isCharter,
  });

  static Future<void> show(
    BuildContext context, {
    required int tripId,
    required ShoppingListGroupView groupView,
    required List<ShoppingStop> stops,
    required bool isCharter,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.9,
        child: GroupDetailSheet(
          tripId: tripId,
          groupView: groupView,
          stops: stops,
          isCharter: isCharter,
        ),
      ),
    );
  }

  @override
  ConsumerState<GroupDetailSheet> createState() => _GroupDetailSheetState();
}

class _GroupDetailSheetState extends ConsumerState<GroupDetailSheet> {
  late bool _showCharterAnyway;

  @override
  void initState() {
    super.initState();
    _showCharterAnyway = !widget.isCharter || widget.groupView.group.visibility == GroupVisibility.all;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final group = widget.groupView.group;
    final variants = widget.groupView.variants;

    return Column(
      children: [
        // Kopfzeile
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.nameDe,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        // Bedarfsangabe
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              group.mode == GroupMode.check
                  ? 'Prüfliste (vorhanden / fehlt / nachkaufen)'
                  : group.split == GroupSplit.each
                      ? 'Jede Sorte wird einzeln berechnet'
                      : 'Bedarf: ${group.need?.amount ?? 0} ${group.need?.unit ?? ""} · split=${group.split.rawValue}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        if (widget.isCharter && widget.groupView.isOwnerOnly)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: SwitchListTile.adaptive(
                title: Text(l10n.charterNotice, style: theme.textTheme.bodySmall),
                value: _showCharterAnyway,
                onChanged: (val) => setState(() => _showCharterAnyway = val),
              ),
            ),
          ),
        const Divider(),
        // Variantenliste
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: variants.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final v = variants[i];
              return _buildVariantTile(context, v, theme, l10n);
            },
          ),
        ),
        // Sticky Summenleiste unten
        _buildBottomBar(theme, l10n),
      ],
    );
  }

  Widget _buildVariantTile(
    BuildContext context,
    ShoppingListItemView v,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: v.isSelected,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(shoppingListServiceProvider).toggleVariantSelected(
                          tripId: widget.tripId,
                          listItemId: v.item.id,
                          isSelected: val,
                        );
                    ref.invalidate(tripShoppingListProvider(widget.tripId));
                  }
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: v.isSelected ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      v.packDisplay,
                      style: theme.proviantTypography.numberSmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (v.isSelected)
                TextButton(
                  onPressed: () async {
                    final newSize = await PackageSizeDialog.show(context, v);
                    if (newSize != null) {
                      await ref.read(shoppingListServiceProvider).updateCustomPackageSize(
                            tripId: widget.tripId,
                            listItemId: v.item.id,
                            packSize: newSize,
                          );
                      ref.invalidate(tripShoppingListProvider(widget.tripId));
                    }
                  },
                  child: Text(
                    l10n.changePackSize,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          if (v.isSelected && widget.groupView.group.split == GroupSplit.equal)
            Padding(
              padding: const EdgeInsets.only(left: 48, right: 8),
              child: Row(
                children: [
                  Text(
                    'Anteil: ${(v.share * 100).round()} %',
                    style: theme.proviantTypography.numberSmall,
                  ),
                  Expanded(
                    child: Slider(
                      value: v.share,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (val) {
                        ref.read(shoppingListServiceProvider).updateVariantShare(
                              tripId: widget.tripId,
                              listItemId: v.item.id,
                              share: val,
                            );
                        ref.invalidate(tripShoppingListProvider(widget.tripId));
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, AppLocalizations l10n) {
    final status = widget.groupView.coverageStatus;
    final total = widget.groupView.totalPackages;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gesamt: $total Packungen',
                style: theme.proviantTypography.numberMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              _buildCoverageBadge(status, theme, l10n),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.stops.length > 1) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final firstSelected = widget.groupView.variants.where((v) => v.isSelected).firstOrNull;
                      if (firstSelected != null) {
                        StopAllocationSheet.show(
                          context,
                          tripId: widget.tripId,
                          item: firstSelected,
                          stops: widget.stops,
                        );
                      }
                    },
                    child: Text(l10n.allocateToStop),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.takeOver),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageBadge(GroupCoverageStatus status, ThemeData theme, AppLocalizations l10n) {
    final (text, color, icon) = switch (status) {
      GroupCoverageStatus.covered => (l10n.covered, theme.colorScheme.secondary, Icons.check_circle_outline),
      GroupCoverageStatus.scarce => (l10n.scarce, Colors.amber, Icons.warning_amber_outlined),
      GroupCoverageStatus.noneSelected => (l10n.noneSelected, theme.colorScheme.onSurfaceVariant, Icons.remove_circle_outline),
      GroupCoverageStatus.checklist => ('${widget.groupView.checkedCount} geprüft', theme.colorScheme.primary, Icons.checklist),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
