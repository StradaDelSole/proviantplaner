/// Widget zur Darstellung eines Tages in der Tagesleiste mit Restaurant-Umschaltern (Slice S3, Mockup 06).
library;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';

class DayCard extends StatelessWidget {
  final TripDay day;
  final List<ShoppingStop> shoppingStops;
  final VoidCallback onToggleLunch;
  final VoidCallback onToggleEvening;
  final ValueChanged<String?> onUpdatePortName;

  const DayCard({
    super.key,
    required this.day,
    required this.shoppingStops,
    required this.onToggleLunch,
    required this.onToggleEvening,
    required this.onUpdatePortName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final dayFormatted = day.dayNumber.toString().padLeft(2, '0');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${l10n.day.toUpperCase()} $dayFormatted',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final controller = TextEditingController(text: day.portName ?? '');
                      final result = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.portName),
                          content: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: l10n.portName,
                              border: const OutlineInputBorder(),
                            ),
                            autofocus: true,
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
                            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(l10n.save)),
                          ],
                        ),
                      );
                      if (result != null) {
                        onUpdatePortName(result.isEmpty ? null : result);
                      }
                    },
                    child: Text(
                      day.portName ?? l10n.portName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: day.portName != null ? theme.colorScheme.onSurface : theme.colorScheme.outline,
                        fontStyle: day.portName == null ? FontStyle.italic : FontStyle.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Restaurant-Umschalter Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Mittagessen Schalter
                ActionChip(
                  avatar: Icon(
                    day.lunchRestaurant ? Icons.restaurant : Icons.soup_kitchen,
                    size: 16,
                    color: day.lunchRestaurant ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurfaceVariant,
                  ),
                  label: Text(day.lunchRestaurant ? l10n.lunchRestaurant : l10n.lunchBoard),
                  backgroundColor: day.lunchRestaurant
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.surfaceContainerLow,
                  side: BorderSide(
                    color: day.lunchRestaurant
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.outlineVariant,
                  ),
                  onPressed: onToggleLunch,
                ),
                // Abendessen Schalter
                ActionChip(
                  avatar: Icon(
                    day.dinnerRestaurant ? Icons.restaurant : Icons.soup_kitchen,
                    size: 16,
                    color: day.dinnerRestaurant ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurfaceVariant,
                  ),
                  label: Text(day.dinnerRestaurant ? l10n.eveningRestaurant : l10n.eveningBoard),
                  backgroundColor: day.dinnerRestaurant
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.surfaceContainerLow,
                  side: BorderSide(
                    color: day.dinnerRestaurant
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.outlineVariant,
                  ),
                  onPressed: onToggleEvening,
                ),
              ],
            ),
            // Einkaufsstopps an diesem Tag
            if (shoppingStops.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              ...shoppingStops.map((stop) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, size: 16, color: theme.colorScheme.secondary),
                    const SizedBox(width: 6),
                    Text(stop.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (stop.isInitial) ...[
                      const SizedBox(width: 6),
                      Text('(Basis)', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                    ],
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
