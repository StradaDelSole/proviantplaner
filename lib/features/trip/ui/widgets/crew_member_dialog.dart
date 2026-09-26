/// Dialog zum Anlegen und Bearbeiten eines Crew-Mitglieds (Slice S3, FB1-A).
library;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';

class CrewMemberDialog extends StatefulWidget {
  final CrewMemberInput? initialMember;

  const CrewMemberDialog({super.key, this.initialMember});

  @override
  State<CrewMemberDialog> createState() => _CrewMemberDialogState();
}

class _CrewMemberDialogState extends State<CrewMemberDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _ibanController;
  late final TextEditingController _paypalController;
  late final TextEditingController _revolutController;
  late bool _isAdult;
  late bool _isVegetarian;
  late bool _noAlcohol;
  EatProfileLevel? _customEatLevel;
  DrinkProfileLevel? _customDrinkLevel;
  String? _ibanError;

  @override
  void initState() {
    super.initState();
    final init = widget.initialMember;
    _nameController = TextEditingController(text: init?.name ?? '');
    _ibanController = TextEditingController(text: init?.iban ?? '');
    _paypalController = TextEditingController(text: init?.paypalLink ?? '');
    _revolutController = TextEditingController(text: init?.revolutLink ?? '');
    _isAdult = init?.isAdult ?? true;
    _isVegetarian = init?.isVegetarian ?? false;
    _noAlcohol = init?.noAlcohol ?? false;
    _customEatLevel = init?.customEatLevel;
    _customDrinkLevel = init?.customDrinkLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ibanController.dispose();
    _paypalController.dispose();
    _revolutController.dispose();
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
            DropdownButtonFormField<EatProfileLevel?>(
              value: _customEatLevel,
              decoration: InputDecoration(
                labelText: l10n.customEatLevel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.appetiteNormal)),
                DropdownMenuItem(value: EatProfileLevel.small, child: Text(l10n.appetiteLight)),
                DropdownMenuItem(value: EatProfileLevel.big, child: Text(l10n.appetiteHearty)),
              ],
              onChanged: (val) => setState(() => _customEatLevel = val),
            ),
            if (_isAdult && !_noAlcohol) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<DrinkProfileLevel?>(
                value: _customDrinkLevel,
                decoration: InputDecoration(
                  labelText: l10n.customDrinkLevel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.drinkingNormal)),
                  DropdownMenuItem(value: DrinkProfileLevel.little, child: Text(l10n.drinkingRelaxed)),
                  DropdownMenuItem(value: DrinkProfileLevel.aLot, child: Text(l10n.drinkingFestive)),
                ],
                onChanged: (val) => setState(() => _customDrinkLevel = val),
              ),
            ],
            const Divider(),
            Text(
              'Zahlungsdaten (optional)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ibanController,
              decoration: InputDecoration(
                labelText: 'IBAN',
                errorText: _ibanError,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _paypalController,
              decoration: const InputDecoration(
                labelText: 'PayPal.Me Link',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _revolutController,
              decoration: const InputDecoration(
                labelText: 'Revolut.Me Link',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
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

            final rawIban = _ibanController.text.trim();
            final cleanIban = rawIban.replaceAll(RegExp(r'\s+'), '').toUpperCase();
            if (cleanIban.isNotEmpty && !IbanValidator.isValid(cleanIban)) {
              setState(() {
                _ibanError = 'Ungültige IBAN (Modulo-97 Prüfsummenfehler)';
              });
              return;
            }

            final member = CrewMemberInput(
              id: widget.initialMember?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              isAdult: _isAdult,
              isVegetarian: _isVegetarian,
              noAlcohol: _noAlcohol,
              customEatLevel: _customEatLevel,
              customDrinkLevel: _customDrinkLevel,
              iban: cleanIban.isNotEmpty ? cleanIban : null,
              paypalLink: _paypalController.text.trim().isNotEmpty ? _paypalController.text.trim() : null,
              revolutLink: _revolutController.text.trim().isNotEmpty ? _revolutController.text.trim() : null,
            );
            Navigator.of(context).pop(member);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
