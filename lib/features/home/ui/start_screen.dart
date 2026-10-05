/// Startbildschirm "Meine Törns" gemäß UX-A (UX-Konzept 2.1).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/theme/theme_controller.dart';
import 'package:proviantplaner/features/entitlements/data/entitlements_providers.dart';
import 'package:proviantplaner/features/entitlements/ui/unlock_sheet.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';

class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  Future<void> _onNewTripPressed(BuildContext context, WidgetRef ref) async {
    final canCreate = await ref.read(entitlementsServiceProvider).canCreateNewTrip();
    if (!context.mounted) return;
    if (canCreate) {
      context.go('/trips/new');
    } else {
      final unlocked = await UnlockSheet.show(context);
      if (unlocked == true && context.mounted) {
        context.go('/trips/new');
      }
    }
  }

  String _getNextStepText(Trip trip, AppLocalizations l10n) {
    final now = DateTime.now();
    final tripEnded = now.isAfter(trip.startDate.add(Duration(days: trip.daysCount)));
    if (tripEnded) return '${l10n.nextStepLabel}: ${l10n.settle}';
    final tripStarted = now.isAfter(trip.startDate);
    if (tripStarted) return '${l10n.nextStepLabel}: Unterwegs / Bordkasse';
    return '${l10n.nextStepLabel}: ${l10n.editList}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final allTripsAsync = ref.watch(allTripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Meine Törns',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'powered by HullQ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Nachtwache',
            icon: Icon(
              ref.watch(themeControllerProvider) == AppThemeMode.nightwatch
                  ? Icons.nightlight_round
                  : Icons.nightlight_outlined,
            ),
            onPressed: () {
              ref.read(themeControllerProvider.notifier).toggleNightwatch();
            },
          ),
          IconButton(
            tooltip: 'Einstellungen',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.go('/more');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: allTripsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('${l10n.genericError}: $err')),
          data: (trips) {
            final activeTrips = trips.where((t) => !t.isArchived).toList();
            final archivedTrips = trips.where((t) => t.isArchived).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (activeTrips.isEmpty) ...[
                        const SizedBox(height: 32),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.view_timeline_outlined,
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.welcomeHeadline,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.welcomeSubline,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ] else ...[
                        Text(
                          'Aktive Törns (${activeTrips.length})',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...activeTrips.map((trip) => _buildTripCard(context, ref, theme, l10n, trip)),
                        const SizedBox(height: 16),
                      ],
                      // Großer Button "Neuer Törn"
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _onNewTripPressed(context, ref),
                        icon: const Icon(Icons.add),
                        label: Text(
                          l10n.newTripButton,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Eingeklappter Bereich: Archiv
                      if (archivedTrips.isNotEmpty) ...[
                        Theme(
                          data: theme.copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: Text(
                              '${l10n.archiveSectionTitle} (${archivedTrips.length})',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            children: archivedTrips.map((t) => _buildTripCard(context, ref, theme, l10n, t, isArchived: true)).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Dezenter Markenhinweis
                      Center(
                        child: Text(
                          l10n.poweredBy.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.outline,
                            letterSpacing: 1.0,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTripCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    Trip trip, {
    bool isArchived = false,
  }) {
    final nextStep = _getNextStepText(trip, l10n);
    final date = trip.startDate;
    final dateStr = '${date.day}.${date.month}.${date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ref.read(activeTripIdProvider.notifier).state = trip.id;
          context.go('/trips/${trip.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isArchived ? Icons.archive_outlined : Icons.view_timeline_outlined,
                    color: isArchived ? theme.colorScheme.outline : theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      trip.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${trip.daysCount} ${l10n.day}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      nextStep,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
