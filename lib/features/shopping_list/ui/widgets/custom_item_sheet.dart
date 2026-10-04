/// Sheet zum Anlegen einer eigenen Position (SC-LST-05).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/services/catalog_localization_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/catalog_models.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';

class CustomItemSheet extends ConsumerStatefulWidget {
  final int tripId;
  final List<ShoppingStop> stops;
  final String? initialName;

  const CustomItemSheet({
    super.key,
    required this.tripId,
    required this.stops,
    this.initialName,
  });

  static Future<void> show(
    BuildContext context, {
    required int tripId,
    required List<ShoppingStop> stops,
    String? initialName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => CustomItemSheet(
        tripId: tripId,
        stops: stops,
        initialName: initialName,
      ),
    );
  }

  @override
  ConsumerState<CustomItemSheet> createState() => _CustomItemSheetState();
}

class _CustomItemSheetState extends ConsumerState<CustomItemSheet> {
  late TextEditingController _nameController;
  late TextEditingController _qtyController;
  String _selectedUnit = 'Stück';
  CatalogDepartment _selectedDept = CatalogDepartment.haushalt;
  int? _selectedStopId;

  static const _units = ['Stück', 'g', 'kg', 'ml', 'l', 'Packung'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _qtyController = TextEditingController(text: '1');
    _selectedStopId = widget.stops.firstOrNull?.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final qty = double.tryParse(_qtyController.text.trim().replaceAll(',', '.')) ?? 1.0;
    final service = ref.read(shoppingListServiceProvider);

    await service.addCustomItem(
      CustomItemInput(
        tripId: widget.tripId,
        name: name,
        quantity: qty,
        unit: _selectedUnit,
        department: _selectedDept.rawValue,
        shoppingStopId: _selectedStopId,
      ),
    );

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.customItemTitle,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.name,
                border: const OutlineInputBorder(),
              ),
              autofocus: widget.initialName == null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.quantity,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: InputDecoration(
                      labelText: l10n.unit,
                      border: const OutlineInputBorder(),
                    ),
                    items: _units.map((u) {
                      String label = u;
                      switch (u) {
                        case 'Stück':
                          label = l10n.unitPiece;
                          break;
                        case 'g':
                          label = l10n.unitGram;
                          break;
                        case 'kg':
                          label = l10n.unitKilogram;
                          break;
                        case 'ml':
                          label = l10n.unitMilliliter;
                          break;
                        case 'l':
                          label = l10n.unitLiter;
                          break;
                        case 'Packung':
                          label = l10n.unitPackage;
                          break;
                      }
                      return DropdownMenuItem(value: u, child: Text(label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedUnit = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CatalogDepartment>(
              value: _selectedDept,
              decoration: InputDecoration(
                labelText: l10n.department,
                border: const OutlineInputBorder(),
              ),
              items: CatalogDepartment.values
                  .map((d) => DropdownMenuItem(value: d, child: Text(d.localizedName(context))))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedDept = val);
              },
            ),
            if (widget.stops.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedStopId,
                decoration: InputDecoration(
                  labelText: l10n.shoppingStop,
                  border: const OutlineInputBorder(),
                ),
                items: widget.stops
                    .map((s) => DropdownMenuItem(value: s.id, child: Text('${l10n.day} ${s.dayNumber} · ${s.name}')))
                    .toList(),
                onChanged: (val) => setState(() => _selectedStopId = val),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _save,
                child: Text(l10n.save),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
