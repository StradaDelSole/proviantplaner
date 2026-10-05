/// Kompaktes Bottom Sheet für Variante → Packung → Anzahl → Liste (PIVOT1 / UX Decision 13-15).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/services/catalog_localization_service.dart';
import 'package:proviantplaner/core/util/formatters.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/package_size_dialog.dart';

class AddOrEditItemSheet extends ConsumerStatefulWidget {
  final TripShoppingListData data;
  final ShoppingListItemView item;
  final bool isAdding;
  final int? currentStopId;

  const AddOrEditItemSheet({
    super.key,
    required this.data,
    required this.item,
    this.isAdding = false,
    this.currentStopId,
  });

  /// Öffnet das Sheet modal von unten.
  static Future<void> show(
    BuildContext context, {
    required TripShoppingListData data,
    required ShoppingListItemView item,
    bool isAdding = false,
    int? currentStopId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddOrEditItemSheet(
        data: data,
        item: item,
        isAdding: isAdding,
        currentStopId: currentStopId,
      ),
    );
  }

  @override
  ConsumerState<AddOrEditItemSheet> createState() => _AddOrEditItemSheetState();
}

class _AddOrEditItemSheetState extends ConsumerState<AddOrEditItemSheet> {
  late double _selectedPackSize;
  late int _quantity;
  late int? _selectedStopId;
  bool _isDirectEditing = false;
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _selectedPackSize = widget.item.effectivePackSize;
    if (widget.isAdding) {
      _quantity = widget.item.effectivePackages > 0
          ? widget.item.effectivePackages
          : (widget.item.calculatedPackages > 0 ? widget.item.calculatedPackages : 1);
    } else {
      _quantity = widget.item.effectivePackages > 0 ? widget.item.effectivePackages : 1;
    }
    _selectedStopId = widget.currentStopId ?? widget.data.stops.firstOrNull?.id;
    _qtyController = TextEditingController(text: _quantity.toString());
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  List<double> _generatePackSizeOptions() {
    final unit = widget.item.unit.toLowerCase().trim();
    final defaultSize = widget.item.effectivePackSize;

    List<double> candidates;
    if (unit == 'g') {
      candidates = [100, 150, 200, 250, 400, 500, 750, 1000];
    } else if (unit == 'kg') {
      candidates = [0.5, 1.0, 1.5, 2.0, 5.0];
    } else if (unit == 'ml') {
      candidates = [100, 200, 250, 330, 500, 750, 1000];
    } else if (unit == 'l') {
      candidates = [0.5, 1.0, 1.5, 2.0, 5.0, 10.0];
    } else {
      candidates = [1.0, 2.0, 4.0, 6.0, 10.0];
    }

    final set = candidates.toSet();
    set.add(defaultSize);
    if (widget.item.customPackageSize > 0) {
      set.add(widget.item.customPackageSize);
    }
    set.add(_selectedPackSize);

    final sorted = set.where((s) => s > 0).toList()..sort();
    return sorted;
  }

  void _openCustomPackSizeDialog() async {
    final result = await PackageSizeDialog.show(context, widget.item);
    if (result != null && result > 0 && mounted) {
      setState(() {
        _selectedPackSize = result;
      });
    }
  }

