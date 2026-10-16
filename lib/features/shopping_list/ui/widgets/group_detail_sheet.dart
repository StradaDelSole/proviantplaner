/// Gruppen-Detail-Sheet zur Auswahl von Varianten und Anteilen (SC-LST-02, FEEDBACK_R1 Punkt 6).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/tables.dart';
import 'package:proviantplaner/core/services/catalog_localization_service.dart';
import 'package:proviantplaner/core/util/formatters.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
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

  ShoppingListGroupView _resolveCurrentGroupView(TripShoppingListData? listData) {
    if (listData == null) return widget.groupView;
    for (final cat in listData.categories) {
      for (final g in cat.groups) {
        if (g.group.id == widget.groupView.group.id) {
          return g;
        }
      }
    }
    return widget.groupView;
  }

  Future<void> _toggleVariant(ShoppingListItemView v, bool isSelected) async {
    await ref.read(shoppingListServiceProvider).toggleVariantSelected(
          tripId: widget.tripId,
          listItemId: v.item.id,
          isSelected: isSelected,
        );
    ref.invalidate(tripShoppingListProvider(widget.tripId));
  }

  Future<void> _updateCheckState(ShoppingListItemView v, CheckItemState state) async {
    await ref.read(shoppingListServiceProvider).updateCheckState(
          tripId: widget.tripId,
          listItemId: v.item.id,
          state: state,
        );
    ref.invalidate(tripShoppingListProvider(widget.tripId));
  }

  Future<void> _showQuantityDialog(BuildContext context, ShoppingListItemView v) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: v.effectivePackages.toString());
    final count = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adjustQuantityTitle(v.name)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.packageCountLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              Navigator.of(ctx).pop(parsed);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (count != null) {
      await ref.read(shoppingListServiceProvider).setPackages(v, count);
      ref.invalidate(tripShoppingListProvider(widget.tripId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final listDataAsync = ref.watch(tripShoppingListProvider(widget.tripId));
    final currentGroupView = _resolveCurrentGroupView(listDataAsync.valueOrNull);
    final group = currentGroupView.group;
    final variants = currentGroupView.variants;
    final tripData = listDataAsync.valueOrNull;
    final hasNoFridge = (tripData?.trip.fridgeCapacity ?? 100) <= 0;
    final anyNeedsCooling = variants.any((v) => v.isCooled);

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
                  group.localizedName(context),
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
            child: group.mode == GroupMode.check
                ? Text(
                    l10n.checklistHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : group.need?.basis == CalculationBasis.perPersonDayRegion
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.waterMinimumTotal(
                              AppFormatters.formatDecimal(
                                context,
                                (currentGroupView.calculatedGroupNeed ?? group.need?.amount ?? 0).toDouble(),
                              ),
                              currentGroupView.calculatedGroupUnit ?? group.need?.unit ?? '',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.waterPlanningNotice,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        group.split == GroupSplit.each
                            ? l10n.eachSplitHint
                            : l10n.needSplitHint(
                                AppFormatters.formatDecimal(context, (group.need?.amount ?? 0).toDouble()),
                                group.need?.unit ?? '',
                                group.split.rawValue,
                              ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
          ),
        ),
        if (widget.isCharter && currentGroupView.isOwnerOnly)
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
        if (hasNoFridge && anyNeedsCooling)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.tertiary.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.ac_unit, size: 20, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.coolingAlternativeHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
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
              if (group.mode == GroupMode.check) {
                return _buildChecklistTile(context, v, theme, l10n);
              }
              return _buildVariantTile(context, v, theme, l10n, currentGroupView, hasNoFridge: hasNoFridge);
            },
          ),
        ),
        // Sticky Summenleiste unten
        _buildBottomBar(theme, l10n, currentGroupView),
      ],
    );
  }

  Widget _buildChecklistTile(
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
          Text(
            v.localizedName(context),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          SegmentedButton<CheckItemState>(
            segments: [
              ButtonSegment(
                value: CheckItemState.available,
                label: Text(l10n.checkStatePresent),
                icon: const Icon(Icons.check, size: 16),
              ),
              ButtonSegment(
                value: CheckItemState.missing,
                label: Text(l10n.checkStateMissing),
                icon: const Icon(Icons.remove, size: 16),
              ),
              ButtonSegment(
                value: CheckItemState.restock,
                label: Text(l10n.checkStateRestock),
                icon: const Icon(Icons.shopping_cart_outlined, size: 16),
              ),
            ],
            selected: {v.checkState},
            onSelectionChanged: (set) {
              if (set.isNotEmpty) {
                _updateCheckState(v, set.first);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVariantTile(
    BuildContext context,
    ShoppingListItemView v,
    ThemeData theme,
    AppLocalizations l10n,
    ShoppingListGroupView currentGroupView, {
    bool hasNoFridge = false,
  }) {
    final needsCooling = v.isCooled;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _toggleVariant(v, !v.isSelected),
      child: Padding(
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
                      _toggleVariant(v, val);
                    }
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.localizedName(context),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasNoFridge && needsCooling) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.needsCoolingBadge,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (v.isSelected)
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => _showQuantityDialog(context, v),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  v.packDisplay,
                                  style: theme.proviantTypography.numberSmall.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.edit_outlined, size: 14, color: theme.colorScheme.primary),
                              ],
                            ),
                          ),
                        )
                      else
                        Text(
                          v.packDisplay,
                          style: theme.proviantTypography.numberSmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (v.isSelected) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_note, size: 20),
                    tooltip: l10n.enterQuantityTooltip,
                    onPressed: () => _showQuantityDialog(context, v),
                  ),
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
              ],
            ),
            if (v.isSelected && currentGroupView.group.split == GroupSplit.equal)
              Padding(
                padding: const EdgeInsets.only(left: 48, right: 8),
                child: Row(
                  children: [
                    Text(
                      l10n.sharePercent((v.share * 100).round()),
                      style: theme.proviantTypography.numberSmall,
                    ),
                    Expanded(
                      child: Slider(
                        value: v.share,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        onChanged: (val) async {
                          await ref.read(shoppingListServiceProvider).updateVariantShare(
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
      ),
    );
  }

  Widget _buildBottomBar(
    ThemeData theme,
    AppLocalizations l10n,
    ShoppingListGroupView currentGroupView,
  ) {
    final status = currentGroupView.coverageStatus;
    final total = currentGroupView.totalPackages;

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
              Expanded(
                child: Text(
                  'Gesamt: $total Packungen',
                  style: theme.proviantTypography.numberMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              _buildCoverageBadge(status, theme, l10n, currentGroupView),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.stops.length > 1) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final firstSelected = currentGroupView.variants.where((v) => v.isSelected).firstOrNull;
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

  Widget _buildCoverageBadge(
    GroupCoverageStatus status,
    ThemeData theme,
    AppLocalizations l10n,
    ShoppingListGroupView currentGroupView,
  ) {
    if (currentGroupView.group.mode == GroupMode.check) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            '${currentGroupView.checkedCount} geprüft',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    final hasItems = currentGroupView.variants.any((v) => v.isOnList);
    final (text, color, icon) = hasItems
        ? ('${currentGroupView.totalPackages} Pck. auf der Liste', theme.colorScheme.secondary, Icons.check_circle_outline)
        : (l10n.noneSelected, theme.colorScheme.onSurfaceVariant, Icons.remove_circle_outline);

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
