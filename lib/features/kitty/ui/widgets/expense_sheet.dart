import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/kitty_providers.dart';
import '../../data/kitty_service.dart';
import '../../domain/models/kitty_models.dart';
import '../../domain/models/receipt_models.dart';
import 'receipt_preview_dialog.dart';

/// Sheet zum Erfassen oder Bearbeiten einer Ausgabe.
class ExpenseSheet extends ConsumerStatefulWidget {
  final int tripId;
  final KittyModel kittyModel;
  final List<KittyMember> members;
  final String currency;
  final KittyExpense? expenseToEdit;
  final String? initialTitle;

  const ExpenseSheet({
    super.key,
    required this.tripId,
    required this.kittyModel,
    required this.members,
    required this.currency,
    this.expenseToEdit,
    this.initialTitle,
  });

  /// Zeigt das Bottom Sheet an und liefert 'delete' zurück, falls Löschen gewählt wurde.
  static Future<String?> show(
    BuildContext context, {
    required int tripId,
    required KittyModel kittyModel,
    required List<KittyMember> members,
    required String currency,
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
        currency: currency,
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

  // Belege (RECEIPT1)
  final List<ExpenseReceiptItem> _existingReceipts = [];
  final List<DraftReceipt> _draftReceipts = [];
  final Set<int> _deletedReceiptIds = {};

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

    if (edit != null) {
      _existingReceipts.addAll(edit.receipts);
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

  String get _currencySuffix => widget.currency == 'EUR' ? '€' : widget.currency;

  Future<void> _pickReceiptImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final fileName = picked.name.isNotEmpty
          ? picked.name
          : 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';

      setState(() {
        _draftReceipts.add(
          DraftReceipt(
            bytes: bytes,
            fileName: fileName,
            tempPath: picked.path,
          ),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden des Bildes: $e')),
        );
      }
    }
  }

  void _showImageSourcePicker(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.receiptSourceCamera),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickReceiptImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.receiptSourceGallery),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickReceiptImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final amountStr = _amountController.text.trim().replaceAll(',', '.');
    final amountUnits = double.tryParse(amountStr) ?? 0.0;
    final amountInCents = (amountUnits * 100).round();
    if (amountInCents <= 0) return;

    Map<int, int>? customSplit;
    if (_customSplitEnabled) {
      customSplit = {};
      for (final m in widget.members) {
        final valStr = _splitControllers[m.id]?.text.trim().replaceAll(',', '.') ?? '';
        final memberUnits = double.tryParse(valStr) ?? 0.0;
        customSplit[m.id] = (memberUnits * 100).round();
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
      draftReceipts: widget.expenseToEdit == null ? _draftReceipts : const [],
    );

    if (widget.expenseToEdit != null) {
      await service.updateExpense(id: widget.expenseToEdit!.id, input: input);

      // Gelöschte Belege entfernen
      for (final deletedId in _deletedReceiptIds) {
        await service.deleteReceipt(deletedId);
      }

      // Neu hinzugefügte Belege persistieren
      for (final draft in _draftReceipts) {
        await service.addReceiptToExpense(
          tripId: widget.tripId,
          expenseId: widget.expenseToEdit!.id,
          imageBytes: draft.bytes,
          preferredFileName: draft.fileName,
        );
      }
    } else {
      await service.addExpense(input);
    }

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fundExpenseSaved)),
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
              const SizedBox(height: 16),
              _buildReceiptsSection(theme, l10n),
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
          isEditing ? l10n.edit : l10n.fundAddExpense,
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
        labelText: '${l10n.fundAmount} *',
        suffixText: _currencySuffix,
        border: const OutlineInputBorder(),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return l10n.fundAmount;
        }
        final parsed = double.tryParse(val.trim().replaceAll(',', '.'));
        if (parsed == null || parsed <= 0) {
          return l10n.fundAmount;
        }
        return null;
      },
    );
  }

  Widget _buildTitleField(ThemeData theme, AppLocalizations l10n) {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: l10n.fundTitleField,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCategorySelector(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.fundExpenseCategory, style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ExpenseCategory.values.map((cat) {
            final isSelected = cat == _selectedCategory;
            return ChoiceChip(
              avatar: Icon(cat.icon, size: 18),
              label: Text(cat.localizedName(l10n)),
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
          l10n.fundPaidByTitle,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (isShared) ...[
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text(l10n.fundPayerFund),
                icon: const Icon(Icons.account_balance_wallet_outlined),
              ),
              ButtonSegment(
                value: false,
                label: Text(l10n.fundPayerPerson),
                icon: const Icon(Icons.person_outline),
              ),
            ],
            selected: {_isPaidFromKitty},
            onSelectionChanged: (val) => setState(() {
              _isPaidFromKitty = val.first;
              if (!_isPaidFromKitty && _paidByMemberId == null) {
                _paidByMemberId = widget.members.firstOrNull?.id;
              }
            }),
          ),
          const SizedBox(height: 8),
        ],
        if (!isShared || !_isPaidFromKitty)
          DropdownButtonFormField<int>(
            value: _paidByMemberId,
            decoration: InputDecoration(
              labelText: l10n.fundPaidByTitle,
              border: const OutlineInputBorder(),
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
                return l10n.fundPaidByTitle;
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
        title: Text(l10n.moreOptions, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(l10n.moreOptionsSubtitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const SizedBox(height: 8),
          _buildTitleField(theme, l10n),
          const SizedBox(height: 12),
          _buildCustomSplitToggle(theme, l10n),
          if (_customSplitEnabled) ...[
            const SizedBox(height: 8),
            _buildCustomSplitList(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomSplitToggle(ThemeData theme, AppLocalizations l10n) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.individualSplit),
      subtitle: Text(l10n.individualSplitSubtitle),
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
                  decoration: InputDecoration(
                    suffixText: _currencySuffix,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReceiptsSection(ThemeData theme, AppLocalizations l10n) {
    final totalCount = _existingReceipts.length + _draftReceipts.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.receiptsPdfTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (totalCount > 0)
              Text(
                l10n.receiptAttachedCount(totalCount),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (totalCount == 0)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(l10n.receiptTakePhoto),
            onPressed: () => _showImageSourcePicker(context, l10n),
          )
        else
          SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < _existingReceipts.length; i++)
                  _buildExistingReceiptThumbnail(_existingReceipts[i], i + 1, theme, l10n),
                for (var i = 0; i < _draftReceipts.length; i++)
                  _buildDraftReceiptThumbnail(_draftReceipts[i], _existingReceipts.length + i + 1, theme, l10n),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                      label: Text(l10n.receiptAddAnotherPage),
                      onPressed: () => _showImageSourcePicker(context, l10n),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildExistingReceiptThumbnail(
    ExpenseReceiptItem receipt,
    int index,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final fileService = ref.read(receiptFileServiceProvider);

    return FutureBuilder<String>(
      future: fileService.resolveAbsolutePath(receipt.filePath),
      builder: (context, snapshot) {
        final absPath = snapshot.data;
        final fileExists = absPath != null && File(absPath).existsSync();

        return Container(
          width: 80,
          margin: const EdgeInsets.only(right: 8),
          child: Stack(
            children: [
              InkWell(
                onTap: () {
                  if (absPath != null) {
                    ReceiptPreviewDialog.show(
                      context,
                      title: '${l10n.receiptPreview} #$index',
                      subtitle: receipt.fileName,
                      filePath: absPath,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: fileExists
                      ? Image.file(File(absPath), fit: BoxFit.cover)
                      : const Center(child: Icon(Icons.receipt_outlined)),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _existingReceipts.removeWhere((r) => r.id == receipt.id);
                      _deletedReceiptIds.add(receipt.id);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withAlpha(200),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: theme.colorScheme.error),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraftReceiptThumbnail(
    DraftReceipt draft,
    int index,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              ReceiptPreviewDialog.show(
                context,
                title: '${l10n.receiptPreview} #$index',
                subtitle: draft.fileName,
                imageBytes: draft.bytes,
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.memory(draft.bytes, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _draftReceipts.remove(draft);
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withAlpha(200),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: theme.colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme, AppLocalizations l10n) {
    return FilledButton(
      onPressed: _saveExpense,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(l10n.fundSaveExpense),
    );
  }
}