  Future<void> _saveAndAdd() async {
    final service = ref.read(shoppingListServiceProvider);
    final tripId = widget.data.trip.id;

    if (_selectedPackSize != widget.item.effectivePackSize) {
      await service.updateCustomPackageSize(
        tripId: tripId,
        listItemId: widget.item.item.id,
        packSize: _selectedPackSize,
      );
    }

    await service.adoptItem(
      tripId: tripId,
      listItemId: widget.item.item.id,
      packages: _quantity,
    );

    if (_selectedStopId != null) {
      await service.allocateToStop(
        tripId: tripId,
        listItemId: widget.item.item.id,
        shoppingStopId: _selectedStopId!,
        packages: _quantity,
      );
    }

    ref.invalidate(tripShoppingListProvider(tripId));

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      final itemName = widget.item.localizedName(context);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.itemAddedNotice(itemName)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _removeFromList() async {
    final service = ref.read(shoppingListServiceProvider);
    final tripId = widget.data.trip.id;

    await service.unadoptItem(
      tripId: tripId,
      listItemId: widget.item.item.id,
    );

    ref.invalidate(tripShoppingListProvider(tripId));

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      final itemName = widget.item.localizedName(context);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.itemRemovedNotice(itemName)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final packUnit = widget.item.unit;
    final assistType = widget.item.assistType;
    final packSizeOptions = _generatePackSizeOptions();
    final totalAmount = _quantity * _selectedPackSize;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag-Griff
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Titelzeile & Abteilung
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.localizedName(context),
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.item.department.localizedName(context),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.item.shelfLifeDays > 0) ...[
                            const SizedBox(width: 8),
                            Text('·', style: theme.textTheme.bodySmall),
                            const SizedBox(width: 8),
                            Text(
                              widget.item.shelfLifeDays == 1
                                  ? l10n.holdsOneDay
                                  : l10n.holdsDays(widget.item.shelfLifeDays),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.item.isOnList && !widget.isAdding)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.onListStatus,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            // Kühlhinweis falls relevant
            if (widget.item.storageNotice != null || widget.item.isCooled) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.ac_unit, size: 14, color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 6),
                    Text(
                      widget.item.storageNotice ?? l10n.needsCooling,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Provy-Richtwert (für needsBased / guided)
            if (widget.item.calculatedQuantity > 0 &&
                (assistType.isNeedsBased || assistType.isGuided)) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.provyGuidelineNotice(AppFormatters.formatDecimal(context, widget.item.calculatedQuantity), widget.item.unit)}'
                        '${widget.item.calculatedPackages > 0 ? " (${l10n.suggestionCount(widget.item.calculatedPackages)})" : ""}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // Packungsgröße (horizontale Chips)
            Text(
              l10n.packageSize,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...packSizeOptions.map((size) {
                    final isSelected = (_selectedPackSize - size).abs() < 1e-4;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text('${AppFormatters.formatDecimal(context, size)} $packUnit'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPackSize = size;
                            });
                          }
                        },
                      ),
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.edit_outlined, size: 14),
                    label: Text(l10n.customPackageSize),
                    onPressed: _openCustomPackSizeDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Anzahl Stepper (− / Zahl / +) mit Pickwheel/Direkteingabe
            Text(
              l10n.quantity,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: _quantity > (widget.isAdding ? 1 : 0)
                            ? () {
                                setState(() {
                                  _quantity--;
                                  _qtyController.text = _quantity.toString();
                                });
                              }
                            : null,
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDirectEditing = true;
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _isDirectEditing
                              ? SizedBox(
                                  width: 48,
                                  child: TextField(
                                    controller: _qtyController,
                                    autofocus: true,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onSubmitted: (val) {
                                      final parsed = int.tryParse(val);
                                      if (parsed != null && parsed >= 0) {
                                        setState(() {
                                          _quantity = parsed;
                                          _isDirectEditing = false;
                                        });
                                      } else {
                                        setState(() {
                                          _isDirectEditing = false;
                                          _qtyController.text = _quantity.toString();
                                        });
                                      }
                                    },
                                  ),
                                )
                              : Text(
                                  '$_quantity',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: () {
                          setState(() {
                            _quantity++;
                            _qtyController.text = _quantity.toString();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '$_quantity ${l10n.unitPackage}\n'
                    '(${l10n.totalQuantity}: ${AppFormatters.formatDecimal(context, totalAmount)} $packUnit)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_quantity × ${AppFormatters.formatDecimal(context, _selectedPackSize)} $packUnit = '
                '${AppFormatters.formatDecimal(context, totalAmount)} $packUnit',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Einkaufsstopp-Auswahl bei mehreren Stopps
            if (widget.data.stops.length > 1) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                l10n.shoppingStopsTitle,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.data.stops.map((stop) {
                  final isSelected = _selectedStopId == stop.id;
                  return ChoiceChip(
                    avatar: const Icon(Icons.storefront_outlined, size: 16),
                    label: Text(l10n.stopDayPort(stop.dayNumber, stop.name)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedStopId = stop.id),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            // Hauptaktion ("Auf die Liste" / "Speichern")
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                key: const ValueKey('sheet_primary_action_btn'),
                icon: Icon(widget.isAdding ? Icons.add_shopping_cart : Icons.check),
                label: Text(
                  widget.isAdding ? l10n.addToList : l10n.save,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _saveAndAdd,
              ),
            ),
            // Entfernen-Aktion wenn bereits auf der Liste
            if (widget.item.isOnList && !widget.isAdding) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  key: const ValueKey('sheet_remove_btn'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.removeFromList),
                  onPressed: _removeFromList,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
