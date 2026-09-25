/// Hauptbildschirm für die Vorrats- und Einkaufsliste (SC-LST-01).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'widgets/catalog_search_delegate.dart';
import 'widgets/custom_item_sheet.dart';
import 'widgets/planning_view.dart';
import 'widgets/shopping_view.dart';
import 'widgets/trip_bottom_bar.dart';

class ShoppingListScreen extends ConsumerWidget {
  final int tripId;

  const ShoppingListScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final listDataAsync = ref.watch(tripShoppingListProvider(tripId));
    final viewMode = ref.watch(shoppingListViewModeProvider);
    final selectedStopId = ref.watch(selectedStopFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: listDataAsync.when(
          loading: () => Text(l10n.navShoppingList),
          error: (_, __) => Text(l10n.navShoppingList),
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.trip.name,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${data.trip.daysCount} Tage · ${data.stops.length} Stopps',
                style: theme.proviantTypography.numberSmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          listDataAsync.maybeWhen(
            data: (data) => IconButton(
              icon: const Icon(Icons.search),
              tooltip: l10n.searchHint,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: CatalogSearchDelegate(data: data),
                );
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onSelected: (val) {
              final data = listDataAsync.valueOrNull;
              if (data == null) return;
              if (val == 'custom') {
                CustomItemSheet.show(context, tripId: tripId, stops: data.stops);
              } else if (val == 'storage') {
                context.push('/trips/$tripId/storage');
              } else if (val == 'shop') {
                final targetStop = selectedStopId ?? data.stops.firstOrNull?.id;
                if (targetStop != null) {
                  context.push('/trips/$tripId/shop/$targetStop');
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'shop',
                child: Row(
                  children: [
                    Icon(Icons.shopping_basket_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Einkauf starten'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'custom',
                child: Row(
                  children: [
                    Icon(Icons.add, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(l10n.addCustomItem),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'storage',
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(l10n.storageTitle),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: listDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Fehler: $err')),
        data: (data) {
          return Column(
            children: [
              // Hinweis: Ernährungs-Tags sind kein Allergieschutz
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.allergenNotice,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Filterleiste: Sichten-Segment (Planen/Einkaufen) & Stopp-Filter-Chip
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    // Segmented Button
                    Expanded(
                      child: SegmentedButton<ShoppingListViewMode>(
                        segments: [
                          ButtonSegment(
                            value: ShoppingListViewMode.plan,
                            label: Text(l10n.planView),
                            icon: const Icon(Icons.list_alt),
                          ),
                          ButtonSegment(
                            value: ShoppingListViewMode.shop,
                            label: Text(l10n.shopView),
                            icon: const Icon(Icons.shopping_cart_outlined),
                          ),
                        ],
                        selected: {viewMode},
                        onSelectionChanged: (newSelection) {
                          ref.read(shoppingListViewModeProvider.notifier).state =
                              newSelection.first;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Stopp-Filter Chip
                    _buildStopFilterChip(context, ref, data, selectedStopId, theme, l10n),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Body je nach Sicht
              Expanded(
                child: viewMode == ShoppingListViewMode.plan
                    ? PlanningView(data: data)
                    : ShoppingView(data: data, selectedStopId: selectedStopId),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: TripBottomBar(
        tripId: tripId,
        currentIndex: 0,
      ),
    );
  }

  Widget _buildStopFilterChip(
    BuildContext context,
    WidgetRef ref,
    TripShoppingListData data,
    int? selectedStopId,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final activeStop = data.stops.where((s) => s.id == selectedStopId).firstOrNull;
    final label = activeStop != null ? 'Tag ${activeStop.dayNumber}' : l10n.allStops;

    return ActionChip(
      avatar: const Icon(Icons.storefront_outlined, size: 16),
      label: Text(label),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.all_inclusive),
                  title: Text(l10n.allStops),
                  selected: selectedStopId == null,
                  onTap: () {
                    ref.read(selectedStopFilterProvider.notifier).state = null;
                    Navigator.of(ctx).pop();
                  },
                ),
                const Divider(height: 1),
                ...data.stops.map((stop) => ListTile(
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text('Tag ${stop.dayNumber} · ${stop.name}'),
                      subtitle: stop.isInitial ? const Text('Basis-Ersteinkauf') : null,
                      selected: selectedStopId == stop.id,
                      onTap: () {
                        ref.read(selectedStopFilterProvider.notifier).state = stop.id;
                        Navigator.of(ctx).pop();
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}
