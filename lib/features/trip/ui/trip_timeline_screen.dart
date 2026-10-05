/// Bildschirm für Törnverlauf, Tagesleiste und Einkaufsstopps (Slice S3, Mockup 06).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/routing/not_found_screen.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/delivery_order_service.dart';
import '../data/trip_provider.dart';
import 'widgets/day_card.dart';

class TripTimelineScreen extends ConsumerWidget {
  final int tripId;

  const TripTimelineScreen({super.key, required this.tripId});

  void _showAddStopDialog(BuildContext context, WidgetRef ref, int maxDays) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    int selectedDay = 1;
    bool isDelivery = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
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
                  maxDays,
                  (i) => DropdownMenuItem(value: i + 1, child: Text('${l10n.day} ${i + 1}')),
                ),
                onChanged: (val) => setState(() => selectedDay = val ?? 1),
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l10n.selfShopping)),
                  ButtonSegment(value: true, label: Text(l10n.deliveryOrder)),
                ],
                selected: {isDelivery},
                onSelectionChanged: (val) => setState(() => isDelivery = val.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final service = ref.read(tripServiceProvider);
      final newStopId = await service.addShoppingStop(
        tripId: tripId,
        name: nameCtrl.text.trim(),
        dayNumber: selectedDay,
      );
      if (isDelivery) {
        await ref.read(deliveryOrderServiceProvider).saveOrder(
              DeliveryOrder(stopId: newStopId, tripId: tripId, isDelivery: true),
            );
      }
      ref.invalidate(tripStopsByIdProvider(tripId));
      ref.invalidate(activeTripStopsProvider);
    }
  }

  void _showEditStopDialog(BuildContext context, WidgetRef ref, ShoppingStop stop) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: stop.name);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.edit),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: l10n.name,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final service = ref.read(tripServiceProvider);
      await service.updateShoppingStop(stop.copyWith(name: result));
      ref.invalidate(tripStopsByIdProvider(tripId));
      ref.invalidate(activeTripStopsProvider);
    }
  }

  void _deleteStop(BuildContext context, WidgetRef ref, ShoppingStop stop) async {
    final l10n = AppLocalizations.of(context)!;
    if (stop.isInitial) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.firstStopProtected)),
      );
      return;
    }

    final service = ref.read(tripServiceProvider);
    final success = await service.deleteShoppingStop(stop.id);
    if (success) {
      ref.invalidate(tripStopsByIdProvider(tripId));
      ref.invalidate(activeTripStopsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final tripAsync = ref.watch(tripByIdProvider(tripId));
    final daysAsync = ref.watch(tripDaysByIdProvider(tripId));
    final stopsAsync = ref.watch(tripStopsByIdProvider(tripId));

    return tripAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.timelineTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => const NotFoundScreen(message: 'Törn nicht gefunden'),
      data: (trip) {
        if (trip == null) {
          return const NotFoundScreen(message: 'Törn nicht gefunden');
        }

        final days = daysAsync.valueOrNull ?? [];
        final stops = stopsAsync.valueOrNull ?? [];

        final boardDinners = days.where((d) => !d.dinnerRestaurant).length;
        final boardLunches = days.where((d) => !d.lunchRestaurant).length;
        final restaurantVisits = days.where((d) => d.lunchRestaurant || d.dinnerRestaurant).length;

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
            title: Text(trip.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_basket_outlined),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: l10n.addShoppingStop,
                onPressed: () {
                  _showAddStopDialog(context, ref, days.isNotEmpty ? days.length : 7);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Metric Card (Mockup 06)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.restaurant_menu, size: 18, color: theme.colorScheme.secondary),
                                const SizedBox(width: 8),
                                Text(
                                  'TÖRN-BILANZ VERPFLEGUNG',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetricItem(
                                  theme,
                                  value: '$boardDinners',
                                  label: l10n.metricBoardDinner,
                                ),
                                _buildMetricItem(
                                  theme,
                                  value: '$boardLunches',
                                  label: l10n.metricBoardLunch,
                                ),
                                _buildMetricItem(
                                  theme,
                                  value: '$restaurantVisits',
                                  label: l10n.metricRestaurant,
                                  valueColor: theme.colorScheme.secondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Einkaufsstopps Card
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.shoppingStopsTitle, style: theme.textTheme.titleLarge),
                        TextButton.icon(
                          onPressed: () => _showAddStopDialog(context, ref, days.isNotEmpty ? days.length : 7),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(l10n.addShoppingStop),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stops.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final stop = stops[idx];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              radius: 14,
                              child: Text('${stop.dayNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(stop.name),
                            subtitle: Text('${l10n.day} ${stop.dayNumber}${stop.isInitial ? " ${l10n.initialBaseStopLabel}" : ""}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                  onPressed: () => _showEditStopDialog(context, ref, stop),
                                ),
                                if (!stop.isInitial)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                    onPressed: () => _deleteStop(context, ref, stop),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Tagesleiste Timeline
                    Text(l10n.timelineTitle, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (days.length < 28)
                      ...days.map((day) => _buildDayCard(context, ref, day, stops))
                    else
                      ..._buildWeeklyGroupedDays(context, ref, days, stops, l10n, theme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    WidgetRef ref,
    TripDay day,
    List<ShoppingStop> stops,
  ) {
    final dayStops = stops.where((s) => s.dayNumber == day.dayNumber).toList();
    return DayCard(
      day: day,
      shoppingStops: dayStops,
      onToggleLunch: () async {
        final service = ref.read(tripServiceProvider);
        await service.toggleLunchRestaurant(day);
        ref.invalidate(tripDaysByIdProvider(tripId));
        ref.invalidate(activeTripDaysProvider);
      },
      onToggleEvening: () async {
        final service = ref.read(tripServiceProvider);
        await service.toggleEveningRestaurant(day);
        ref.invalidate(tripDaysByIdProvider(tripId));
        ref.invalidate(activeTripDaysProvider);
      },
      onUpdatePortName: (name) async {
        final service = ref.read(tripServiceProvider);
        await service.updateDayInfo(day, portName: name);
        ref.invalidate(tripDaysByIdProvider(tripId));
        ref.invalidate(activeTripDaysProvider);
      },
    );
  }

  List<Widget> _buildWeeklyGroupedDays(
    BuildContext context,
    WidgetRef ref,
    List<TripDay> days,
    List<ShoppingStop> stops,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final widgets = <Widget>[];
    const daysPerWeek = 7;
    final weekCount = (days.length / daysPerWeek).ceil();

    for (int w = 0; w < weekCount; w++) {
      final startIndex = w * daysPerWeek;
      final endIndex = (startIndex + daysPerWeek < days.length)
          ? startIndex + daysPerWeek
          : days.length;
      final weekDays = days.sublist(startIndex, endIndex);
      final startDayNumber = weekDays.first.dayNumber;
      final endDayNumber = weekDays.last.dayNumber;

      widgets.add(
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            initiallyExpanded: w == 0,
            title: Text(
              l10n.timelineWeek(w + 1, startDayNumber, endDayNumber),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${weekDays.length} ${l10n.day}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            childrenPadding: const EdgeInsets.all(8),
            children: weekDays.map((day) => _buildDayCard(context, ref, day, stops)).toList(),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildMetricItem(
    ThemeData theme, {
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: theme.proviantTypography.numberLarge.copyWith(
            fontSize: 26,
            height: 32 / 26,
            fontWeight: FontWeight.w600,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
