/// Hauptbildschirm für die Vorrats- und Einkaufsliste (SC-LST-01 / FEEDBACK_R1 Punkt 5 & 7).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/routing/not_found_screen.dart';
import 'package:proviantplaner/core/services/pdf_providers.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'widgets/catalog_search_delegate.dart';
import 'widgets/custom_item_sheet.dart';
import 'flight_strip/flight_strip_board_view.dart';
import 'widgets/planning_view.dart';
import 'widgets/provisioning_review_sheet.dart';
import 'widgets/shopping_view.dart';

class ShoppingListScreen extends ConsumerWidget {
  final int tripId;

  const ShoppingListScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final listDataAsync = ref.watch(tripShoppingListProvider(tripId));
    final sortMode = ref.watch(shoppingListViewModeProvider);
    final selectedStopId = ref.watch(selectedStopFilterProvider);

    // 1. Initialer Fehler ohne Daten
    if (listDataAsync.hasError && !listDataAsync.hasValue) {
      return NotFoundScreen(message: l10n.tripNotFound);
    }

    // 2. Initiales Laden ohne vorherige Daten
    if (listDataAsync.isLoading && !listDataAsync.hasValue) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.previousStep,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/trips/$tripId');
              }
            },
          ),
          title: Text(l10n.navShoppingList),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 3. Vorhandene Daten (aktiv oder während Reload):
    final data = listDataAsync.value;
    if (data == null) {
      return NotFoundScreen(message: l10n.tripNotFound);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.previousStep,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/trips/$tripId');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.trip.name,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              l10n.tripDaysStopsSubtitle(data.trip.daysCount, data.stops.length),
              style: theme.proviantTypography.numberSmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.searchHint,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CatalogSearchDelegate(
                  data: data,
                  parentContext: context,
                  searchFieldLabel: l10n.searchCatalogPlaceholder,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.fact_check_outlined),
            tooltip: l10n.reviewButtonLabel,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () {
              ProvisioningReviewSheet.show(context, data: data);
            },
          ),
          Builder(
            builder: (ctx) {
              final isFlightBoardActive = ref.watch(flightStripBoardEnabledProvider) &&
                  ref.watch(shoppingListViewModeProvider) == ShoppingListSortMode.category;
              return IconButton(
                key: const ValueKey('toggle_flight_strip_board_button'),
                icon: Icon(isFlightBoardActive
                    ? Icons.table_rows_outlined
                    : Icons.view_agenda_outlined),
                tooltip: isFlightBoardActive
                    ? l10n.switchToClassicList
                    : l10n.switchToFlightStripBoard,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () {
                  if (isFlightBoardActive) {
                    ref.read(shoppingListViewModeProvider.notifier).state = ShoppingListSortMode.department;
                  } else {
                    ref.read(flightStripBoardEnabledProvider.notifier).state = true;
                    ref.read(shoppingListViewModeProvider.notifier).state = ShoppingListSortMode.category;
                  }
                },
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onSelected: (val) {
              final data = listDataAsync.valueOrNull;
              if (data == null) return;
              if (val == 'review') {
                ProvisioningReviewSheet.show(context, data: data);
              } else if (val == 'custom') {
                CustomItemSheet.show(context, tripId: tripId, stops: data.stops);
              } else if (val == 'storage') {
                context.push('/trips/$tripId/storage');
              } else if (val == 'shop') {
                final targetStop = selectedStopId ?? data.stops.firstOrNull?.id;
                if (targetStop != null) {
                  context.push('/trips/$tripId/shop/$targetStop');
                }
              } else if (val == 'pdf') {
                _exportPdf(context, ref, data);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'review',
                child: Row(
                  children: [
                    Icon(Icons.fact_check_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(l10n.reviewButtonLabel),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'shop',
                child: Row(
                  children: [
                    Icon(Icons.shopping_basket_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(l10n.startShopping),
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
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(l10n.exportShoppingListPdf),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Hinweis 1: Ernährungs-Tags sind kein Allergieschutz
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
          // Hinweis 2 (FEEDBACK_R1 Punkt 1): Längere Törns ab 15 Tagen
          if (data.trip.daysCount >= 15)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.longTripStopsNotice,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Sortier-Umschalter und Stopp-Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final segmented = SegmentedButton<ShoppingListSortMode>(
                  segments: [
                    ButtonSegment(
                      value: ShoppingListSortMode.category,
                      label: Text(l10n.byCategory),
                      icon: const Icon(Icons.category_outlined),
                    ),
                    ButtonSegment(
                      value: ShoppingListSortMode.department,
                      label: Text(l10n.byDepartment),
                      icon: const Icon(Icons.storefront_outlined),
                    ),
                  ],
                  selected: {sortMode},
                  onSelectionChanged: (newSelection) {
                    ref.read(shoppingListViewModeProvider.notifier).state =
                        newSelection.first;
                  },
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      segmented,
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildStopFilterChip(context, ref, data, selectedStopId, theme, l10n),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: segmented),
                    const SizedBox(width: 8),
                    _buildStopFilterChip(context, ref, data, selectedStopId, theme, l10n),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Einheitliche Liste je nach Sortierung - permanent gemountet mit stabilen Keys
          Expanded(
            child: sortMode == ShoppingListSortMode.category
                ? (ref.watch(flightStripBoardEnabledProvider)
                    ? FlightStripBoardView(
                        key: ValueKey('flight_strip_board_view_${data.trip.id}'),
                        data: data,
                        selectedStopId: selectedStopId,
                      )
                    : PlanningView(
                        key: ValueKey('planning_view_${data.trip.id}'),
                        data: data,
                        selectedStopId: selectedStopId,
                      ))
                : ShoppingView(
                    key: ValueKey('shopping_view_${data.trip.id}'),
                    data: data,
                    selectedStopId: selectedStopId,
                  ),
          ),
        ],
      ),
      floatingActionButton: (sortMode == ShoppingListSortMode.category &&
              ref.watch(flightStripBoardEnabledProvider))
          ? null
          : FloatingActionButton.extended(
              heroTag: 'fab_add_position',
              icon: const Icon(Icons.add),
              label: Text(l10n.item),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: CatalogSearchDelegate(
                    data: data,
                    parentContext: context,
                    searchFieldLabel: l10n.searchCatalogPlaceholder,
                  ),
                );
              },
            ),
      bottomNavigationBar: (sortMode == ShoppingListSortMode.category &&
              ref.watch(flightStripBoardEnabledProvider))
          ? null
          : Builder(
              builder: (ctx) {
                final activeStop = data.stops.where((s) => s.id == selectedStopId).firstOrNull ?? data.stops.firstOrNull;
                final stopLabel = activeStop != null
                    ? '${l10n.day} ${activeStop.dayNumber} · ${activeStop.name}'
                    : l10n.initialShopping;

                return SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            icon: const Icon(Icons.shopping_basket_outlined, size: 20),
                            label: Text('${l10n.startShopping} · $stopLabel'),
                            onPressed: () {
                              final targetStop = activeStop?.id ?? data.stops.firstOrNull?.id;
                              if (targetStop != null) {
                                context.push('/trips/$tripId/shop/$targetStop');
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          tooltip: l10n.switchStop,
                          icon: const Icon(Icons.swap_horiz),
                          onPressed: () => _openStopSelection(context, ref, data, selectedStopId, l10n),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _openStopSelection(
    BuildContext context,
    WidgetRef ref,
    TripShoppingListData data,
    int? selectedStopId,
    AppLocalizations l10n,
  ) {
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
                  title: Text('${l10n.day} ${stop.dayNumber} · ${stop.name}'),
                  subtitle: stop.isInitial ? Text(l10n.initialShopping) : null,
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
    final label = activeStop != null ? '${l10n.day} ${activeStop.dayNumber}' : l10n.allStops;

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
                      title: Text('${l10n.day} ${stop.dayNumber} · ${stop.name}'),
                      subtitle: stop.isInitial ? Text(l10n.initialShopping) : null,
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

  Future<void> _exportPdf(BuildContext context, WidgetRef ref, TripShoppingListData data) async {
    final pdfService = ref.read(pdfExportServiceProvider);
    final selectedStopId = ref.read(selectedStopFilterProvider);
    final stop = selectedStopId != null
        ? data.stops.where((s) => s.id == selectedStopId).firstOrNull
        : null;

    final bytes = await pdfService.generateShoppingListPdf(
      trip: data.trip,
      items: data.allItems,
      currentStop: stop,
    );

    await pdfService.shareOrPrintPdf(
      bytes: bytes,
      filename: 'Einkaufsliste_${data.trip.name.replaceAll(' ', '_')}.pdf',
      subject: 'Einkaufsliste ${data.trip.name}',
    );
  }
}
