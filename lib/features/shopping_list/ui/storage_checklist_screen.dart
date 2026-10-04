/// Checkliste für die Einlagerung an Bord (SC-STO-01).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/routing/not_found_screen.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';

class StorageChecklistScreen extends ConsumerWidget {
  final int tripId;

  const StorageChecklistScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final checklistAsync = ref.watch(storageChecklistProvider(tripId));

    if (checklistAsync.hasError) {
      return const NotFoundScreen(message: 'Törn nicht gefunden');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storageTitle),
      ),
      body: checklistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Fehler: $err')),
        data: (entries) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hinweis-Karte oben (Warnung Wellpappe)
              Card(
                color: Colors.amber.shade900.withOpacity(0.12),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.amber.shade700),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.storageNotice,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Checklisten-Punkte je storage_hint
              ...entries.map((entry) => _buildStorageEntryCard(context, ref, entry, theme)),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.storageCompleted)),
              );
              Navigator.of(context).pop();
            },
            child: Text(l10n.storageFinish),
          ),
        ),
      ),
    );
  }

  Widget _buildStorageEntryCard(
    BuildContext context,
    WidgetRef ref,
    StorageChecklistEntry entry,
    ThemeData theme,
  ) {
    final names = entry.affectedItems.map((it) => it.name).take(6).join(', ');
    final suffix = entry.affectedItems.length > 6 ? ' u. a.' : '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Checkbox(
                value: entry.isCompleted,
                onChanged: (val) async {
                  if (val != null) {
                    await ref.read(shoppingListServiceProvider).toggleStorageHint(entry, val);
                    ref.invalidate(storageChecklistProvider(tripId));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: entry.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.explanation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Betrifft: $names$suffix',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
