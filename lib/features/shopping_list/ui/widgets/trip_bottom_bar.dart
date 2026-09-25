/// Gemeinsame Navigationsleiste mit 4 Reitern innerhalb eines Törns (Design Brief Abschnitt 3).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TripBottomBar extends StatelessWidget {
  final int tripId;
  final int currentIndex;

  const TripBottomBar({
    super.key,
    required this.tripId,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == currentIndex) return;
        switch (index) {
          case 0:
            context.go('/trips/$tripId/shopping-list');
            break;
          case 1:
            context.go('/trips/$tripId/timeline');
            break;
          case 2:
            context.go('/trips/$tripId/kitty');
            break;
          case 3:
            context.go('/trips/$tripId/more');
            break;
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.inventory_2_outlined),
          selectedIcon: const Icon(Icons.inventory_2),
          label: l10n.navShoppingList,
        ),
        NavigationDestination(
          icon: const Icon(Icons.view_timeline_outlined),
          selectedIcon: const Icon(Icons.view_timeline),
          label: l10n.navTrip,
        ),
        NavigationDestination(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: const Icon(Icons.account_balance_wallet),
          label: l10n.navKitty,
        ),
        NavigationDestination(
          icon: const Icon(Icons.more_horiz_outlined),
          selectedIcon: const Icon(Icons.more_horiz),
          label: l10n.navMore,
        ),
      ],
      backgroundColor: theme.colorScheme.surface,
      indicatorColor: theme.colorScheme.secondaryContainer,
    );
  }
}
