/// Sheet zur Zuordnung von Teilmengen auf Einkaufsstopps (SC-LST-04).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';

class StopAllocationSheet extends ConsumerStatefulWidget {
  final int tripId;
  final ShoppingListItemView item;
  final List<ShoppingStop> stops;

  const StopAllocationSheet({
    super.key,
    required this.tripId,
    required this.item,
    required this.stops,
  });

  static Future<void> show(
    BuildContext context, {
    required int tripId,
    required ShoppingListItemView item,
    required List<ShoppingStop> stops,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StopAllocationSheet(
        tripId: tripId,
        item: item,
        stops: stops,
      ),
    );
  }

  @override
  ConsumerState<StopAllocationSheet> createState() => _StopAllocationSheetState();
}

class _StopAllocationSheetState extends ConsumerState<StopAllocationSheet> {
  late Map<int, int> _allocations;

  @override
  void initState() {
    super.initState();
    _allocations = {};
    for (final stop in widget.stops) {
      _allocations[stop.id] = widget.item.allocationsByStop[stop.id]?.allocatedPackages ?? 0;
    }
  }

  int get _totalAllocated =>
      _allocations.values.fold<int>(0, (sum, val) => sum + val);

  int get _totalAvailable => widget.item.effectivePackages;

  void _increment(int stopId) {
    if (_totalAllocated < _totalAvailable) {
      setState(() {
        _allocations[stopId] = (_allocations[stopId] ?? 0) + 1;
      });
    }
  }

  void _decrement(int stopId) {
    final current = _allocations[stopId] ?? 0;
    if (current > 0) {
      setState(() {
        _allocations[stopId] = current - 1;
      });
    }
  }

  Future<void> _save() async {
    final service = ref.read(shoppingListServiceProvider);
    for (final entry in _allocations.entries) {
      await service.allocateToStop(
        tripId: widget.tripId,
        listItemId: widget.item.item.id,
        shoppingStopId: entry.key,
        packages: entry.value,
      );
    }
    if (mounted) {
      Navigator.of(context).pop();
      ref.invalidate(tripShoppingListProvider(widget.tripId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.allocateDialogTitle,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.item.name,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Verteilt: $_totalAllocated von $_totalAvailable Packungen',
            style: theme.proviantTypography.numberMedium.copyWith(
              color: _totalAllocated > _totalAvailable
                  ? theme.colorScheme.error
                  : theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.unallocatedNotice,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.stops.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final stop = widget.stops[i];
                final count = _allocations[stop.id] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tag ${stop.dayNumber} · ${stop.name}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (stop.isInitial)
                              Text(
                                'Ersteinkauf (Basis)',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                            onPressed: count > 0 ? () => _decrement(stop.id) : null,
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 32),
                            alignment: Alignment.center,
                            child: Text(
                              '$count',
                              style: theme.proviantTypography.numberMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                            onPressed: _totalAllocated < _totalAvailable
                                ? () => _increment(stop.id)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _save,
              child: Text(l10n.takeOver),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
