import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'catalog_search_delegate.dart';
import 'custom_item_sheet.dart';

/// Zentraler Search-First Leerstadium-Zustand für die Vorratsliste (PIVOT1).
class EmptyShoppingListView extends StatelessWidget {
  final TripShoppingListData data;

  const EmptyShoppingListView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.emptyListTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptyListSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: CatalogSearchDelegate(
                    data: data,
                    searchFieldLabel: l10n.searchCatalogPlaceholder,
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: Text(l10n.searchProducts),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                CustomItemSheet.show(
                  context,
                  tripId: data.trip.id,
                  stops: data.stops,
                );
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addCustomItem),
            ),
          ],
        ),
      ),
    );
  }
}
