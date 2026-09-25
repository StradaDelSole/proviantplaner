/// Bildschirm für den Einkaufsmodus je Stopp (SC-SHOP-01).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';

class ShoppingModeScreen extends ConsumerStatefulWidget {
  final int tripId;
  final int stopId;

  const ShoppingModeScreen({
    super.key,
    required this.tripId,
    required this.stopId,
  });

  @override
  ConsumerState<ShoppingModeScreen> createState() => _ShoppingModeScreenState();
}

class _ShoppingModeScreenState extends ConsumerState<ShoppingModeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dataAsync = ref.watch(tripShoppingListProvider(widget.tripId));

    return dataAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Fehler: $err'))),
      data: (data) {
        final stop = data.stops.where((s) => s.id == widget.stopId).firstOrNull ?? data.stops.first;
        final isFirstStop = data.stops.firstOrNull?.id == stop.id;

        // Artikel für diesen Stopp filtern
        final stopItems = data.allItems.where((it) {
          if (!it.isSelected) return false;
          final totalOtherAlloc = it.allocationsByStop.entries
              .where((e) => e.key != stop.id)
              .fold<int>(0, (sum, e) => sum + e.value.allocatedPackages);
          final count = it.packagesAtStop(
            stop.id,
            isFirstStop: isFirstStop,
            totalOtherAllocated: totalOtherAlloc,
          );
          return count > 0;
        }).toList();

        final totalCount = stopItems.length;
        final boughtCount = stopItems.where((it) => it.isBoughtAtStop(stop.id)).length;
        final progress = totalCount > 0 ? boughtCount / totalCount : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Einkauf Tag ${stop.dayNumber} · ${stop.name}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$boughtCount von $totalCount erledigt',
                  style: theme.proviantTypography.numberSmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined),
                tooltip: 'Ausgabe erfassen',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ausgabe erfassen folgt in Slice S5 (Bordkasse)')),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          body: stopItems.isEmpty
              ? const Center(child: Text('Keine Posten für diesen Stopp zugeordnet.'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: stopItems.length,
                  itemBuilder: (ctx, i) {
                    final it = stopItems[i];
                    final isBought = it.isBoughtAtStop(stop.id);
                    return _buildShoppingRow(context, it, isBought, stop.id, theme);
                  },
                ),
          bottomSheet: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => _finishShopping(context, totalCount, boughtCount, l10n),
                child: Text(l10n.shoppingDone),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShoppingRow(
    BuildContext context,
    ShoppingListItemView it,
    bool isBought,
    int stopId,
    ThemeData theme,
  ) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isBought ? 0.45 : 1.0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: SizedBox(
          width: 48,
          height: 48,
          child: Checkbox(
            value: isBought,
            onChanged: (val) async {
              if (val != null) {
                await ref.read(shoppingListServiceProvider).toggleBought(
                      tripId: widget.tripId,
                      listItemId: it.item.id,
                      shoppingStopId: stopId,
                      isBought: val,
                    );
                ref.invalidate(tripShoppingListProvider(widget.tripId));
              }
            },
          ),
        ),
        title: Text(
          it.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            decoration: isBought ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: Text(
          it.packDisplay,
          style: theme.proviantTypography.numberMedium.copyWith(
            fontWeight: FontWeight.bold,
            decoration: isBought ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }

  void _finishShopping(
    BuildContext context,
    int totalCount,
    int boughtCount,
    AppLocalizations l10n,
  ) {
    final unbought = totalCount - boughtCount;
    if (unbought > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.unboughtItemsDialogTitle),
          content: Text(
            '$unbought Posten nicht gekauft – für einen späteren Stopp merken oder streichen?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(l10n.dismiss),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(l10n.postpone),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }
}
