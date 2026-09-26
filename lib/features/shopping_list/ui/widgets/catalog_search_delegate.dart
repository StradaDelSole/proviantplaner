/// Such-Delegate für den Vorratskatalog (SC-LST-06).
library;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'custom_item_sheet.dart';
import 'group_detail_sheet.dart';

class CatalogSearchDelegate extends SearchDelegate<ShoppingListItemView?> {
  final TripShoppingListData data;

  CatalogSearchDelegate({required this.data});

  @override
  String? get searchFieldLabel => 'Im Vorratskatalog suchen';

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
                close(context, null);
                CustomItemSheet.show(
                  context,
                  tripId: data.trip.id,
                  stops: data.stops,
                );
              },
            ),
          ],
        ),
      );
    }

    final matches = data.allItems.where((it) {
      final nameMatches = it.name.toLowerCase().contains(q);
      final deptMatches = it.department.rawValue.toLowerCase().contains(q);
      final catMatches = it.categoryId.toLowerCase().contains(q);
      return nameMatches || deptMatches || catMatches;
    }).toList();

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
                icon: const Icon(Icons.add),
                label: Text('Als eigene Position anlegen: "${query.trim()}"'),
                onPressed: () {
                  close(context, null);
                  CustomItemSheet.show(
                    context,
                    tripId: data.trip.id,
                    stops: data.stops,
                    initialName: query.trim(),
                  );
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
              'Als eigene Position anlegen: "${query.trim()}"',
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              close(context, null);
              CustomItemSheet.show(
                context,
                tripId: data.trip.id,
                stops: data.stops,
                initialName: query.trim(),
              );
            },
          );
        }
        final it = matches[i];
        return ListTile(
          title: Text(it.name, style: theme.textTheme.bodyLarge),
          subtitle: Text(it.demandDisplay, style: theme.textTheme.bodySmall),
          trailing: Text(
            it.packDisplay,
            style: theme.proviantTypography.numberSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            close(context, it);
            _openDetail(context, it);
          },
        );
      },
    );
  }

  void _openDetail(BuildContext context, ShoppingListItemView it) {
    if (it.variant == null) return;
    for (final cat in data.categories) {
      for (final grp in cat.groups) {
        if (grp.group.id == it.variant!.group) {
          GroupDetailSheet.show(
            context,
            tripId: data.trip.id,
            groupView: grp,
            stops: data.stops,
            isCharter: data.trip.isCharter,
          );
          return;
        }
      }
    }
  }
}
