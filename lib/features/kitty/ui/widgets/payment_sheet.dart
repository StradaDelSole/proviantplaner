/// Bottom Sheet zum Erfassen einer Einzahlung in die Bordkasse (SC-KAS-03).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../data/kitty_providers.dart';
import '../../domain/models/kitty_models.dart';

/// Sheet zum Erfassen einer Einzahlung in die gemeinsame Kasse.
class PaymentSheet extends ConsumerStatefulWidget {
  final int tripId;
  final List<KittyMember> members;

  const PaymentSheet({
    super.key,
    required this.tripId,
    required this.members,
  });

  /// Zeigt das Bottom Sheet an.
  static Future<void> show(
    BuildContext context, {
    required int tripId,
    required List<KittyMember> members,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => PaymentSheet(
        tripId: tripId,
        members: members,
      ),
    );
  }

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  int? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _selectedMemberId = widget.members.firstOrNull?.id;
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

  Future<void> _saveSingleDeposit() async {
    if (!_formKey.currentState!.validate()) return;
    final cents = _parseAmountInCents();
    if (cents == null || _selectedMemberId == null) return;

    final service = ref.read(kittyServiceProvider);
    await service.addDeposit(
      tripId: widget.tripId,
      memberId: _selectedMemberId!,
      amountInCents: cents,
    );

    _onComplete();
  }

  Future<void> _saveEqualDepositForAll() async {
    if (!_formKey.currentState!.validate()) return;
    final cents = _parseAmountInCents();
    if (cents == null) return;

    final service = ref.read(kittyServiceProvider);
    for (final member in widget.members) {
      await service.addDeposit(
        tripId: widget.tripId,
        memberId: member.id,
        amountInCents: cents,
      );
    }

    _onComplete();
  }

  void _onComplete() {
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.kittyDepositSaved)),
      );
      Navigator.of(context).pop();
      ref.invalidate(tripKittyDataProvider(widget.tripId));
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
              _buildMemberSelector(theme),
              const SizedBox(height: 20),
              _buildAllMembersButton(theme, l10n),
              const SizedBox(height: 12),
              _buildSubmitButton(theme, l10n),
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
        Text(l10n.kittyAddDeposit, style: theme.textTheme.titleMedium),
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
      style: theme.textTheme.headlineMedium?.copyWith(
        fontFamily: 'JetBrains Mono',
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: '${l10n.kittyAmount} (€)',
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

  Widget _buildMemberSelector(ThemeData theme) {
    return DropdownButtonFormField<int>(
      value: _selectedMemberId,
      decoration: const InputDecoration(
        labelText: 'Person',
        border: OutlineInputBorder(),
      ),
      items: widget.members.map((m) {
        return DropdownMenuItem<int>(
          value: m.id,
          child: Text(m.name),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedMemberId = val),
    );
  }

  Widget _buildAllMembersButton(ThemeData theme, AppLocalizations l10n) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.groups_outlined),
      label: Text(l10n.kittyEqualDepositForAll),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _saveEqualDepositForAll,
    );
  }

  Widget _buildSubmitButton(ThemeData theme, AppLocalizations l10n) {
    return FilledButton(
      onPressed: _saveSingleDeposit,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(l10n.kittySaveDeposit),
    );
  }
}
