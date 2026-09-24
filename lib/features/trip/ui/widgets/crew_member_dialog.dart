/// Dialog zum Anlegen und Bearbeiten eines Crew-Mitglieds (Slice S3).
library;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';

class CrewMemberDialog extends StatefulWidget {
  final CrewMemberInput? initialMember;

  const CrewMemberDialog({super.key, this.initialMember});

  @override
  State<CrewMemberDialog> createState() => _CrewMemberDialogState();
}

class _CrewMemberDialogState extends State<CrewMemberDialog> {
  late final TextEditingController _nameController;
  late bool _isAdult;
  late bool _isVegetarian;
  late bool _noAlcohol;
  String? _customEatLevel;
  String? _customDrinkLevel;

  @override
  void initState() {
    super.initState();
    final init = widget.initialMember;
    _nameController = TextEditingController(text: init?.name ?? '');
    _isAdult = init?.isAdult ?? true;
    _isVegetarian = init?.isVegetarian ?? false;
    _noAlcohol = init?.noAlcohol ?? false;
    _customEatLevel = init?.customEatLevel;
    _customDrinkLevel = init?.customDrinkLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.initialMember == null ? l10n.addCrewMember : l10n.edit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.name,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: true, label: Text(l10n.isAdult)),
                      ButtonSegment(value: false, label: Text(l10n.isChild)),
                    ],
                    selected: {_isAdult},
                    onSelectionChanged: (val) {
                      setState(() {
                        _isAdult = val.first;
                        if (!_isAdult) {
                          _noAlcohol = true;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.isVegetarian),
              value: _isVegetarian,
              onChanged: (val) => setState(() => _isVegetarian = val ?? false),
            ),
            if (_isAdult)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.noAlcohol),
                value: _noAlcohol,
                onChanged: (val) => setState(() => _noAlcohol = val ?? false),
              ),
            const Divider(),
            Text(
              l10n.adjustIndividualDetails,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _customEatLevel,
              decoration: InputDecoration(
                labelText: l10n.customEatLevel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.appetiteNormal)),
                DropdownMenuItem(value: 'small', child: Text(l10n.appetiteLight)),
                DropdownMenuItem(value: 'big', child: Text(l10n.appetiteHearty)),
              ],
              onChanged: (val) => setState(() => _customEatLevel = val),
            ),
            if (_isAdult && !_noAlcohol) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _customDrinkLevel,
                decoration: InputDecoration(
                  labelText: l10n.customDrinkLevel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.drinkingNormal)),
                  DropdownMenuItem(value: 'little', child: Text(l10n.drinkingRelaxed)),
                  DropdownMenuItem(value: 'a_lot', child: Text(l10n.drinkingFestive)),
                ],
                onChanged: (val) => setState(() => _customDrinkLevel = val),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            final member = CrewMemberInput(
              id: widget.initialMember?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              isAdult: _isAdult,
              isVegetarian: _isVegetarian,
              noAlcohol: _noAlcohol,
              customEatLevel: _customEatLevel,
              customDrinkLevel: _customDrinkLevel,
            );
            Navigator.of(context).pop(member);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
