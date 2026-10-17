/// Bottom-Sheet für die Vorratsprüfung (PIVOT2 / Issue #26).
/// Zeigt die Prüfbefunde übersichtlich nach Dringlichkeit gegliedert an.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/provisioning_review_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'add_or_edit_item_sheet.dart';
import 'catalog_search_delegate.dart';

class ProvisioningReviewSheet extends ConsumerWidget {
  final TripShoppingListData data;

  const ProvisioningReviewSheet({
    super.key,
    required this.data,
  });

  static Future<void> show(BuildContext context, {required TripShoppingListData data}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ProvisioningReviewSheet(data: data),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final reviewAsync = ref.watch(provisioningReviewProvider(data.trip.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            // Handle & Header
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.fact_check_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.reviewTitle,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: reviewAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.technicalErrorMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ),
                data: (result) {
                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _buildStatusHeader(context, theme, l10n, result),
                      const SizedBox(height: 16),
                      ..._buildSections(context, ref, theme, l10n, result),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusHeader(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    ProvisioningReviewResult result,
  ) {
    final (icon, color, title, subtitle) = switch (result.status) {
      ProvisioningReviewStatus.ready => (
          Icons.check_circle_outline,
          Colors.green,
          l10n.reviewStatusReady,
          l10n.reviewStatusReadySubtitle,
        ),
      ProvisioningReviewStatus.check => (
          Icons.help_outline,
          Colors.orange,
          l10n.reviewStatusCheck,
          l10n.reviewStatusCheckSubtitle,
        ),
      ProvisioningReviewStatus.actionNeeded => (
          Icons.error_outline,
          theme.colorScheme.error,
          l10n.reviewStatusActionNeeded,
          l10n.reviewStatusActionNeededSubtitle,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSections(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    ProvisioningReviewResult result,
  ) {
    final widgets = <Widget>[];

    final actionNeededFindings = result.findings
        .where((f) => f.severity == ProvisioningReviewSeverity.actionNeeded)
        .toList();
    final checkFindings = result.findings
        .where((f) => f.severity == ProvisioningReviewSeverity.check)
        .toList();
    final infoFindings = result.findings
        .where((f) => f.severity == ProvisioningReviewSeverity.info)
        .toList();

    // Sektion: Aktion nötig
    if (actionNeededFindings.isNotEmpty) {
      widgets.add(_buildSectionHeader(
        theme,
        l10n.reviewSectionActionNeeded,
        theme.colorScheme.error,
        Icons.warning_amber_rounded,
      ));
      for (final f in actionNeededFindings) {
        widgets.add(_buildFindingCard(context, ref, theme, l10n, f));
        widgets.add(const SizedBox(height: 8));
      }
      widgets.add(const SizedBox(height: 12));
    }

    // Sektion: Noch prüfen
    if (checkFindings.isNotEmpty) {
      widgets.add(_buildSectionHeader(
        theme,
        l10n.reviewSectionCheck,
        Colors.orange,
        Icons.info_outline,
      ));
      for (final f in checkFindings) {
        widgets.add(_buildFindingCard(context, ref, theme, l10n, f));
        widgets.add(const SizedBox(height: 8));
      }
      widgets.add(const SizedBox(height: 12));
    }

    // Sektion: Informationen (inkl. Gesamtgewicht / Volumen)
    widgets.add(_buildSectionHeader(
      theme,
      l10n.reviewSectionInfo,
      theme.colorScheme.primary,
      Icons.analytics_outlined,
    ));

    // Gewicht & Volumen Karte
    widgets.add(_buildWeightVolumeCard(theme, l10n, result));
    widgets.add(const SizedBox(height: 8));

    for (final f in infoFindings) {
      widgets.add(_buildFindingCard(context, ref, theme, l10n, f));
      widgets.add(const SizedBox(height: 8));
    }

    return widgets;
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindingCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    ProvisioningReviewFinding finding,
  ) {
    final (title, message) = _formatFindingTexts(context, l10n, finding);

    final color = switch (finding.severity) {
      ProvisioningReviewSeverity.actionNeeded => theme.colorScheme.error,
      ProvisioningReviewSeverity.check => Colors.orange,
      ProvisioningReviewSeverity.info => theme.colorScheme.primary,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (finding.hasPotableTank || finding.hasWatermaker) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (finding.hasPotableTank)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.water_drop_outlined, size: 14),
                      label: Text(l10n.reviewWaterTankNote, style: const TextStyle(fontSize: 11)),
                    ),
                  if (finding.hasWatermaker)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.waves, size: 14),
                      label: Text(l10n.reviewWatermakerNote, style: const TextStyle(fontSize: 11)),
                    ),
                ],
              ),
            ],
            if (finding.action.type != ProvisioningReviewActionType.noAction) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _buildActionButton(context, ref, theme, l10n, finding),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeightVolumeCard(
    ThemeData theme,
    AppLocalizations l10n,
    ProvisioningReviewResult result,
  ) {
    final weightStr = result.totalWeightKg.toStringAsFixed(1);
    final volumeStr = result.totalVolumeLiters.toStringAsFixed(1);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.scale_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.reviewTotalWeightVolumeTitle,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              result.hasItemsWithoutWeight
                  ? l10n.reviewTotalWeightVolumeMessageWithNotice(weightStr, volumeStr)
                  : l10n.reviewTotalWeightVolumeMessage(weightStr, volumeStr),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, String) _formatFindingTexts(
    BuildContext context,
    AppLocalizations l10n,
    ProvisioningReviewFinding finding,
  ) {
    switch (finding.kind) {
      case ProvisioningReviewKind.missingBasic:
        final ruleId = finding.ruleId ?? 'other';
        return (
          l10n.reviewMissingBasicTitle(ruleId),
          l10n.reviewMissingBasicMessage(ruleId),
        );

      case ProvisioningReviewKind.drinkingWaterCheck:
        final actualStr = (finding.actualValue ?? 0.0).toStringAsFixed(1);
        final estStr = (finding.estimatedValue ?? 0.0).toStringAsFixed(1);
        return (
          l10n.reviewWaterCheckTitle,
          l10n.reviewWaterCheckMessage(actualStr, estStr),
        );

      case ProvisioningReviewKind.freshness:
        final itemName = _resolveItemName(finding.listItemId);
        return (
          l10n.reviewFreshnessTitle(itemName),
          l10n.reviewFreshnessMessage(
            itemName,
            finding.shelfLifeDays ?? 0,
            finding.horizonDays ?? 0,
          ),
        );

      case ProvisioningReviewKind.fridgeRequirement:
        final itemName = _resolveItemName(finding.listItemId);
        return (
          l10n.reviewFridgeNoCapacityTitle(itemName),
          l10n.reviewFridgeNoCapacityMessage(itemName),
        );

      case ProvisioningReviewKind.freezerRequirement:
        final itemName = _resolveItemName(finding.listItemId);
        return (
          l10n.reviewFreezerNoFreezerTitle(itemName),
          l10n.reviewFreezerNoFreezerMessage(itemName),
        );

      case ProvisioningReviewKind.fridgeCapacity:
        final actStr = (finding.actualValue ?? 0.0).toStringAsFixed(1);
        final capStr = (finding.estimatedValue ?? 0.0).toStringAsFixed(0);
        return (
          l10n.reviewFridgeOverloadedTitle,
          l10n.reviewFridgeOverloadedMessage(actStr, capStr),
        );

      case ProvisioningReviewKind.freezerCapacity:
        final actStr = (finding.actualValue ?? 0.0).toStringAsFixed(1);
        final capStr = (finding.estimatedValue ?? 0.0).toStringAsFixed(0);
        return (
          l10n.reviewFreezerOverloadedTitle,
          l10n.reviewFreezerOverloadedMessage(actStr, capStr),
        );

      case ProvisioningReviewKind.incompleteCoolingAssessment:
        return (
          l10n.reviewIncompleteCoolingTitle,
          l10n.reviewIncompleteCoolingMessage,
        );

      case ProvisioningReviewKind.weightVolumeInfo:
        return (
          l10n.reviewTotalWeightVolumeTitle,
          '',
        );
    }
  }

  String _resolveItemName(int? listItemId) {
    if (listItemId == null) return '';
    final it = data.allItems.where((i) => i.item.id == listItemId).firstOrNull;
    return it?.name ?? '';
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    ProvisioningReviewFinding finding,
  ) {
    final action = finding.action;

    switch (action.type) {
      case ProvisioningReviewActionType.searchOrAdd:
        return OutlinedButton.icon(
          icon: const Icon(Icons.search, size: 16),
          label: Text(l10n.reviewActionSearchAdd),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(48, 36),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            showSearch(
              context: context,
              delegate: CatalogSearchDelegate(
                data: data,
                parentContext: context,
                searchFieldLabel: l10n.searchCatalogPlaceholder,
              ),
            );
          },
        );

      case ProvisioningReviewActionType.assignShoppingStop:
        return OutlinedButton.icon(
          icon: const Icon(Icons.storefront_outlined, size: 16),
          label: Text(l10n.reviewActionAssignStop),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(48, 36),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            final it = data.allItems.where((i) => i.item.id == action.listItemId).firstOrNull;
            if (it != null) {
              AddOrEditItemSheet.show(context, data: data, item: it);
            }
          },
        );

      case ProvisioningReviewActionType.editItem:
        return OutlinedButton.icon(
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: Text(l10n.reviewActionEditItem),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(48, 36),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            final it = data.allItems.where((i) => i.item.id == action.listItemId).firstOrNull;
            if (it != null) {
              AddOrEditItemSheet.show(context, data: data, item: it);
            }
          },
        );

      case ProvisioningReviewActionType.noAction:
        return const SizedBox.shrink();
    }
  }
}

