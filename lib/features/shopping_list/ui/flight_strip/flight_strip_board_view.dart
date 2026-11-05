/// Hauptansicht des Flight-Strip-Boards (Issue #56).
/// Drei Ebenen:
/// 1. Warenkorb (Basket Tray) am unteren Bildschirmrand
/// 2. Farbcodierte Produktgruppen & Subgruppen-Stacks (10 Kategorien / 47 Subgruppen)
/// 3. Einzelne Produkt-Strips mit direkt bedienbarer Mengensteuerung und Swipe-Gesten.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/services/catalog_localization_service.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/add_or_edit_item_sheet.dart';
import 'basket_tray_widget.dart';
import 'flight_strip_colors.dart';
import 'product_strip_widget.dart';

class FlightStripBoardView extends ConsumerStatefulWidget {
  final TripShoppingListData data;
  final int? selectedStopId;

  const FlightStripBoardView({
    super.key,
    required this.data,
    this.selectedStopId,
  });

  @override
  ConsumerState<FlightStripBoardView> createState() => _FlightStripBoardViewState();
}

class _FlightStripBoardViewState extends ConsumerState<FlightStripBoardView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  String? _selectedGroupId;
  final Set<String> _skippedItemIds = {};
  final Set<String> _transferredItemIds = {};
  final Set<String> _pendingOperations = {};
  final Map<String, int> _itemKeyGenerations = {};
  bool _showSkipped = false;

  @override
  void didUpdateWidget(FlightStripBoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    // Erste Kategorie standardmäßig vorauswählen
    if (widget.data.categories.isNotEmpty) {
      _selectedCategoryId = widget.data.categories.first.category.id;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String catId) {
    setState(() {
      _selectedCategoryId = catId;
      _selectedGroupId = null; // Subgruppe zurücksetzen
    });
  }

  void _onSubgroupSelected(String? groupId) {
    setState(() {
      _selectedGroupId = groupId;
    });
  }

  Future<bool> _handleConfirmSwipeToBasket(ShoppingListItemView item, int packages) async {
    // F3: Parallelitäts- und Race-Schutz gegen mehrfache schnelle Aktionen
    if (_pendingOperations.contains(item.id)) return false;
    _pendingOperations.add(item.id);

    final l10n = AppLocalizations.of(context)!;
    final tripId = widget.data.trip.id;
    final itemName = item.localizedName(context);
    final unitStr = item.unit.isNotEmpty ? item.unit : l10n.unitPackage;

    // F1: Vorherigen Zustand erfassen
    final bool wasInBasket = item.isOnList;
    final int priorEffectivePackages = item.effectivePackages;

    // F1: Idempotenz bei bereits im Korb liegenden Artikeln (keine destruktive Änderung)
    if (wasInBasket) {
      _pendingOperations.remove(item.id);
      if (!mounted) return false;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.alreadyInBasketMessage(itemName, priorEffectivePackages, unitStr)),
          duration: const Duration(seconds: 3),
        ),
      );
      return false; // Streifen schnappt zurück, bleibt sichtbar
    }

    try {
      // F3: Persistenz abwarten
      await ref.read(shoppingListServiceProvider).adoptItem(
            tripId: tripId,
            listItemId: item.item.id,
            packages: packages,
          );
      return true;
    } catch (e) {
      _pendingOperations.remove(item.id);
      if (!mounted) return false;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorSavingItem(itemName)),
          action: SnackBarAction(
            label: l10n.retry,
            onPressed: () => _handleQuickAddToBasket(item, packages),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return false; // F3: Bei Persistenzfehler schnappt Streifen zurück
    }
  }

  void _handleDismissedToBasket(ShoppingListItemView item, int packages) {
    _pendingOperations.remove(item.id);
    final l10n = AppLocalizations.of(context)!;
    final tripId = widget.data.trip.id;
    final itemName = item.localizedName(context);
    final unitStr = item.unit.isNotEmpty ? item.unit : l10n.unitPackage;

    setState(() {
      _transferredItemIds.add(item.id);
    });
    ref.invalidate(tripShoppingListProvider(tripId));

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.addedToBasketMessage(itemName, packages, unitStr)),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () async {
            try {
              // F1 / F6: Item wurde neu zum Korb hinzugefügt -> Unadopt & Transferred-Reset bei mounted
              if (mounted) {
                setState(() {
                  _transferredItemIds.remove(item.id);
                  _itemKeyGenerations[item.id] = (_itemKeyGenerations[item.id] ?? 0) + 1;
                });
              }
              await ref.read(shoppingListServiceProvider).unadoptItem(
                    tripId: tripId,
                    listItemId: item.item.id,
                  );
              if (mounted) {
                ref.invalidate(tripShoppingListProvider(tripId));
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.errorSavingItem(itemName))),
                );
              }
            }
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleQuickAddToBasket(ShoppingListItemView item, int packages) async {
    final confirmed = await _handleConfirmSwipeToBasket(item, packages);
    if (confirmed) {
      _handleDismissedToBasket(item, packages);
    }
  }

  void _handleSkip(ShoppingListItemView item) {
    final l10n = AppLocalizations.of(context)!;
    final itemName = item.localizedName(context);

    setState(() {
      _skippedItemIds.add(item.id);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.itemSkippedMessage(itemName)),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () {
            if (!mounted) return;
            setState(() {
              _skippedItemIds.remove(item.id);
            });
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  List<ShoppingListItemView> _getFilteredItems() {
    final all = widget.data.allItems;

    // Falls Suchbegriff aktiv ist, kategorieübergreifend suchen
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      return all.where((it) {
        if (_transferredItemIds.contains(it.id)) return false;
        if (!_showSkipped && _skippedItemIds.contains(it.id)) return false;
        final nameMatch = it.name.toLowerCase().contains(q) ||
            it.localizedName(context).toLowerCase().contains(q);
        final tagMatch = it.variant?.tags.any((t) => t.toLowerCase().contains(q)) ?? false;
        final deptMatch = it.department.toString().toLowerCase().contains(q);
        return nameMatch || tagMatch || deptMatch;
      }).toList();
    }

    // Nach Kategorie filtern
    if (_selectedCategoryId == null) return [];

    final catView = widget.data.categories
        .where((c) => c.category.id == _selectedCategoryId)
        .firstOrNull;
    if (catView == null) return [];

    // Falls eine Subgruppe gewählt ist
    if (_selectedGroupId != null) {
      final groupView = catView.groups
          .where((g) => g.group.id == _selectedGroupId)
          .firstOrNull;
      if (groupView == null) return [];
      return groupView.variants.where((it) {
        if (_transferredItemIds.contains(it.id)) return false;
        return _showSkipped || !_skippedItemIds.contains(it.id);
      }).toList();
    }

    // Alle Varianten der Kategorie
    final items = <ShoppingListItemView>[];
    for (final g in catView.groups) {
      for (final v in g.variants) {
        if (!_transferredItemIds.contains(v.id) && (_showSkipped || !_skippedItemIds.contains(v.id))) {
          items.add(v);
        }
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isNightwatch = theme.scaffoldBackgroundColor == Colors.black &&
        theme.colorScheme.primary == const Color(0xFFFF3B30);

    final filteredItems = _getFilteredItems();

    // Aktuell ausgewählte Kategorieansicht
    final activeCatView = widget.data.categories
        .where((c) => c.category.id == _selectedCategoryId)
        .firstOrNull;
    final hasAdoptedItems = widget.data.allItems.any((it) => it.isOnList);

    return Column(
      children: [
        // 1. Prominente Suchleiste
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: TextField(
            key: const ValueKey('flight_strip_search_field'),
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchProducts,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val);
            },
          ),
        ),

        // 2. Horizontale Kategorie-Auswahl (10 Hauptkategorien)
        if (_searchQuery.trim().isEmpty) ...[
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.data.categories.length,
              itemBuilder: (ctx, index) {
                final catView = widget.data.categories[index];
                final catId = catView.category.id;
                final isSelected = catId == _selectedCategoryId;
                final catColor = FlightStripColors.getCategoryColor(
                  catId,
                  brightness: brightness,
                  isNightwatch: isNightwatch,
                );
                final catIcon = FlightStripColors.getCategoryIcon(catId);
                final adoptedCount = catView.groups.fold<int>(
                  0,
                  (sum, g) => sum + g.variants.where((v) => v.isOnList).length,
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: FilterChip(
                    key: ValueKey('cat_chip_$catId'),
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Icon(
                      catIcon,
                      size: 16,
                      color: isSelected
                          ? (isNightwatch ? Colors.black : Colors.white)
                          : catColor,
                    ),
                    label: Text(
                      adoptedCount > 0 ? '${catView.category.localizedName(context)} ($adoptedCount)' : catView.category.localizedName(context),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? (isNightwatch ? Colors.black : Colors.white)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    selectedColor: isNightwatch ? const Color(0xFFFF3B30) : catColor,
                    backgroundColor: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? (isNightwatch ? const Color(0xFFFF3B30) : catColor)
                            : theme.colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    onSelected: (_) => _onCategorySelected(catId),
                  ),
                );
              },
            ),
          ),

          // 3. Subgruppen-Leiste der ausgewählten Kategorie
          if (activeCatView != null && activeCatView.groups.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  // Chip für "Alle" Subgruppen
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                    child: ChoiceChip(
                      key: const ValueKey('subgroup_chip_all'),
                      selected: _selectedGroupId == null,
                      showCheckmark: false,
                      label: Text(
                        l10n.allSubgroups,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onSelected: (_) => _onSubgroupSelected(null),
                    ),
                  ),
                  ...activeCatView.groups.map((groupView) {
                    final isSelected = groupView.group.id == _selectedGroupId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                      child: ChoiceChip(
                        key: ValueKey('subgroup_chip_${groupView.group.id}'),
                        selected: isSelected,
                        showCheckmark: false,
                        label: Text(
                          groupView.group.localizedName(context),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        onSelected: (_) => _onSubgroupSelected(groupView.group.id),
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],

        // 4. Statuszeile für übersprungene Artikel
        if (_skippedItemIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            child: Row(
              children: [
                Icon(Icons.skip_next_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.showSkippedItems(_skippedItemIds.length),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton(
                  key: const ValueKey('toggle_skipped_button'),
                  onPressed: () {
                    setState(() => _showSkipped = !_showSkipped);
                  },
                  child: Text(_showSkipped ? l10n.hideSkippedItems : l10n.allSubgroups),
                ),
                TextButton(
                  key: const ValueKey('restore_all_skipped_button'),
                  onPressed: () {
                    setState(() {
                      _skippedItemIds.clear();
                      _showSkipped = false;
                    });
                  },
                  child: Text(l10n.restoreAllSkipped),
                ),
              ],
            ),
          ),

        const Divider(height: 1),

        // 5. Scrollbare Liste der Produkt-Strips
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? l10n.emptyListTitle
                              : l10n.emptyListTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchQuery.isNotEmpty
                              ? l10n.emptyListSubtitle
                              : l10n.emptyListSubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  key: const ValueKey('flight_strip_list_view'),
                  padding: const EdgeInsets.only(top: 6, bottom: 12),
                  itemCount: filteredItems.length + (!hasAdoptedItems && _searchQuery.isEmpty ? 1 : 0),
                  itemBuilder: (ctx, index) {
                    if (!hasAdoptedItems && _searchQuery.isEmpty && index == 0) {
                      return Container(
                        key: const ValueKey('empty_list_banner'),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 22, color: theme.colorScheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.emptyListTitle,
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    l10n.emptyListSubtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final itemIndex = (!hasAdoptedItems && _searchQuery.isEmpty) ? index - 1 : index;
                    final item = filteredItems[itemIndex];
                    final gen = _itemKeyGenerations[item.id] ?? 0;
                    return ProductStripWidget(
                      key: ValueKey('strip_widget_${item.id}'),
                      data: widget.data,
                      item: item,
                      generation: gen,
                      onConfirmSwipeToBasket: (packages) => _handleConfirmSwipeToBasket(item, packages),
                      onDismissedToBasket: (packages) => _handleDismissedToBasket(item, packages),
                      onQuickAddToBasket: (packages) => _handleQuickAddToBasket(item, packages),
                      onSkip: () => _handleSkip(item),
                      onTapDetails: () {
                        AddOrEditItemSheet.show(
                          context,
                          data: widget.data,
                          item: item,
                        );
                      },
                    );
                  },
                ),
        ),

        // 6. Permanenter Warenkorb-Tray am Fuß
        BasketTrayWidget(
          data: widget.data,
          selectedStopId: widget.selectedStopId,
          onItemRemoved: (itemId) {
            // F2 / F6: Nach Löschen im Korb sofort wieder auf dem Board anzeigen (nur wenn mounted)
            if (!mounted) return;
            setState(() {
              _transferredItemIds.remove(itemId);
              _itemKeyGenerations[itemId] = (_itemKeyGenerations[itemId] ?? 0) + 1;
            });
          },
        ),
      ],
    );
  }
}
