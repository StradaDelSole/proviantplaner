import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bildschirm für nicht gefundene Routen oder ungültige IDs (FB2-B).
class NotFoundScreen extends StatelessWidget {
  final String? message;

  const NotFoundScreen({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nicht gefunden'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                message ?? 'Die angeforderte Seite oder der Törn wurde nicht gefunden.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Zurück zur Übersicht'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
