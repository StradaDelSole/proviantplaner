/// Bottom Sheet zum Erfassen einer Einzahlung in die Bordkasse (SC-KAS-03, FB1-D).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../data/kitty_providers.dart';
import '../../domain/models/kitty_models.dart';

/// Sheet zum Erfassen von Einzahlungen in einem Schritt (FEEDBACK_R1 Punkt 9).
class PaymentSheet extends ConsumerStatefulWidget {
  final int tripId;
  final List<KittyMember> members;
  final int? initialAmountInCents;

  const PaymentSheet({
    super.key,
    required this.tripId,
    required this.members,
    this.initialAmountInCents,
  });

  /// Zeigt das Bottom Sheet an.
  static Future<void> show(
    BuildContext context, {
    required int tripId,
    required List<KittyMember> members,
    int? initialAmountInCents,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => PaymentSheet(
        tripId: tripId,
        members: members,
        initialAmountInCents: initialAmountInCents,
      ),
    );
  }

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late Set<int> _selectedMemberIds;

  @override
  void initState() {
    super.initState();
    final initCents = widget.initialAmountInCents;
    _amountController = TextEditingController(
      text: initCents != null ? (initCents / 100.0).toStringAsFixed(2) : '',
    );
    // Standardmäßig alle Crew-Mitglieder zum Einzahlen vorausgewählt
    _selectedMemberIds = widget.members.map((m) => m.id).toSet();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int? _parseAmountInCents() {
    final str = _amountController.text.trim().replaceAll(',', '.');
    final euros = double.tryParse(str) ?? 0.0;
    final cents = (euros * 100).round();
    return cents > 0 ? cents : null;
  }

  Future<void> _saveDeposits() async {
    if (!_formKey.currentState!.validate()) return;
    final cents = _parseAmountInCents();
    if (cents == null || _selectedMemberIds.isEmpty) return;

    final service = ref.read(kittyServiceProvider);
    for (final memberId in _selectedMemberIds) {
      await service.addDeposit(
        tripId: widget.tripId,
        memberId: memberId,
        amountInCents: cents,
      );
    }

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fundDepositSaved)),
      );
      Navigator.of(context).pop();
      ref.invalidate(tripKittyDataProvider(widget.tripId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cents = _parseAmountInCents();
    final totalCents = (cents ?? 0) * _selectedMemberIds.length;
    final totalEuros = (totalCents / 100.0).toStringAsFixed(2).replaceAll('.', ',');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme, l10n),
              const SizedBox(height: 16),
              _buildAmountField(theme, l10n),
              const SizedBox(height: 16),
              _buildMembersChecklist(theme),
              const SizedBox(height: 20),
              _buildSubmitButton(theme, l10n, totalEuros),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.fundAddDeposit,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ],
    );
  }

  Widget _buildAmountField(ThemeData theme, AppLocalizations l10n) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autofocus: widget.initialAmountInCents == null,
      onChanged: (_) => setState(() {}),
      style: theme.textTheme.headlineMedium?.copyWith(
        fontFamily: 'JetBrains Mono',
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: 'Wie viel zahlt jeder ein? (€)',
        suffixText: '€',
        suffixStyle: theme.textTheme.headlineSmall?.copyWith(
          fontFamily: 'JetBrains Mono',
        ),
        border: const OutlineInputBorder(),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Betrag erforderlich';
        final parsed = double.tryParse(val.replaceAll(',', '.'));
        if (parsed == null || parsed <= 0) return 'Gültigen Betrag eingeben';
        return null;
      },
    );
  }

  Widget _buildMembersChecklist(ThemeData theme) {
    final allSelected = _selectedMemberIds.length == widget.members.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Wer hat eingezahlt?',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (allSelected) {
                    _selectedMemberIds.clear();
                  } else {
                    _selectedMemberIds = widget.members.map((m) => m.id).toSet();
                  }
                });
              },
              child: Text(allSelected ? 'Keine' : 'Alle'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...widget.members.map((m) {
          final isChecked = _selectedMemberIds.contains(m.id);
          return CheckboxListTile(
            value: isChecked,
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Text(m.name, style: theme.textTheme.bodyLarge),
                if (m.isSkipperFree) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text('Skipper', style: TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ],
            ),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedMemberIds.add(m.id);
                } else {
                  _selectedMemberIds.remove(m.id);
                }
              });
            },
          );
        }),
        if (_selectedMemberIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Mindestens eine Person muss ausgewählt sein',
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme, AppLocalizations l10n, String totalEuros) {
    final hasSelection = _selectedMemberIds.isNotEmpty;
    final cents = _parseAmountInCents();
    final buttonText = (cents != null && hasSelection)
        ? 'Einzahlungen speichern ($totalEuros €)'
        : l10n.fundSaveDeposit;

    return FilledButton(
      onPressed: hasSelection ? _saveDeposits : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(buttonText),
    );
  }
}
