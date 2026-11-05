/// Einzelner Flugstreifen (Product Strip) für das Flight-Strip-Board (Issue #56).
/// Stellt ein Produkt kompakt, farbcodiert und mit direkt bedienbarer Mengensteuerung dar.
/// Unterstützt Swipe-Right (in den Korb), Swipe-Left (überspringen) sowie barrierefreie Schaltflächen.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/services/catalog_localization_service.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/core/util/formatters.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'flight_strip_colors.dart';

class ProductStripWidget extends ConsumerStatefulWidget {
  final TripShoppingListData data;
  final ShoppingListItemView item;
  final int generation;
  final Future<bool> Function(int packages) onConfirmSwipeToBasket;
  final void Function(int packages) onDismissedToBasket;
  final Future<void> Function(int packages) onQuickAddToBasket;
  final VoidCallback onSkip;
  final VoidCallback? onTapDetails;

  const ProductStripWidget({
    super.key,
    required this.data,
    required this.item,
    this.generation = 0,
    required this.onConfirmSwipeToBasket,
    required this.onDismissedToBasket,
    required this.onQuickAddToBasket,
    required this.onSkip,
    this.onTapDetails,
  });

  @override
  ConsumerState<ProductStripWidget> createState() => _ProductStripWidgetState();
}

class _ProductStripWidgetState extends ConsumerState<ProductStripWidget> {
  late int _stagedPackages;

  @override
  void initState() {
    super.initState();
    _initStagedPackages();
  }

