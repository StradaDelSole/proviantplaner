/// Törn-Übersicht – das Rückgrat der Törn-Verwaltung (UX-A, UX-Konzept 2.3).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/features/kitty/data/kitty_providers.dart';
import 'package:proviantplaner/features/kitty/data/kitty_service.dart';
import 'package:proviantplaner/features/kitty/ui/widgets/expense_sheet.dart';
import 'package:proviantplaner/features/kitty/ui/widgets/payment_sheet.dart';
import 'package:proviantplaner/features/shopping_list/data/delivery_order_service.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/delivery_config_sheet.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/order_preview_sheet.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/delivery_received_sheet.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/core/routing/not_found_screen.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';
import 'package:proviantplaner/features/trip/ui/widgets/crew_member_dialog.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';

class TripOverviewScreen extends ConsumerStatefulWidget {
  final int tripId;

  const TripOverviewScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripOverviewScreen> createState() => _TripOverviewScreenState();
}

class _TripOverviewScreenState extends ConsumerState<TripOverviewScreen> {
  Trip? _trip;
  List<CrewMember> _crew = [];
  List<TripDay> _days = [];
  List<ShoppingStop> _stops = [];
  List<ListItem> _items = [];
  Map<int, DeliveryOrder> _deliveryOrders = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTripDetails();
  }

  @override
  void didUpdateWidget(TripOverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadTripDetails();
  }

  Future<void> _loadTripDetails() async {
    final db = ref.read(databaseProvider);
    final trip = await db.tripDao.getTripById(widget.tripId);
    final crew = await db.tripDao.getCrewForTrip(widget.tripId);
    final days = await db.tripDao.getDaysForTrip(widget.tripId);
    final stops = await db.tripDao.getShoppingStopsForTrip(widget.tripId);
    final items = await db.listItemDao.getListItemsForTrip(widget.tripId);
    final deliveryService = ref.read(deliveryOrderServiceProvider);
    final deliveryOrders = await deliveryService.getOrdersForTrip(widget.tripId);

    if (mounted) {
      setState(() {
        _trip = trip;
        _crew = crew;
        _days = days;
        _stops = stops;
        _items = items;
        _deliveryOrders = deliveryOrders;
        _isLoading = false;
      });
    }
  }

  int _calculateCurrentStep(TripKittyData kittyData) {
    if (_trip == null) return 1;
    if (_trip!.isArchived || _trip!.phase == TripPhase.conclusion) {
      return 4;
    }
    if (_trip!.phase == TripPhase.underway || kittyData.expenses.isNotEmpty) {
      return 3;
    }
    if (_trip!.phase == TripPhase.storage || _trip!.phase == TripPhase.shopping) {
      return 2;
    }
    final hasAdopted = _items.any((it) => it.isAdopted || it.isCustom);
    if (hasAdopted) {
      return 2;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final kittyAsync = ref.watch(tripKittyDataProvider(widget.tripId));

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tripOverviewTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_trip == null) {
      return NotFoundScreen(message: l10n.tripNotFound);
    }

    return kittyAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(_trip!.name)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: Text(_trip!.name)),
        body: Center(child: Text('${l10n.genericError}: $err')),
      ),
      data: (kittyData) {
        final currentStep = _calculateCurrentStep(kittyData);
        final hasStarted = DateTime.now().isAfter(_trip!.startDate) || kittyData.expenses.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: l10n.previousStep,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            title: Text(_trip!.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.editTrip,
                onPressed: () {
                  _showEditTripDialog(context, l10n);
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(theme, l10n),
                      const SizedBox(height: 24),
                      _buildWorkflowStepCard(
                        theme: theme,
                        stepNumber: 1,
                        title: l10n.navShoppingList,
                        subtitle: l10n.itemsOnListCount(_items.where((it) => it.isAdopted || it.isCustom).length),
                        actionLabel: l10n.editList,
                        icon: Icons.inventory_2_outlined,
                        isCurrent: currentStep == 1,
                        isDone: currentStep > 1,
                        onAction: () => context.push('/trips/${widget.tripId}/shopping-list'),
                      ),
                      _buildStepConnector(theme),
                      _buildShoppingStepCard(
                        theme: theme,
                        l10n: l10n,
                        isCurrent: currentStep == 2,
                        isDone: currentStep > 2,
                      ),
                      _buildStepConnector(theme),
                      _buildKittyStepCard(
                        theme: theme,
                        l10n: l10n,
                        kittyData: kittyData,
                        isCurrent: currentStep == 3,
                        isDone: currentStep > 3,
                      ),
                      _buildStepConnector(theme),
                      _buildSettlementStepCard(
                        theme: theme,
                        l10n: l10n,
                        kittyData: kittyData,
                        isCurrent: currentStep == 4,
                        isDone: false,
                      ),
                      const SizedBox(height: 24),
                      _buildDaysInDetailTile(theme, l10n),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton: hasStarted
              ? FloatingActionButton.extended(
                  onPressed: () => _openExpenseSheet(context, kittyData),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.recordExpense),
                )
              : null,
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations l10n) {
    final start = _trip!.startDate;
    final dateStr = '${start.day}.${start.month}.${start.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.inventory_2_outlined, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _trip!.name,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr · ${_crew.length} ${l10n.persons} · ${_trip!.daysCount} ${l10n.day}',
                  style: theme.textTheme.bodyMedium?.copyWith(
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

  Widget _buildStepConnector(ThemeData theme) {
    return Center(
      child: Container(
        width: 2,
        height: 16,
        color: theme.colorScheme.outlineVariant,
      ),
    );
  }

  Widget _buildWorkflowStepCard({
    required ThemeData theme,
    required int stepNumber,
    required String title,
    required String subtitle,
    required String actionLabel,
    required IconData icon,
    required bool isCurrent,
    required bool isDone,
    required VoidCallback onAction,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isDone
                      ? theme.colorScheme.secondaryContainer
                      : (isCurrent ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest),
                  child: isDone
                      ? Icon(Icons.check, size: 16, color: theme.colorScheme.onSecondaryContainer)
                      : Text(
                          '$stepNumber',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.outline,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShoppingStepCard({
    required ThemeData theme,
    required AppLocalizations l10n,
    required bool isCurrent,
    required bool isDone,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isDone
                      ? theme.colorScheme.secondaryContainer
                      : (isCurrent ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest),
                  child: isDone
                      ? Icon(Icons.check, size: 16, color: theme.colorScheme.onSecondaryContainer)
                      : Text(
                          '2',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.outline,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.shopView, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        l10n.shoppingStopsCount(_stops.length),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                if (_stops.isNotEmpty)
                  FilledButton.tonal(
                    onPressed: () => context.push('/trips/${widget.tripId}/shop/${_stops.first.id}'),
                    child: Text(l10n.startShopping),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ..._stops.map((s) {
                  final order = _deliveryOrders[s.id];
                  final isDelivery = order?.isDelivery ?? false;

                  if (isDelivery && order != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.local_shipping_outlined, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${l10n.day} ${s.dayNumber} · ${s.name} (${l10n.deliveryOrder})',
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: l10n.adjustDeliveryDetails,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () => _configureDelivery(s, order),
                                ),
                              ],
                            ),
                            if (order.isDelivered) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(l10n.orderReceived, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => _openOrderPreview(s, order),
                                    child: Text(l10n.viewOrder),
                                  ),
                                ],
                              ),
                            ] else if (order.isOrdered) ...[
                              const SizedBox(height: 4),
                              Text(
                                order.formattedOrderedAt,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  FilledButton.tonal(
                                    onPressed: () => _openDeliveryReceived(s, order),
                                    child: Text(l10n.orderReceived),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => _openOrderPreview(s, order),
                                    child: Text(l10n.viewOrder),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              FilledButton.tonal(
                                onPressed: () => _openOrderPreview(s, order),
                                child: Text(l10n.sendOrder),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.storefront_outlined, size: 16, color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${l10n.day} ${s.dayNumber} · ${s.name}', style: theme.textTheme.bodyMedium),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: l10n.edit,
                          onPressed: () => _showEditStopDialog(context, s, l10n),
                        ),
                        if (!s.isInitial)
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                            tooltip: l10n.delete,
                            onPressed: () => _deleteStop(context, s, l10n),
                          ),
                        IconButton(
                          icon: const Icon(Icons.local_shipping_outlined, size: 18),
                          tooltip: l10n.createAsDelivery,
                          onPressed: () => _configureDelivery(s, null),
                        ),
                        TextButton(
                          onPressed: () => context.push('/trips/${widget.tripId}/shop/${s.id}'),
                          child: Text(l10n.startTrip),
                        ),
                      ],
                    ),
                  );
                }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.addShoppingStop),
              onPressed: () => _showAddStopDialog(context, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _configureDelivery(ShoppingStop s, DeliveryOrder? existing) async {
    final defaultDate = s.dayNumber == 1
        ? _trip!.startDate
        : _trip!.startDate.add(Duration(days: s.dayNumber - 1));
    await DeliveryConfigSheet.show(
      context,
      tripId: widget.tripId,
      stopId: s.id,
      stopName: s.name,
      initialOrder: existing,
      defaultDate: defaultDate,
    );
    await _loadTripDetails();
  }

  Future<void> _openOrderPreview(ShoppingStop s, DeliveryOrder order) async {
    final listData = await ref.read(tripShoppingListProvider(widget.tripId).future);
    final isFirstStop = listData.stops.firstOrNull?.id == s.id;
    final stopItems = listData.allItems.where((it) {
      if (!it.isOnList) return false;
      final totalOtherAlloc = it.allocationsByStop.entries
          .where((e) => e.key != s.id)
          .fold<int>(0, (sum, e) => sum + e.value.allocatedPackages);
      final count = it.packagesAtStop(
        s.id,
        isFirstStop: isFirstStop,
        totalOtherAllocated: totalOtherAlloc,
      );
      return count > 0;
    }).toList();

    if (!mounted) return;
    await OrderPreviewSheet.show(
      context,
      trip: _trip!,
      stop: s,
      order: order,
      items: stopItems,
      onOrderSent: () => _loadTripDetails(),
    );
    await _loadTripDetails();
  }

  Future<void> _openDeliveryReceived(ShoppingStop s, DeliveryOrder order) async {
    final listData = await ref.read(tripShoppingListProvider(widget.tripId).future);
    final isFirstStop = listData.stops.firstOrNull?.id == s.id;
    final stopItems = listData.allItems.where((it) {
      if (!it.isOnList) return false;
      final totalOtherAlloc = it.allocationsByStop.entries
          .where((e) => e.key != s.id)
          .fold<int>(0, (sum, e) => sum + e.value.allocatedPackages);
      final count = it.packagesAtStop(
        s.id,
        isFirstStop: isFirstStop,
        totalOtherAllocated: totalOtherAlloc,
      );
      return count > 0;
    }).toList();

    if (!mounted) return;
    await DeliveryReceivedSheet.show(
      context,
      trip: _trip!,
      stop: s,
      items: stopItems,
      allStops: listData.stops,
      onReceived: () => _loadTripDetails(),
    );
    await _loadTripDetails();
  }

  Widget _buildKittyStepCard({
    required ThemeData theme,
    required AppLocalizations l10n,
    required TripKittyData kittyData,
    required bool isCurrent,
    required bool isDone,
  }) {
    final balanceEuros = (kittyData.cashBalanceCents / 100.0).toStringAsFixed(2);
    final treasurerName = kittyData.treasurer?.name ?? l10n.notSpecified;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isDone
                      ? theme.colorScheme.secondaryContainer
                      : (isCurrent ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest),
                  child: isDone
                      ? Icon(Icons.check, size: 16, color: theme.colorScheme.onSecondaryContainer)
                      : Text(
                          '3',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.outline,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.underwayFund, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('${l10n.treasurerLabel} $treasurerName', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => context.push('/trips/${widget.tripId}/kitty'),
                  child: Text(l10n.openFund),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.balanceLabel, style: theme.textTheme.bodyMedium),
                  Text(
                    '$balanceEuros €',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrains Mono',
                      color: kittyData.cashBalanceCents < 0 ? theme.colorScheme.error : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l10n.recordExpense),
                    onPressed: () => _openExpenseSheet(context, kittyData),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.arrow_downward),
                    label: Text(l10n.deposit),
                    onPressed: () => _openPaymentSheet(context, kittyData),
                  ),
                ),
              ],
            ),
            if (kittyData.expenses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l10n.recentExpenses, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline)),
              const SizedBox(height: 4),
              ...kittyData.expenses.take(3).map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.title, style: theme.textTheme.bodySmall),
                        Text(
                          '${(e.amountInCents / 100.0).toStringAsFixed(2)} €',
                          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'JetBrains Mono'),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementStepCard({
    required ThemeData theme,
    required AppLocalizations l10n,
    required TripKittyData kittyData,
    required bool isCurrent,
    required bool isDone,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isCurrent ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    '4',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.settle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(l10n.settlementPaymentsCount(kittyData.transfers.length),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => context.push('/trips/${widget.tripId}/kitty/settlement'),
                  child: Text(l10n.settle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysInDetailTile(ThemeData theme, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(l10n.daysInDetail, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text(l10n.daysInTripCount(_days.length), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(l10n.openTimeline),
                      onPressed: () => context.push('/trips/${widget.tripId}/timeline'),
                    ),
                  ),
                ],
              ),
            ),
            ..._days.map((day) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: theme.colorScheme.surfaceContainerLowest,
                  child: ListTile(
                    title: Text('${l10n.day} ${day.dayNumber} ${day.portName != null && day.portName!.isNotEmpty ? "· ${day.portName}" : ""}'),
                    subtitle: Row(
                      children: [
                        FilterChip(
                          label: Text(l10n.lunchRestaurant),
                          selected: day.lunchRestaurant,
                          onSelected: (val) async {
                            final service = ref.read(tripServiceProvider);
                            await service.toggleLunchRestaurant(day);
                            await _loadTripDetails();
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(l10n.eveningRestaurant),
                          selected: day.dinnerRestaurant,
                          onSelected: (val) async {
                            final service = ref.read(tripServiceProvider);
                            await service.toggleEveningRestaurant(day);
                            await _loadTripDetails();
                          },
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _openExpenseSheet(BuildContext context, TripKittyData kittyData) async {
    await ExpenseSheet.show(
      context,
      tripId: widget.tripId,
      kittyModel: kittyData.model,
      members: kittyData.members,
    );
    ref.invalidate(tripKittyDataProvider(widget.tripId));
  }

  Future<void> _openPaymentSheet(BuildContext context, TripKittyData kittyData) async {
    await PaymentSheet.show(
      context,
      tripId: widget.tripId,
      members: kittyData.members,
    );
    ref.invalidate(tripKittyDataProvider(widget.tripId));
  }

  Future<void> _showAddStopDialog(BuildContext context, AppLocalizations l10n) async {
    final nameCtrl = TextEditingController(text: l10n.shoppingStopDayDefault(_days.isNotEmpty ? _days.last.dayNumber : 1));
    int selectedDay = _days.isNotEmpty ? _days.last.dayNumber : 1;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.addShoppingStop),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.name,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedDay,
                decoration: InputDecoration(
                  labelText: l10n.day,
                  border: const OutlineInputBorder(),
                ),
                items: List.generate(
                  _days.length,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${l10n.day} ${index + 1}'),
                  ),
                ),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedDay = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  final service = ref.read(tripServiceProvider);
                  await service.addShoppingStop(
                    tripId: widget.tripId,
                    name: name,
                    dayNumber: selectedDay,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) _loadTripDetails();
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditStopDialog(BuildContext context, ShoppingStop stop, AppLocalizations l10n) async {
    final nameCtrl = TextEditingController(text: stop.name);
    int selectedDay = stop.dayNumber;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.edit),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.name,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              if (!stop.isInitial) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedDay,
                  decoration: InputDecoration(
                    labelText: l10n.day,
                    border: const OutlineInputBorder(),
                  ),
                  items: List.generate(
                    _days.length,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${l10n.day} ${index + 1}'),
                    ),
                  ),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedDay = val);
                    }
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  final service = ref.read(tripServiceProvider);
                  await service.updateShoppingStop(
                    stop.copyWith(
                      name: name,
                      dayNumber: selectedDay,
                    ),
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) _loadTripDetails();
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteStop(BuildContext context, ShoppingStop stop, AppLocalizations l10n) async {
    if (stop.isInitial) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.firstStopProtected)),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteStopConfirmTitle),
        content: Text(l10n.deleteStopConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final service = ref.read(tripServiceProvider);
      await service.deleteShoppingStop(stop.id);
      if (mounted) _loadTripDetails();
    }
  }

  Future<void> _addCrewMember(BuildContext context, AppLocalizations l10n) async {
    final input = await showDialog<CrewMemberInput>(
      context: context,
      builder: (ctx) => const CrewMemberDialog(),
    );
    if (input != null) {
      final db = ref.read(databaseProvider);
      await db.tripDao.addCrewMember(CrewMembersCompanion.insert(
        tripId: widget.tripId,
        name: input.name,
        isChild: Value(!input.isAdult),
        isVegetarian: Value(input.isVegetarian),
        isNonDrinker: Value(input.noAlcohol),
        customEatLevel: Value(input.customEatLevel?.rawValue),
        customDrinkLevel: Value(input.customDrinkLevel?.rawValue),
      ));
      await ref.read(tripServiceProvider).recalculateTrip(widget.tripId);
      if (mounted) _loadTripDetails();
    }
  }

  Future<void> _editCrewMember(BuildContext context, CrewMember member, AppLocalizations l10n) async {
    EatProfileLevel? eat;
    if (member.customEatLevel != null) {
      try {
        eat = EatProfileLevel.fromString(member.customEatLevel!);
      } catch (_) {}
    }
    DrinkProfileLevel? drink;
    if (member.customDrinkLevel != null) {
      try {
        drink = DrinkProfileLevel.fromString(member.customDrinkLevel!);
      } catch (_) {}
    }

    final initial = CrewMemberInput(
      id: member.id.toString(),
      name: member.name,
      isAdult: !member.isChild,
      isVegetarian: member.isVegetarian,
      noAlcohol: member.isNonDrinker,
      customEatLevel: eat,
      customDrinkLevel: drink,
    );

    final input = await showDialog<CrewMemberInput>(
      context: context,
      builder: (ctx) => CrewMemberDialog(initialMember: initial),
    );
    if (input != null) {
      final db = ref.read(databaseProvider);
      await db.tripDao.updateCrewMember(member.copyWith(
        name: input.name,
        isChild: !input.isAdult,
        isVegetarian: input.isVegetarian,
        isNonDrinker: input.noAlcohol,
        customEatLevel: Value(input.customEatLevel?.rawValue),
        customDrinkLevel: Value(input.customDrinkLevel?.rawValue),
      ));
      await ref.read(tripServiceProvider).recalculateTrip(widget.tripId);
      if (mounted) _loadTripDetails();
    }
  }

  Future<void> _deleteCrewMember(CrewMember member, AppLocalizations l10n) async {
    if (_crew.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.atLeastOnePersonRequired)),
      );
      return;
    }
    final db = ref.read(databaseProvider);
    await db.tripDao.deleteCrewMember(member.id);
    await ref.read(tripServiceProvider).recalculateTrip(widget.tripId);
    if (mounted) _loadTripDetails();
  }

  Future<void> _showEditTripDialog(BuildContext context, AppLocalizations l10n) async {
    final nameCtrl = TextEditingController(text: _trip!.name);
    final boatNameCtrl = TextEditingController(text: _trip!.boatName ?? '');
    final boatManufacturerCtrl = TextEditingController(text: _trip!.boatManufacturer ?? '');
    final boatModelCtrl = TextEditingController(text: _trip!.boatModel ?? '');
    DateTime selectedDate = _trip!.startDate;
    int daysCount = _trip!.daysCount;
    int lunchCount = _days.where((d) => d.lunchRestaurant).length;
    int dinnerCount = _days.where((d) => d.dinnerRestaurant).length;
    int fridgeCapacity = _trip!.fridgeCapacity;
    bool hasFreezer = _trip!.hasFreezer;
    int freezerCapacity = _trip!.freezerCapacity;
    int waterTankLiters = _trip!.waterTankLiters;
    bool isWaterTankDrinkable = _trip!.isWaterTankDrinkable;
    bool hasWatermaker = _trip!.hasWatermaker;

    final fridgeCtrl = TextEditingController(text: fridgeCapacity.toString());
    final freezerCtrl = TextEditingController(text: freezerCapacity.toString());
    final waterCtrl = TextEditingController(text: waterTankLiters.toString());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.95,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, scrollController) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme = Theme.of(ctx);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.editTrip, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.tripName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.startDate),
                    subtitle: Text('${selectedDate.day}.${selectedDate.month}.${selectedDate.year}'),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2040),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.daysCount, style: theme.textTheme.bodyMedium),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: daysCount > 1
                                ? () => setSheetState(() {
                                      daysCount--;
                                      if (lunchCount > daysCount) lunchCount = daysCount;
                                      if (dinnerCount > daysCount) dinnerCount = daysCount;
                                    })
                                : null,
                          ),
                          Text('$daysCount', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: daysCount < 180
                                ? () => setSheetState(() => daysCount++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(
                    l10n.mealsSectionTitle,
                    style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.lunchInRestaurant, style: theme.textTheme.bodyMedium),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: lunchCount > 0
                                ? () => setSheetState(() => lunchCount--)
                                : null,
                          ),
                          Text('$lunchCount', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: lunchCount < daysCount
                                ? () => setSheetState(() => lunchCount++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.dinnerInRestaurant, style: theme.textTheme.bodyMedium),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: dinnerCount > 0
                                ? () => setSheetState(() => dinnerCount--)
                                : null,
                          ),
                          Text('$dinnerCount', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: dinnerCount < daysCount
                                ? () => setSheetState(() => dinnerCount++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(
                    l10n.boatSectionTitle,
                    style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  if (_trip!.boatProfileId != null) ...[
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerLowest,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.directions_boat_outlined, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.linkedBoatProfile,
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.sync, size: 16),
                              label: Text(l10n.resyncBoatProfile),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: ctx,
                                  builder: (c) => AlertDialog(
                                    title: Text(l10n.resyncBoatProfile),
                                    content: Text(l10n.resyncBoatProfileConfirm),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(c).pop(false),
                                        child: Text(l10n.cancel),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.of(c).pop(true),
                                        child: Text(l10n.save),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  final ok = await ref.read(tripServiceProvider).resyncTripBoatProfile(widget.tripId);
                                  if (ok) {
                                    await _loadTripDetails();
                                    setSheetState(() {
                                      boatNameCtrl.text = _trip!.boatName ?? '';
                                      boatManufacturerCtrl.text = _trip!.boatManufacturer ?? '';
                                      boatModelCtrl.text = _trip!.boatModel ?? '';
                                      fridgeCapacity = _trip!.fridgeCapacity;
                                      fridgeCtrl.text = fridgeCapacity.toString();
                                      hasFreezer = _trip!.hasFreezer;
                                      freezerCapacity = _trip!.freezerCapacity;
                                      freezerCtrl.text = freezerCapacity.toString();
                                      waterTankLiters = _trip!.waterTankLiters;
                                      waterCtrl.text = waterTankLiters.toString();
                                      isWaterTankDrinkable = _trip!.isWaterTankDrinkable;
                                      hasWatermaker = _trip!.hasWatermaker;
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l10n.resyncSuccess)),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: boatNameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.boatName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: boatManufacturerCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.boatManufacturer,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: boatModelCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.boatModel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fridgeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.fridgeCapacity,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.freezerAvailable),
                    value: hasFreezer,
                    onChanged: (val) => setSheetState(() => hasFreezer = val),
                  ),
                  if (hasFreezer) ...[
                    const SizedBox(height: 4),
                    TextField(
                      controller: freezerCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.freezerCapacityLiters,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: waterCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.waterTankLiters,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.waterTankDrinkable),
                    subtitle: Text(l10n.waterTankDrinkableSubtitle),
                    value: isWaterTankDrinkable,
                    onChanged: (val) => setSheetState(() => isWaterTankDrinkable = val),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.hasWatermaker),
                    subtitle: Text(l10n.hasWatermakerSubtitle),
                    value: hasWatermaker,
                    onChanged: (val) => setSheetState(() => hasWatermaker = val),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.crewSectionTitle} (${_crew.length} ${l10n.persons})',
                          style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: Text(l10n.addCrewMember),
                        onPressed: () async {
                          await _addCrewMember(context, l10n);
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                  ..._crew.map((member) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?'),
                        ),
                        title: Text(member.name),
                        subtitle: Text([
                          !member.isChild ? l10n.isAdult : l10n.isChild,
                          if (member.isVegetarian) l10n.isVegetarian,
                          if (member.isNonDrinker) l10n.noAlcohol,
                        ].join(' · ')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () async {
                                await _editCrewMember(context, member, l10n);
                                setSheetState(() {});
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                              onPressed: () async {
                                await _deleteCrewMember(member, l10n);
                                setSheetState(() {});
                              },
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      final newName = nameCtrl.text.trim();
                      final newBoatName = boatNameCtrl.text.trim();
                      final newBoatManufacturer = boatManufacturerCtrl.text.trim();
                      final newBoatModel = boatModelCtrl.text.trim();
                      final parsedFridge = int.tryParse(fridgeCtrl.text.trim()) ?? fridgeCapacity;
                      final parsedFreezer = int.tryParse(freezerCtrl.text.trim()) ?? freezerCapacity;
                      final parsedWater = int.tryParse(waterCtrl.text.trim()) ?? waterTankLiters;

                      final service = ref.read(tripServiceProvider);
                      await service.updateTripDetails(
                        tripId: widget.tripId,
                        name: newName.isNotEmpty ? newName : null,
                        startDate: selectedDate,
                        daysCount: daysCount,
                        fridgeCapacity: parsedFridge,
                        hasFreezer: hasFreezer,
                        freezerCapacity: parsedFreezer,
                        waterTankLiters: parsedWater,
                        isWaterTankDrinkable: isWaterTankDrinkable,
                        restaurantLunches: lunchCount,
                        restaurantDinners: dinnerCount,
                        boatName: newBoatName.isNotEmpty ? newBoatName : null,
                        boatManufacturer: newBoatManufacturer.isNotEmpty ? newBoatManufacturer : null,
                        boatModel: newBoatModel.isNotEmpty ? newBoatModel : null,
                        hasWatermaker: hasWatermaker,
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) _loadTripDetails();
                    },
                    child: Text(l10n.save),
                  ),
                  const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
