/// Warenkorb-Ebene (Basket Tray) für das Flight-Strip-Board (Issue #56).
/// Dient als permanentes Arbeitsziel am unteren Bildschirmrand mit
/// Artikelanzahl, Gewichts-/Volumen-Zusammenfassung und aufklappbarer Detailansicht.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/services/catalog_localization_service.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/core/util/formatters.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'flight_strip_colors.dart';

class BasketTrayWidget extends ConsumerStatefulWidget {
  final TripShoppingListData data;
  final int? selectedStopId;
  final void Function(String listItemId)? onItemRemoved;

  const BasketTrayWidget({
    super.key,
    required this.data,
    this.selectedStopId,
    this.onItemRemoved,
  });

  @override
  ConsumerState<BasketTrayWidget> createState() => _BasketTrayWidgetState();
}

class _BasketTrayWidgetState extends ConsumerState<BasketTrayWidget> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isNightwatch = theme.scaffoldBackgroundColor == Colors.black &&
        theme.colorScheme.primary == const Color(0xFFFF3B30);

    final adoptedItems = widget.data.allItems.where((it) => it.isOnList).toList();
    final itemCount = adoptedItems.length;
    final wv = widget.data.weightAndVolume;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      key: const ValueKey('flight_strip_basket_tray'),
      decoration: BoxDecoration(
        color: isNightwatch
            ? const Color(0xFF1A0000)
            : theme.colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(
            color: isNightwatch
                ? const Color(0xFFFF3B30)
                : theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tray-Header (immer sichtbar am Fuß)
            InkWell(
              onTap: _toggleExpanded,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Korb-Icon mit Zähler
                    Badge(
                      label: Text('$itemCount'),
                      isLabelVisible: itemCount > 0,
                      backgroundColor: isNightwatch
                          ? const Color(0xFFFF3B30)
                          : theme.colorScheme.primary,
                      textColor: isNightwatch ? Colors.black : Colors.white,
                      child: Icon(
                        Icons.shopping_basket,
                        color: isNightwatch
                            ? const Color(0xFFFF3B30)
                            : theme.colorScheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Titel & Gewicht/Volumen
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.basketSummary(itemCount),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (itemCount > 0)
                            Text(
                              l10n.totalWeightVolumeSummary(
                                AppFormatters.formatDecimal(context, wv.totalWeightKg),
                                AppFormatters.formatDecimal(context, wv.totalVolumeLiters),
                                wv.hasItemsWithoutWeight ? ' (+ ${l10n.unitPiece})' : '',
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          else
                            Text(
                              l10n.emptyBasketSubtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),

                    // Aufklappen / Zuklappen Button
                    IconButton(
                      key: const ValueKey('basket_expand_button'),
                      icon: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: _isExpanded ? l10n.hideSkippedItems : l10n.basketTitle,
                      onPressed: _toggleExpanded,
                    ),
                  ],
                ),
              ),
            ),

            // Ausgeklappte Liste der Korb-Inhalte
            if (_isExpanded)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: Column(
                  children: [
                    const Divider(height: 1),
                    Expanded(
                      child: adoptedItems.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.shopping_basket_outlined,
                                      size: 40,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.emptyBasketTitle,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.emptyBasketSubtitle,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              key: const ValueKey('flight_strip_basket_sheet'),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: adoptedItems.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, index) {
                                final item = adoptedItems[index];
                                final itemName = item.localizedName(context);
                                final catColor = FlightStripColors.getCategoryColor(
                                  item.categoryId,
                                  brightness: brightness,
                                  isNightwatch: isNightwatch,
                                );

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      // Farbpunkt für Kategorie
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: catColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Name & Gebindegröße
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              itemName,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${AppFormatters.formatDecimal(context, item.customPackageSize)} ${item.unit}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Stepper im Korb
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 16),
                                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                        padding: EdgeInsets.zero,
                                        tooltip: l10n.removeFromList,
                                        onPressed: () async {
                                          await ref.read(shoppingListServiceProvider).adjustPackagesDelta(
                                                tripId: widget.data.trip.id,
                                                listItemId: item.item.id,
                                                delta: -1,
                                              );
                                          if (!context.mounted) return;
                                          ref.invalidate(tripShoppingListProvider(widget.data.trip.id));
                                        },
                                      ),
                                      Text(
                                        '${item.effectivePackages}',
                                        style: theme.proviantTypography.numberSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 16),
                                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                        padding: EdgeInsets.zero,
                                        tooltip: l10n.addToList,
                                        onPressed: () async {
                                          await ref.read(shoppingListServiceProvider).adjustPackagesDelta(
                                                tripId: widget.data.trip.id,
                                                listItemId: item.item.id,
                                                delta: 1,
                                              );
                                          if (!context.mounted) return;
                                          ref.invalidate(tripShoppingListProvider(widget.data.trip.id));
                                        },
                                      ),

                                      // Löschen-Button
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                        padding: EdgeInsets.zero,
                                        tooltip: l10n.removeFromList,
                                        onPressed: () async {
                                          await ref.read(shoppingListServiceProvider).unadoptItem(
                                                tripId: widget.data.trip.id,
                                                listItemId: item.item.id,
                                              );
                                          if (!context.mounted) return;
                                          widget.onItemRemoved?.call(item.id);
                                          ref.invalidate(tripShoppingListProvider(widget.data.trip.id));
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // Aktion: Einkauf starten
                    if (adoptedItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                          ),
                          icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                          label: Text(l10n.startShopping),
                          onPressed: () {
                            final targetStop = widget.selectedStopId ??
                                widget.data.stops.firstOrNull?.id;
                            if (targetStop != null) {
                              context.push('/trips/${widget.data.trip.id}/shop/$targetStop');
                            }
                          },
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
