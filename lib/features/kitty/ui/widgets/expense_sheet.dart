/// Bottom Sheet zum Erfassen einer Ausgabe (SC-KAS-02).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../data/kitty_providers.dart';
import '../../data/kitty_service.dart';
import '../../domain/models/kitty_models.dart';

/// Sheet zum Erfassen einer neuen Ausgabe.
class ExpenseSheet extends ConsumerStatefulWidget {
  final int tripId;
  final KittyModel kittyModel;
  final List<KittyMember> members;

  const ExpenseSheet({
    super.key,
    required this.tripId,
    required this.kittyModel,
    required this.members,
  });

  /// Zeigt das Bottom Sheet an.
  static Future<void> show(
    BuildContext context, {
    required int tripId,
    required KittyModel kittyModel,
    required List<KittyMember> members,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ExpenseSheet(
        tripId: tripId,
        kittyModel: kittyModel,
        members: members,
      ),
    );
  }

  @override
  ConsumerState<ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<ExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _titleController;
  ExpenseCategory _selectedCategory = ExpenseCategory.provisions;
  bool _isPaidFromKitty = true;
  int? _paidByMemberId;
  bool _customSplitEnabled = false;
  final Map<int, TextEditingController> _splitControllers = {};

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _titleController = TextEditingController();
    _isPaidFromKitty = widget.kittyModel == KittyModel.sharedKitty;
    _paidByMemberId = widget.members.firstOrNull?.id;
    for (final m in widget.members) {
      _splitControllers[m.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    for (final c in _splitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final amountStr = _amountController.text.trim().replaceAll(',', '.');
    final amountEuros = double.tryParse(amountStr) ?? 0.0;
    final amountInCents = (amountEuros * 100).round();
    if (amountInCents <= 0) return;

    Map<int, int>? customSplit;
    if (_customSplitEnabled) {
      customSplit = {};
      for (final m in widget.members) {
        final valStr = _splitControllers[m.id]?.text.trim().replaceAll(',', '.') ?? '';
        final memberEuros = double.tryParse(valStr) ?? 0.0;
        customSplit[m.id] = (memberEuros * 100).round();
      }
    }

    final service = ref.read(kittyServiceProvider);
    await service.addExpense(
      ExpenseInput(
        tripId: widget.tripId,
        title: _titleController.text.trim(),
        amountInCents: amountInCents,
        category: _selectedCategory,
        paidByMemberId: _isPaidFromKitty ? null : _paidByMemberId,
        isPaidFromKitty: _isPaidFromKitty,
        customSplitInCents: customSplit,
      ),
    );

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.kittyExpenseSaved)),
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
              _buildTitleField(theme, l10n),
              const SizedBox(height: 16),
              _buildCategorySelector(theme, l10n),
              const SizedBox(height: 16),
              _buildPayerSelector(theme, l10n),
              const SizedBox(height: 16),
              _buildCustomSplitToggle(theme),
              if (_customSplitEnabled) _buildCustomSplitList(theme),
              const SizedBox(height: 24),
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
        Text(
          l10n.kittyAddExpense,
          style: theme.textTheme.titleMedium,
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

  Widget _buildTitleField(ThemeData theme, AppLocalizations l10n) {
    return TextFormField(
      controller: _titleController,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: l10n.kittyTitleField,
        border: const OutlineInputBorder(),
      ),
      validator: (val) =>
          (val == null || val.trim().isEmpty) ? 'Titel erforderlich' : null,
    );
  }

  Widget _buildCategorySelector(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.kittyExpenseCategory, style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ExpenseCategory.values.map((cat) {
            final isSelected = cat == _selectedCategory;
            return ChoiceChip(
              avatar: Icon(cat.icon, size: 18),
              label: Text(cat.displayName),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = cat),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPayerSelector(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.kittyPaidByTitle, style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.kittyModel == KittyModel.sharedKitty)
              ChoiceChip(
                avatar: const Icon(Icons.account_balance_outlined, size: 18),
                label: Text(l10n.kittyPaidFromKitty),
                selected: _isPaidFromKitty,
                onSelected: (_) => setState(() => _isPaidFromKitty = true),
              ),
            ...widget.members.map((m) {
              final isSelected = !_isPaidFromKitty && _paidByMemberId == m.id;
              return ChoiceChip(
                avatar: const Icon(Icons.person_outline, size: 18),
                label: Text(m.name),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _isPaidFromKitty = false;
                  _paidByMemberId = m.id;
                }),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomSplitToggle(ThemeData theme) {
    return SwitchListTile(
      title: const Text('Anders aufteilen'),
      subtitle: const Text('Beträge je Person manuell festlegen'),
      value: _customSplitEnabled,
      onChanged: (val) => setState(() => _customSplitEnabled = val),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildCustomSplitList(ThemeData theme) {
    return Column(
      children: widget.members.map((m) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(m.name)),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _splitControllers[m.id],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    suffixText: '€',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton(ThemeData theme, AppLocalizations l10n) {
    return FilledButton(
      onPressed: _saveExpense,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(l10n.kittySaveExpense),
    );
  }
}