  @override
  void didUpdateWidget(covariant ProductStripWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.isOnList != oldWidget.item.isOnList ||
        widget.item.effectivePackages != oldWidget.item.effectivePackages) {
      _initStagedPackages();
    }
  }

  void _initStagedPackages() {
    if (widget.item.isOnList) {
      _stagedPackages = widget.item.effectivePackages;
    } else if (widget.item.calculatedPackages > 0) {
      _stagedPackages = widget.item.calculatedPackages;
    } else {
      // Präferenz- oder unberechnete Artikel starten sichtbar bei 1 Packung (Owner-Vorgabe #56)
      _stagedPackages = 1;
    }
  }

  Future<void> _handleDecrement() async {
    HapticFeedback.selectionClick();
    if (widget.item.isOnList) {
      await ref.read(shoppingListServiceProvider).adjustPackagesDelta(
            tripId: widget.data.trip.id,
            listItemId: widget.item.item.id,
            delta: -1,
          );
    } else {
      if (_stagedPackages > 1) {
        setState(() => _stagedPackages--);
      }
    }
  }

  Future<void> _handleIncrement() async {
    HapticFeedback.selectionClick();
    if (widget.item.isOnList) {
      await ref.read(shoppingListServiceProvider).adjustPackagesDelta(
            tripId: widget.data.trip.id,
            listItemId: widget.item.item.id,
            delta: 1,
          );
    } else {
      setState(() => _stagedPackages++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isNightwatch = theme.scaffoldBackgroundColor == Colors.black &&
        theme.colorScheme.primary == const Color(0xFFFF3B30);

    final catId = widget.item.categoryId;
    final categoryColor = FlightStripColors.getCategoryColor(
      catId,
      brightness: brightness,
      isNightwatch: isNightwatch,
    );
    final categoryIcon = FlightStripColors.getCategoryIcon(catId);

    final isInBasket = widget.item.isOnList;
    final activePackages = isInBasket ? widget.item.effectivePackages : _stagedPackages;
    final itemName = widget.item.localizedName(context);

    // Packungsbeschriftung
    final packUnit = widget.item.unit.isNotEmpty ? widget.item.unit : l10n.unitPackage;
    final packSizeStr = widget.item.customPackageSize > 0
        ? '${AppFormatters.formatDecimal(context, widget.item.customPackageSize)} $packUnit'
        : packUnit;

    return Dismissible(
      key: ValueKey('strip_dismissible_${widget.item.id}_${widget.generation}'),
      direction: DismissDirection.horizontal,
      resizeDuration: const Duration(milliseconds: 180),
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: isNightwatch ? const Color(0xFF8B0000) : Colors.green.shade700,
        icon: Icons.shopping_basket_outlined,
        label: l10n.swipeActionAdd,
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: isNightwatch ? const Color(0xFF330000) : Colors.blueGrey.shade700,
        icon: Icons.skip_next_outlined,
        label: l10n.swipeActionSkip,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return await widget.onConfirmSwipeToBasket(activePackages);
        } else if (direction == DismissDirection.endToStart) {
          widget.onSkip();
          return true;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.mediumImpact();
          widget.onDismissedToBasket(activePackages);
        } else if (direction == DismissDirection.endToStart) {
          HapticFeedback.lightImpact();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isInBasket
              ? (isNightwatch
                  ? const Color(0xFF220000)
                  : theme.colorScheme.primaryContainer.withOpacity(0.2))
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isInBasket
                ? (isNightwatch ? const Color(0xFFFF3B30) : theme.colorScheme.primary)
                : theme.colorScheme.outlineVariant.withOpacity(0.6),
            width: isInBasket ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Linker ATC-Farbbalken mit Ikonografie
                Container(
                  width: 38,
                  color: categoryColor.withOpacity(0.9),
                  child: Center(
                    child: Icon(
                      categoryIcon,
                      size: 20,
                      color: isNightwatch
                          ? Colors.black
                          : (categoryColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white),
                    ),
                  ),
                ),

                // 2. Streifen-Inhalt (Tippen öffnet Detailansicht)
                Expanded(
                  child: InkWell(
                    onTap: widget.onTapDetails,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  itemName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isInBasket)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isNightwatch
                                            ? const Color(0xFFFF3B30)
                                            : theme.colorScheme.primary)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isNightwatch
                                          ? const Color(0xFFFF3B30)
                                          : theme.colorScheme.primary,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check,
                                        size: 12,
                                        color: isNightwatch
                                            ? const Color(0xFFFF3B30)
                                            : theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        l10n.inBasketBadge(activePackages),
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: isNightwatch
                                              ? const Color(0xFFFF3B30)
                                              : theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                packSizeStr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (widget.item.isCooled)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.tertiaryContainer.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.ac_unit,
                                        size: 11,
                                        color: theme.colorScheme.onTertiaryContainer,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        l10n.reviewInlineFridgeHint,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontSize: 10,
                                          color: theme.colorScheme.onTertiaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Direkt auf dem Streifen bedienbare Mengensteuerung (− / Count / +)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus-Button (mind. 48x48dp Barrierefreiheit)
                      IconButton(
                        key: ValueKey('strip_minus_${widget.item.id}'),
                        icon: const Icon(Icons.remove, size: 18),
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        padding: EdgeInsets.zero,
                        tooltip: l10n.removeFromList,
                        onPressed: _handleDecrement,
                      ),
                      // Sichtbare Anzahl
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 26),
                        child: Text(
                          '$activePackages',
                          textAlign: TextAlign.center,
                          style: theme.proviantTypography.numberMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isInBasket
                                ? (isNightwatch
                                    ? const Color(0xFFFF3B30)
                                    : theme.colorScheme.primary)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // Plus-Button (mind. 48x48dp Barrierefreiheit)
                      IconButton(
                        key: ValueKey('strip_plus_${widget.item.id}'),
                        icon: const Icon(Icons.add, size: 18),
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        padding: EdgeInsets.zero,
                        tooltip: l10n.addToList,
                        onPressed: _handleIncrement,
                      ),

                      // Barrierefreie Schnell-Aktion für Touch-Screens ohne Wisch-Zwang
                      if (!isInBasket) ...[
                        const SizedBox(width: 2),
                        IconButton(
                          key: ValueKey('strip_add_btn_${widget.item.id}'),
                          icon: Icon(
                            Icons.add_shopping_cart,
                            size: 20,
                            color: isNightwatch
                                ? const Color(0xFFFF3B30)
                                : theme.colorScheme.primary,
                          ),
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          tooltip: l10n.addToBasketTooltip,
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            await widget.onQuickAddToBasket(activePackages);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerLeft
            ? [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            : [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 24),
              ],
      ),
    );
  }
}
