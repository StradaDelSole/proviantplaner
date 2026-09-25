import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/core/theme/theme_controller.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';

/// Startbildschirm gemäß Slice S0 & S3.
/// Zeigt den App-Namen sowie das dezente "powered by HullQ",
/// Einstiegspunkte zum Törn anlegen und die vier Hauptnavigationsreiter.
class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final activeTripAsync = ref.watch(activeTripProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.appTitle ?? 'Proviantplaner',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                l10n?.poweredBy ?? 'POWERED BY HULLQ',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Dezentes maritimes technisches Symbol / Blueprint Icon (keine Segel/Anker)
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.view_timeline_outlined,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n?.welcomeHeadline ?? 'Törnplanung leicht gemacht',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.welcomeSubline ??
                      'Proviant kalkulieren, Vorräte verwalten und Bordkasse fair aufteilen.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                // Aktiver Törn oder Button für neuen Törn
                activeTripAsync.when(
                  loading: () => const SizedBox(height: 48),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (trip) {
                    if (trip != null) {
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: theme.colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined, color: theme.colorScheme.secondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      trip.name,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(
                                    '${trip.daysCount} ${l10n?.day ?? "Tage"}',
                                    style: theme.proviantTypography.numberMedium.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => context.go('/trips/new'),
                                      child: Text(l10n?.newTripButton ?? '+ Neuer Törn'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () => context.go('/trips/${trip.id}/timeline'),
                                      child: Text(l10n?.navTrip ?? 'Törn öffnen'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return FilledButton.icon(
                      onPressed: () => context.go('/trips/new'),
                      icon: const Icon(Icons.add),
                      label: Text(l10n?.newTripButton ?? 'Neuen Törn anlegen'),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Dezentes Label unten
                Text(
                  l10n?.poweredBy ?? 'POWERED BY HULLQ',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.outline,
                    letterSpacing: 0.8,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
          if (index == 1) {
            final activeTrip = activeTripAsync.valueOrNull;
            if (activeTrip != null) {
              context.go('/trips/${activeTrip.id}/timeline');
            } else {
              context.go('/trips/new');
            }
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist),
            label: l10n?.navShoppingList ?? 'Liste',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n?.navTrip ?? 'Törn',
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: l10n?.navKitty ?? 'Bordkasse',
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            selectedIcon: const Icon(Icons.more_horiz),
            label: l10n?.navMore ?? 'Mehr',
          ),
        ],
      ),
    );
  }
}
