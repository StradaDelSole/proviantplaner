/// Such-Delegate für den Vorratskatalog (SC-LST-06).
library;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/services/catalog_localization_service.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'add_or_edit_item_sheet.dart';
import 'custom_item_sheet.dart';

class CatalogSearchDelegate extends SearchDelegate<ShoppingListItemView?> {
  final TripShoppingListData data;
  final BuildContext? parentContext;
  final String? _customSearchFieldLabel;

  CatalogSearchDelegate({
    required this.data,
    this.parentContext,
    String? searchFieldLabel,
  }) : _customSearchFieldLabel = searchFieldLabel;

  @override
  String? get searchFieldLabel => _customSearchFieldLabel;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  /// Filtert Positionen für einen Suchbegriff (ohne oder mit BuildContext für Lokalisierung).
  List<ShoppingListItemView> filterItems(String query, [BuildContext? context]) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return data.allItems.where((it) {
      final locName = context != null ? it.localizedName(context).toLowerCase() : it.name.toLowerCase();
      final nameMatches = it.name.toLowerCase().contains(q) || locName.contains(q);
      final deptMatches = it.department.rawValue.toLowerCase().contains(q) ||
          (context != null ? it.department.localizedName(context).toLowerCase().contains(q) : false);
      final catMatches = it.categoryId.toLowerCase().contains(q);
      final tagMatches = it.variant?.tags.any((t) => t.toLowerCase().contains(q)) ?? false;
      return nameMatches || deptMatches || catMatches || tagMatches;
    }).toList();
  }

  Widget _buildSearchResults(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.searchHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.addCustomItem),
              onPressed: () {
                final targetContext = parentContext ?? context;
                close(context, null);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (targetContext.mounted) {
                    CustomItemSheet.show(
                      targetContext,
                      tripId: data.trip.id,
                      stops: data.stops,
                    );
                  }
                });
              },
            ),
          ],
        ),
      );
    }

    final matches = filterItems(query, context);

    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                l10n.noSearchResults,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('no_results_custom_item_btn'),
                icon: const Icon(Icons.add),
                label: Text(l10n.addAsCustomItemNamed(query.trim())),
                onPressed: () {
                  final targetContext = parentContext ?? context;
                  close(context, null);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (targetContext.mounted) {
                      CustomItemSheet.show(
                        targetContext,
                        tripId: data.trip.id,
                        stops: data.stops,
                        initialName: query.trim(),
                      );
                    }
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: matches.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        if (i == matches.length) {
          return ListTile(
            leading: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
            title: Text(
              l10n.addAsCustomItemNamed(query.trim()),
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              final targetContext = parentContext ?? context;
              close(context, null);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (targetContext.mounted) {
                  CustomItemSheet.show(
                    targetContext,
                    tripId: data.trip.id,
                    stops: data.stops,
                    initialName: query.trim(),
                  );
                }
              });
            },
          );
        }
        final it = matches[i];
        final sizeFormatted = (it.effectivePackSize % 1 == 0)
            ? it.effectivePackSize.toInt().toString()
            : it.effectivePackSize.toStringAsFixed(1);
        final packUnit = it.variant?.pack.unit ?? it.unit;

        return ListTile(
          title: Text(it.localizedName(context), style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
          subtitle: Text(
            it.isOnList
                ? '${it.department.localizedName(context)} · ${l10n.onListStatus}: ${it.packDisplay}'
                : '${it.department.localizedName(context)} · $sizeFormatted $packUnit',
            style: theme.textTheme.bodySmall?.copyWith(
              color: it.isOnList ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: it.isOnList
              ? Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 22)
              : Icon(Icons.add_circle_outline, color: theme.colorScheme.primary, size: 22),
          onTap: () {
            final targetContext = parentContext ?? context;
            close(context, it);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (targetContext.mounted) {
                AddOrEditItemSheet.show(
                  targetContext,
                  data: data,
                  item: it,
                  isAdding: !it.isOnList,
                );
              }
            });
          },
        );
      },
    );
  }
}
