/// Törn-Übersicht – das Rückgrat der Törn-Verwaltung (UX-A, UX-Konzept 2.3).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final now = DateTime.now();
    final tripEnded = now.isAfter(_trip!.startDate.add(Duration(days: _trip!.daysCount)));
    if (tripEnded) return 4;
    final tripStarted = now.isAfter(_trip!.startDate) || kittyData.expenses.isNotEmpty;
    if (tripStarted) return 3;
    final hasItems = _items.isNotEmpty;
    if (hasItems) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final kittyAsync = ref.watch(tripKittyDataProvider(widget.tripId));

    if (_isLoading || _trip == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tripOverviewTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return kittyAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(_trip!.name)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: Text(_trip!.name)),
        body: Center(child: Text('Fehler: $err')),
      ),
      data: (kittyData) {
        final currentStep = _calculateCurrentStep(kittyData);
        final hasStarted = DateTime.now().isAfter(_trip!.startDate) || kittyData.expenses.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text(_trip!.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.edit,
                onPressed: () {
                  // Schnellbearbeitung Törn-Stammdaten
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
                        subtitle: '${_items.length} Positionen kalkuliert',
                        actionLabel: l10n.editList,
                        icon: Icons.inventory_2_outlined,
                        isCurrent: currentStep == 1,
                        isDone: currentStep > 1,
                        onAction: () => context.go('/trips/${widget.tripId}/shopping-list'),
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
                        '${_stops.length} Einkaufsstopp${_stops.length == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                if (_stops.isNotEmpty)
                  FilledButton.tonal(
                    onPressed: () => context.go('/trips/${widget.tripId}/shop/${_stops.first.id}'),
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
                                    'Tag ${s.dayNumber} · ${s.name} (Lieferung)',
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: 'Lieferdetails anpassen',
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
                                  const Text('Lieferung erhalten', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => _openOrderPreview(s, order),
                                    child: const Text('Bestellung ansehen'),
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
                                    child: const Text('Lieferung erhalten'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => _openOrderPreview(s, order),
                                    child: const Text('Bestellung ansehen'),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              FilledButton.tonal(
                                onPressed: () => _openOrderPreview(s, order),
                                child: const Text('Bestellung senden'),
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
                        Text('Tag ${s.dayNumber} · ${s.name}', style: theme.textTheme.bodyMedium),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.local_shipping_outlined, size: 18),
                          tooltip: 'Als Lieferung anlegen',
                          onPressed: () => _configureDelivery(s, null),
                        ),
                        TextButton(
                          onPressed: () => context.go('/trips/${widget.tripId}/shop/${s.id}'),
                          child: const Text('Starten'),
                        ),
                      ],
                    ),
                  );
                }),
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
    final treasurerName = kittyData.treasurer?.name ?? 'Nicht festgelegt';

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
                      Text('Unterwegs / Bordkasse', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Kassenwart: $treasurerName', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
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
                  Text('Kassenstand:', style: theme.textTheme.bodyMedium),
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
              Text('Letzte Ausgaben:', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline)),
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
                      Text('${kittyData.transfers.length} Ausgleichszahlungen',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => context.go('/trips/${widget.tripId}/kitty/settlement'),
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
          subtitle: Text('${_days.length} Tage im Törnverlauf', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            ..._days.map((day) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: theme.colorScheme.surfaceContainerLowest,
                  child: ListTile(
                    title: Text('Tag ${day.dayNumber} ${day.portName != null && day.portName!.isNotEmpty ? "· ${day.portName}" : ""}'),
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

  Future<void> _showEditTripDialog(BuildContext context, AppLocalizations l10n) async {
    final nameCtrl = TextEditingController(text: _trip!.name);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.edit),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: l10n.tripName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                final db = ref.read(databaseProvider);
                await db.tripDao.updateTrip(_trip!.copyWith(name: newName));
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                if (mounted) {
                  _loadTripDetails();
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
