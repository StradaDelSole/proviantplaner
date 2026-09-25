/// Dialog zum Ändern der Packungsgröße einer Variante (SC-LST-03).
library;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import '../../domain/models/shopping_list_models.dart';

class PackageSizeDialog extends StatefulWidget {
  final ShoppingListItemView item;

  const PackageSizeDialog({super.key, required this.item});

  static Future<double?> show(BuildContext context, ShoppingListItemView item) {
    return showDialog<double>(
      context: context,
      builder: (ctx) => PackageSizeDialog(item: item),
    );
  }

  @override
  State<PackageSizeDialog> createState() => _PackageSizeDialogState();
}

class _PackageSizeDialogState extends State<PackageSizeDialog> {
  late TextEditingController _sizeController;
  bool _remember = true;

  @override
  void initState() {
    super.initState();
    final currentSize = widget.item.effectivePackSize;
    final formatted = (currentSize % 1 == 0)
        ? currentSize.toInt().toString()
        : currentSize.toStringAsFixed(1);
    _sizeController = TextEditingController(text: formatted);
  }

  @override
  void dispose() {
    _sizeController.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = double.tryParse(_sizeController.text.trim().replaceAll(',', '.'));
    if (parsed != null && parsed > 0) {
      Navigator.of(context).pop(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'Packungsgröße ${widget.item.name}',
        style: theme.textTheme.titleMedium,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sizeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: theme.proviantTypography.numberLarge,
                  decoration: InputDecoration(
                    labelText: l10n.packSizeValue,
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.item.unit,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.rememberForFutureTrips, style: theme.textTheme.bodyMedium),
            value: _remember,
            onChanged: (val) => setState(() => _remember = val),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.packSizeRecalcNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.takeOver),
        ),
      ],
    );
  }
}
