/// Bottom Sheet zum Erfassen und Bearbeiten einer Ausgabe (SC-KAS-02, FEEDBACK_R1 Punkt 8).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../data/kitty_providers.dart';
import '../../data/kitty_service.dart';
import '../../domain/models/kitty_models.dart';

/// Sheet zum Erfassen oder Bearbeiten einer Ausgabe.
class ExpenseSheet extends ConsumerStatefulWidget {
  final int tripId;
  final KittyModel kittyModel;
  final List<KittyMember> members;
  final KittyExpense? expenseToEdit;
  final String? initialTitle;

  const ExpenseSheet({
    super.key,
    required this.tripId,
    required this.kittyModel,
    required this.members,
    this.expenseToEdit,
    this.initialTitle,
  });

  /// Zeigt das Bottom Sheet an und liefert 'delete' zurück, falls Löschen gewählt wurde.
  static Future<String?> show(
    BuildContext context, {
    required int tripId,
    required KittyModel kittyModel,
    required List<KittyMember> members,
    KittyExpense? expenseToEdit,
    String? initialTitle,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ExpenseSheet(
        tripId: tripId,
        kittyModel: kittyModel,
        members: members,
        expenseToEdit: expenseToEdit,
        initialTitle: initialTitle,
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
    final edit = widget.expenseToEdit;
    _amountController = TextEditingController(
      text: edit != null ? (edit.amountInCents / 100.0).toStringAsFixed(2) : '',
    );
    _titleController = TextEditingController(text: edit?.title ?? widget.initialTitle ?? '');
    _selectedCategory = edit?.category ?? ExpenseCategory.provisions;
    _isPaidFromKitty = edit != null
        ? edit.isPaidFromKitty
        : (widget.kittyModel == KittyModel.sharedKitty);
    _paidByMemberId = edit != null
        ? edit.paidByMemberId
        : widget.members.firstOrNull?.id;
    _customSplitEnabled = edit?.customSplitInCents != null;
    for (final m in widget.members) {
      final customMemberCents = edit?.customSplitInCents?[m.id];
      _splitControllers[m.id] = TextEditingController(
        text: customMemberCents != null ? (customMemberCents / 100.0).toStringAsFixed(2) : '',
      );
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
    final titleText = _titleController.text.trim().isEmpty
        ? _selectedCategory.displayName
        : _titleController.text.trim();

    final input = ExpenseInput(
      tripId: widget.tripId,
      title: titleText,
      amountInCents: amountInCents,
      category: _selectedCategory,
      paidByMemberId: _isPaidFromKitty ? null : _paidByMemberId,
      isPaidFromKitty: _isPaidFromKitty,
      customSplitInCents: customSplit,
      createdAt: widget.expenseToEdit?.createdAt,
    );

    if (widget.expenseToEdit != null) {
      await service.updateExpense(id: widget.expenseToEdit!.id, input: input);
    } else {
      await service.addExpense(input);
    }

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.kittyExpenseSaved)),
      );
      Navigator.of(context).pop('saved');
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
              _buildCategorySelector(theme, l10n),
              const SizedBox(height: 16),
              _buildPayerSelector(theme, l10n),
              const SizedBox(height: 12),
              _buildMoreOptions(theme, l10n),
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
    final isEditing = widget.expenseToEdit != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isEditing ? 'Ausgabe bearbeiten' : l10n.kittyAddExpense,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEditing)
              IconButton(
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                tooltip: l10n.delete,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => Navigator.of(context).pop('delete'),
              ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountField(ThemeData theme, AppLocalizations l10n) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autofocus: widget.expenseToEdit == null,
      decoration: InputDecoration(
        labelText: '${l10n.kittyAmount} *',
        suffixText: '€',
        border: const OutlineInputBorder(),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Bitte einen Betrag eingeben';
        }
        final parsed = double.tryParse(val.trim().replaceAll(',', '.'));
        if (parsed == null || parsed <= 0) {
          return 'Ungültiger Betrag';
        }
        return null;
      },
    );
  }

  Widget _buildTitleField(ThemeData theme, AppLocalizations l10n) {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: l10n.kittyTitleField,
        border: const OutlineInputBorder(),
      ),
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
    final isShared = widget.kittyModel == KittyModel.sharedKitty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.kittyPaidByTitle,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (isShared) ...[
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Kasse'),
                icon: Icon(Icons.account_balance_wallet_outlined),
              ),
              ButtonSegment(
                value: false,
                label: Text('Person'),
                icon: Icon(Icons.person_outline),
              ),
            ],
            selected: {_isPaidFromKitty},
            onSelectionChanged: (val) => setState(() => _isPaidFromKitty = val.first),
          ),
          const SizedBox(height: 8),
        ],
        if (!isShared || !_isPaidFromKitty)
          DropdownButtonFormField<int>(
            value: _paidByMemberId,
            decoration: const InputDecoration(
              labelText: 'Wer hat bezahlt?',
              border: OutlineInputBorder(),
            ),
            items: widget.members.map((m) {
              return DropdownMenuItem(
                value: m.id,
                child: Text(m.name),
              );
            }).toList(),
            onChanged: (val) => setState(() => _paidByMemberId = val),
            validator: (val) {
              if ((!isShared || !_isPaidFromKitty) && val == null) {
                return 'Bitte die zahlende Person auswählen';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildMoreOptions(ThemeData theme, AppLocalizations l10n) {
    final hasCustomContent = _titleController.text.isNotEmpty || _customSplitEnabled;
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: hasCustomContent,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: const Text('Mehr Optionen', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Titel / Notiz, abweichende Aufteilung'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const SizedBox(height: 8),
          _buildTitleField(theme, l10n),
          const SizedBox(height: 12),
          _buildCustomSplitToggle(theme),
          if (_customSplitEnabled) ...[
            const SizedBox(height: 8),
            _buildCustomSplitList(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomSplitToggle(ThemeData theme) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: const Text('Individuelle Betragsaufteilung'),
      subtitle: const Text('Weicht von der regulären Beteiligung ab'),
      value: _customSplitEnabled,
      onChanged: (val) => setState(() => _customSplitEnabled = val),
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
