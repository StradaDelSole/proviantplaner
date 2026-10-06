/// Reusable dialog to create or edit a boat profile (PIVOT3-B, Issue #6).
library;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';

class BoatProfileDialog extends ConsumerStatefulWidget {
  final BoatProfile? initialProfile;

  const BoatProfileDialog({super.key, this.initialProfile});

  @override
  ConsumerState<BoatProfileDialog> createState() => _BoatProfileDialogState();
}

class _BoatProfileDialogState extends ConsumerState<BoatProfileDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _manufacturerCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _fridgeCtrl;
  late final TextEditingController _freezerCtrl;
  late final TextEditingController _waterCtrl;

  late bool _hasFreezer;
  late bool _isWaterTankDrinkable;
  late bool _hasWatermaker;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _manufacturerCtrl = TextEditingController(text: p?.manufacturer ?? '');
    _modelCtrl = TextEditingController(text: p?.model ?? '');
    _fridgeCtrl = TextEditingController(text: (p?.fridgeCapacity ?? 100).toString());
    _freezerCtrl = TextEditingController(text: (p?.freezerCapacity ?? 0).toString());
    _waterCtrl = TextEditingController(text: (p?.waterTankLiters ?? 0).toString());

    _hasFreezer = p?.hasFreezer ?? false;
    _isWaterTankDrinkable = p?.isWaterTankDrinkable ?? false;
    _hasWatermaker = p?.hasWatermaker ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _manufacturerCtrl.dispose();
    _modelCtrl.dispose();
    _fridgeCtrl.dispose();
    _freezerCtrl.dispose();
    _waterCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final manufacturer = _manufacturerCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    final fridge = int.tryParse(_fridgeCtrl.text.trim()) ?? 100;
    final freezer = _hasFreezer ? (int.tryParse(_freezerCtrl.text.trim()) ?? 0) : 0;
    final water = int.tryParse(_waterCtrl.text.trim()) ?? 0;

    final service = ref.read(boatProfileServiceProvider);

    if (widget.initialProfile != null) {
      final updated = widget.initialProfile!.copyWith(
        name: name,
        manufacturer: drift.Value(manufacturer.isNotEmpty ? manufacturer : null),
        model: drift.Value(model.isNotEmpty ? model : null),
        fridgeCapacity: fridge,
        hasFreezer: _hasFreezer,
        freezerCapacity: freezer,
        waterTankLiters: water,
        isWaterTankDrinkable: _isWaterTankDrinkable,
        hasWatermaker: _hasWatermaker,
      );
      final ok = await service.updateProfile(updated);
      if (ok && mounted) {
        Navigator.of(context).pop(updated);
      }
    } else {
      final id = await service.createProfile(
        name: name,
        manufacturer: manufacturer.isNotEmpty ? manufacturer : null,
        model: model.isNotEmpty ? model : null,
        fridgeCapacity: fridge,
        hasFreezer: _hasFreezer,
        freezerCapacity: freezer,
        waterTankLiters: water,
        isWaterTankDrinkable: _isWaterTankDrinkable,
        hasWatermaker: _hasWatermaker,
      );
      final created = await service.getProfileById(id);
      if (mounted) {
        Navigator.of(context).pop(created);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.initialProfile != null;

    return AlertDialog(
      title: Text(isEditing ? l10n.editBoatProfile : l10n.createNewBoatProfile),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: '${l10n.boatName} *',
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.boatName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _manufacturerCtrl,
                decoration: InputDecoration(
                  labelText: l10n.boatManufacturer,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelCtrl,
                decoration: InputDecoration(
                  labelText: l10n.boatModel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fridgeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.fridgeCapacity,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.freezerAvailable),
                value: _hasFreezer,
                onChanged: (val) => setState(() => _hasFreezer = val),
              ),
              if (_hasFreezer) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _freezerCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.freezerCapacityLiters,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _waterCtrl,
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
                value: _isWaterTankDrinkable,
                onChanged: (val) => setState(() => _isWaterTankDrinkable = val),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.hasWatermaker),
                subtitle: Text(l10n.hasWatermakerSubtitle),
                value: _hasWatermaker,
                onChanged: (val) => setState(() => _hasWatermaker = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
