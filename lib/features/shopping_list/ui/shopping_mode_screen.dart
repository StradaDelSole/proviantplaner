/// Bildschirm für den Einkaufsmodus je Stopp (SC-SHOP-01 / UX-B / UX-Konzept 3.2 / HCD-SHOP-01).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/config/app_config.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/routing/not_found_screen.dart';
import 'package:proviantplaner/core/services/catalog_localization_service.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/kitty/data/kitty_providers.dart';
import 'package:proviantplaner/features/kitty/ui/widgets/expense_sheet.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';

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
  final Set<int> _pendingItemIds = <int>{};

  Future<void> _openExpenseSheet(ShoppingStop stop, AppLocalizations l10n) async {
    final kittyData = await ref.read(tripKittyDataProvider(widget.tripId).future);
    if (!mounted) return;
    await ExpenseSheet.show(
      context,
      tripId: widget.tripId,
      kittyModel: kittyData.model,
      members: kittyData.members,
      currency: kittyData.trip.currency,
      initialTitle: '${l10n.shoppingModeTitle} ${stop.name}',
    );
  }

  Future<void> _handleToggleBought(
    int listItemId,
    int stopId,
    bool isBought,
    AppLocalizations l10n,
  ) async {
    if (_pendingItemIds.contains(listItemId)) return;

    setState(() {
      _pendingItemIds.add(listItemId);
    });

    try {
      final service = ref.read(shoppingListServiceProvider);
      final success = await service.toggleBought(
            tripId: widget.tripId,
            listItemId: listItemId,
            shoppingStopId: stopId,
            isBought: isBought,
          );

      if (!mounted) return;

      if (!success) {
        _showToggleErrorSnackBar(
          listItemId: listItemId,
          stopId: stopId,
          desiredIsBought: isBought,
          l10n: l10n,
        );
        ref.invalidate(tripShoppingListProvider(widget.tripId));
      } else if (service.onTripDataChanged == null) {
        // Fallback für Testumgebungen mit rohem Service-Mock ohne onTripDataChanged-Verdrahtung
        ref.invalidate(tripShoppingListProvider(widget.tripId));
      }
      // Hinweis: Im regulären Betrieb löst ShoppingListService.onTripDataChanged
      // die Reaktivität über tripDataVersionProvider aus.
    } catch (_) {
      if (!mounted) return;
      _showToggleErrorSnackBar(
        listItemId: listItemId,
        stopId: stopId,
        desiredIsBought: isBought,
        l10n: l10n,
      );
      ref.invalidate(tripShoppingListProvider(widget.tripId));
    } finally {
      if (mounted) {
        setState(() {
          _pendingItemIds.remove(listItemId);
        });
      }
    }
  }

  void _showToggleErrorSnackBar({
    required int listItemId,
    required int stopId,
    required bool desiredIsBought,
    required AppLocalizations l10n,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.technicalErrorMessage),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l10n.retry,
          onPressed: () {
            _handleToggleBought(listItemId, stopId, desiredIsBought, l10n);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dataAsync = ref.watch(tripShoppingListProvider(widget.tripId));

    // 1. Initialer Fehler ohne Daten: Eigenständiger Fehlerbildschirm mit Retry
    if (dataAsync.hasError && !dataAsync.hasValue) {
      return Scaffold(
        key: const Key('shopping_mode_initial_error_scaffold'),
        appBar: AppBar(
          title: const Text(AppConfig.appName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/trips/${widget.tripId}');
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  l10n.technicalErrorTitle,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.technicalErrorMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('shopping_mode_initial_retry_button'),
                  onPressed: () => ref.invalidate(tripShoppingListProvider(widget.tripId)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Initiales Laden ohne vorherige Daten:
    if (dataAsync.isLoading && !dataAsync.hasValue) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 3. Vorhandene Daten (aktiv, während Reload oder mit Reload-Fehler):
    final data = dataAsync.value;
    if (data == null) {
      return NotFoundScreen(message: l10n.tripNotFound);
    }

    final stop = data.stops.where((s) => s.id == widget.stopId).firstOrNull;
    if (stop == null) {
      return NotFoundScreen(message: l10n.shoppingStopNotFound);
    }
    final isFirstStop = data.stops.firstOrNull?.id == stop.id;

    // Artikel für diesen Stopp filtern: Genau die Positionen der Liste mit Menge > 0 für diesen Stopp
    final stopItems = data.allItems.where((it) {
      if (!it.isOnList) return false;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.previousStep,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/trips/${widget.tripId}');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.shoppingDayTitle(stop.dayNumber, stop.name),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              l10n.shoppingProgress(boughtCount, totalCount),
              style: theme.proviantTypography.numberSmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) {
              final isConstrained = MediaQuery.sizeOf(context).width < 380 ||
                  MediaQuery.textScalerOf(context).scale(14) > 16;
              if (isConstrained) {
                return IconButton(
                  onPressed: () => _openExpenseSheet(stop, l10n),
                  icon: const Icon(Icons.receipt_long_outlined),
                  tooltip: l10n.fundAddExpense,
                );
              }
              return TextButton.icon(
                onPressed: () => _openExpenseSheet(stop, l10n),
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(l10n.fundAddExpense),
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
      body: Column(
        children: [
          if (dataAsync.hasError)
            Container(
              key: const Key('shopping_mode_reload_error_banner'),
              color: theme.colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.technicalErrorMessage,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                  TextButton(
                    key: const Key('shopping_mode_reload_retry_button'),
                    onPressed: () => ref.invalidate(tripShoppingListProvider(widget.tripId)),
                    child: Text(l10n.retry, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: stopItems.isEmpty
                ? Center(child: Text(l10n.noItemsForStop))
                : ListView(
                    key: const PageStorageKey('shopping_mode_list_view'),
                    padding: const EdgeInsets.only(bottom: 96),
                    children: data.departments.map((deptView) {
                      final deptItems = deptView.items.where((it) {
                        if (!it.isOnList) return false;
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

                      if (deptItems.isEmpty) return const SizedBox.shrink();

                      // Sortierung innerhalb der Abteilung: ungekaufte zuerst, gekaufte ans Ende
                      deptItems.sort((a, b) {
                        final aBought = a.isBoughtAtStop(stop.id);
                        final bBought = b.isBoughtAtStop(stop.id);
                        if (aBought == bBought) return 0;
                        return aBought ? 1 : -1;
                      });

                      return Column(
                        key: ValueKey('dept_${deptView.department.rawValue}'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Abteilungskopf
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                            child: Row(
                              children: [
                                Icon(deptView.icon, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    deptView.department.localizedName(context).toUpperCase(),
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${deptItems.where((it) => it.isBoughtAtStop(stop.id)).length}/${deptItems.length}',
                                  style: theme.proviantTypography.numberSmall.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...deptItems.map((it) {
                            final isBought = it.isBoughtAtStop(stop.id);
                            final totalOtherAlloc = it.allocationsByStop.entries
                                .where((e) => e.key != stop.id)
                                .fold<int>(0, (sum, e) => sum + e.value.allocatedPackages);
                            final count = it.packagesAtStop(
                              stop.id,
                              isFirstStop: isFirstStop,
                              totalOtherAllocated: totalOtherAlloc,
                            );
                            return _buildShoppingRow(context, it, count, isBought, stop.id, theme, l10n);
                          }),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
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
  }

  Widget _buildShoppingRow(
    BuildContext context,
    ShoppingListItemView it,
    int countAtStop,
    bool isBought,
    int stopId,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final size = it.effectivePackSize;
    final sizeFormatted = (size % 1 == 0) ? size.toInt().toString() : size.toStringAsFixed(1);
    final packUnit = it.variant?.pack.unit ?? it.unit;
    final stopPackDisplay = '$countAtStop × $sizeFormatted $packUnit';
    final isPending = _pendingItemIds.contains(it.item.id);

    return AnimatedOpacity(
      key: ValueKey('shopping_row_${it.item.id}'),
      duration: const Duration(milliseconds: 200),
      opacity: isPending ? 0.6 : (isBought ? 0.45 : 1.0),
      child: ListTile(
        key: ValueKey('shopping_tile_${it.item.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: SizedBox(
          width: 48,
          height: 48,
          child: Checkbox(
            key: ValueKey('shopping_checkbox_${it.item.id}'),
            value: isBought,
            onChanged: isPending
                ? null
                : (val) async {
                    if (val == null) return;
                    await _handleToggleBought(it.item.id, stopId, val, l10n);
                  },
          ),
        ),
        title: Text(
          it.localizedName(context),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            decoration: isBought ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: Text(
          stopPackDisplay,
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
            l10n.unboughtNoticeLaterOrDrop(unbought),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref.read(shoppingListServiceProvider).handleUnboughtItems(
                      tripId: widget.tripId,
                      currentStopId: widget.stopId,
                      postpone: false,
                    );
                ref.invalidate(tripShoppingListProvider(widget.tripId));
                if (context.mounted) {
                  _promptStorage(context, l10n);
                }
              },
              child: Text(l10n.dismiss),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _handlePostpone(context, unbought, l10n);
              },
              child: Text(l10n.postpone),
            ),
          ],
        ),
      );
    } else {
      _promptStorage(context, l10n);
    }
  }

  Future<void> _handlePostpone(BuildContext context, int unboughtCount, AppLocalizations l10n) async {
    final listData = await ref.read(shoppingListServiceProvider).loadShoppingList(widget.tripId);
    final currentStop = listData.stops.where((s) => s.id == widget.stopId).firstOrNull;
    if (currentStop == null) return;

    final laterStops = listData.stops.where((s) => s.dayNumber >= currentStop.dayNumber && s.id != widget.stopId).toList();

    if (laterStops.isNotEmpty) {
      final targetStop = laterStops.first;
      await ref.read(shoppingListServiceProvider).handleUnboughtItems(
            tripId: widget.tripId,
            currentStopId: widget.stopId,
            postpone: true,
            targetStopId: targetStop.id,
          );
      ref.invalidate(tripShoppingListProvider(widget.tripId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.itemsMovedToStopNotice(unboughtCount, targetStop.name))),
        );
        _promptStorage(context, l10n);
      }
    } else {
      if (!context.mounted) return;
      await _promptCreateFollowUpStop(context, unboughtCount, currentStop, listData.trip.daysCount, l10n);
    }
  }

  Future<void> _promptCreateFollowUpStop(
    BuildContext context,
    int unboughtCount,
    ShoppingStop currentStop,
    int totalTripDays,
    AppLocalizations l10n,
  ) async {
    int defaultDay = (currentStop.dayNumber + 1).clamp(1, totalTripDays);
    int selectedDay = defaultDay;
    final nameCtrl = TextEditingController(text: l10n.shoppingStopDayDefault(selectedDay));

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.createFollowUpStopTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.createFollowUpStopContent(unboughtCount)),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedDay,
                decoration: InputDecoration(
                  labelText: l10n.day,
                  border: const OutlineInputBorder(),
                ),
                items: List.generate(
                  totalTripDays,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${l10n.day} ${index + 1}'),
                  ),
                ),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      selectedDay = val;
                      nameCtrl.text = l10n.shoppingStopDayDefault(val);
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.name,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.createStopAndMove),
            ),
          ],
        ),
      ),
    );

    if (created == true && context.mounted) {
      final tripService = ref.read(tripServiceProvider);
      final finalName = nameCtrl.text.trim().isNotEmpty
          ? nameCtrl.text.trim()
          : l10n.shoppingStopDayDefault(selectedDay);
      final newStopId = await tripService.addShoppingStop(
        tripId: widget.tripId,
        name: finalName,
        dayNumber: selectedDay,
      );

      await ref.read(shoppingListServiceProvider).handleUnboughtItems(
            tripId: widget.tripId,
            currentStopId: widget.stopId,
            postpone: true,
            targetStopId: newStopId,
          );
      ref.invalidate(tripShoppingListProvider(widget.tripId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.itemsMovedToStopNotice(unboughtCount, finalName))),
        );
        _promptStorage(context, l10n);
      }
    }
  }

  void _promptStorage(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.shoppingFinishedTitle),
        content: Text(l10n.shoppingFinishedContent),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(tripServiceProvider).setTripPhase(widget.tripId, TripPhase.storage);
              if (context.mounted) {
                context.go('/trips/${widget.tripId}');
              }
            },
            child: Text(l10n.later),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.inventory_2_outlined),
            label: Text(l10n.storeNow),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(tripServiceProvider).setTripPhase(widget.tripId, TripPhase.storage);
              if (context.mounted) {
                context.push('/trips/${widget.tripId}/storage');
              }
            },
          ),
        ],
      ),
    );
  }
}
