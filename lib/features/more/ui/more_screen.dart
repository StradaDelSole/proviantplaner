import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:proviantplaner/core/config/app_config.dart';
import 'package:proviantplaner/core/routing/not_found_screen.dart';
import 'package:proviantplaner/core/services/backup_providers.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';
import 'package:proviantplaner/core/services/user_payment_profile_service.dart';
import 'package:proviantplaner/core/theme/theme_controller.dart';
import 'package:proviantplaner/features/entitlements/data/entitlements_providers.dart';
import 'package:proviantplaner/features/entitlements/ui/unlock_sheet.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/shopping_list/data/supplier_service.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bildschirm "Mehr" mit Kontostatus, Sicherung, Darstellung und Abmeldung/Löschung (SC-MORE-01).
class MoreScreen extends ConsumerWidget {
  final int? tripId;

  const MoreScreen({super.key, this.tripId});

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountDeleteConfirmTitle),
        content: Text(l10n.accountDeleteConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.accountDeleteConfirmButton),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authNotifierProvider.notifier).deleteAccount();
      ref.invalidate(entitlementLevelProvider);
      ref.invalidate(canCreateTripProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.accountDeletedNotice)),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(authNotifierProvider.notifier).logout();
    ref.invalidate(entitlementLevelProvider);
    ref.invalidate(canCreateTripProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountLogoutNotice)),
      );
    }
  }

  Future<void> _backupNow(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final success = await ref.read(backupCoordinatorProvider).createBackup();
      ref.invalidate(lastBackupTimestampProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? l10n.accountBackupSuccess : 'Sicherung fehlgeschlagen.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler bei der Sicherung: $e')),
        );
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountBackupRestore),
        content: const Text(
          'Möchtest du alle Törns aus der Cloud-Sicherung wiederherstellen? Bestehende lokale Daten werden überschrieben.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.accountBackupRestore),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final success = await ref.read(backupCoordinatorProvider).restoreBackup();
        ref.invalidate(canCreateTripProvider);
        ref.invalidate(entitlementLevelProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? l10n.accountRestoreSuccess : 'Keine Sicherung gefunden.',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler bei der Wiederherstellung: $e')),
          );
        }
      }
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tripId != null) {
      final tripAsync = ref.watch(tripByIdProvider(tripId!));
      if (tripAsync.hasValue && tripAsync.value == null) {
        return const NotFoundScreen(message: 'Törn nicht gefunden');
      }
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final status = authState.status;
    final email = authState.email ?? '';
    final isNightwatch = ref.watch(themeControllerProvider) == AppThemeMode.nightwatch;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navMore),
        actions: [
          IconButton(
            tooltip: 'Nachtwache',
            icon: Icon(
              isNightwatch ? Icons.nightlight_round : Icons.nightlight_outlined,
            ),
            onPressed: () {
              ref.read(themeControllerProvider.notifier).toggleNightwatch();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildAccountCard(context, ref, theme, l10n, status, email),
          const SizedBox(height: 16),
          _buildNightwatchTile(ref, theme, isNightwatch),
          const Divider(height: 24),
          _buildSectionHeader(theme, 'Einstellungen'),
          ListTile(
            leading: const Icon(Icons.payment_outlined),
            title: const Text('Meine Zahlungsdaten'),
            subtitle: const Text('Nur auf diesem Gerät gespeichert'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUserPaymentProfileDialog(context, ref),
          ),
          Consumer(
            builder: (ctx, ref, _) {
              final suppliersAsync = ref.watch(savedSuppliersProvider);
              final subtitle = suppliersAsync.maybeWhen(
                data: (list) => list.isEmpty
                    ? 'Keine Lieferanten hinterlegt'
                    : '${list.length} Lieferant${list.length == 1 ? "" : "en"} hinterlegt',
                orElse: () => 'Lieferanten verwalten',
              );
              return ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: const Text('Gespeicherte Lieferanten'),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSuppliersDialog(context, ref),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.straighten_outlined),
            title: const Text('Gemerkte Packungsgrößen'),
            subtitle: const Text('Keine Packungsgrößen angepasst'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Sprache'),
            subtitle: const Text('Deutsch'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(height: 24),
          _buildSectionHeader(theme, 'Rechtliches & Information'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _launchExternalUrl(AppConfig.privacyPolicyUrl),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.termsOfUse),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _launchExternalUrl(AppConfig.termsOfServiceUrl),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.imprint),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _launchExternalUrl(AppConfig.imprintUrl),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  'Version ${AppConfig.appVersion} (${AppConfig.buildNumber})',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 4),
                Text(
                  'POWERED BY HULLQ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNightwatchTile(WidgetRef ref, ThemeData theme, bool isNightwatch) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: SwitchListTile(
        title: const Text('Nachtwache-Modus'),
        subtitle: const Text('Reines Rot auf Schwarz zum Erhalt der Nachtsicht'),
        secondary: Icon(
          isNightwatch ? Icons.nightlight_round : Icons.nightlight_outlined,
          color: isNightwatch ? theme.colorScheme.primary : null,
        ),
        value: isNightwatch,
        onChanged: (_) {
          ref.read(themeControllerProvider.notifier).toggleNightwatch();
        },
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    HullqMembershipStatus status,
    String email,
  ) {
    final isLoggedIn = status != HullqMembershipStatus.trial;

    final lastBackupAsync = ref.watch(lastBackupTimestampProvider);
    final lastBackup = lastBackupAsync.valueOrNull;
    final backupSubtitle = lastBackup != null
        ? '${l10n.accountBackupStatus} ${DateFormat('dd.MM.yyyy HH:mm').format(lastBackup)}'
        : l10n.accountBackupNever;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isLoggedIn
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    isLoggedIn ? Icons.person : Icons.person_outline,
                    color: isLoggedIn
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoggedIn ? email : l10n.accountTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLoggedIn
                            ? (status == HullqMembershipStatus.pro
                                ? l10n.accountStatusPro
                                : l10n.accountStatusMember)
                            : l10n.accountNotLoggedIn,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoggedIn)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status == HullqMembershipStatus.pro ? 'PRO' : 'MITGLIED',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isLoggedIn) ...[
              FilledButton.icon(
                icon: const Icon(Icons.lock_open, size: 18),
                label: Text(l10n.accountUnlockFree),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => UnlockSheet.show(context),
              ),
            ] else ...[
              Text(
                backupSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: Text(l10n.accountBackupNow),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                      onPressed: () => _backupNow(context, ref),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, size: 18),
                      label: Text(l10n.accountLogout),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                      onPressed: () => _logout(context, ref),
                    ),
                  ),
                ],
              ),
              if (lastBackup != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cloud_download_outlined, size: 18),
                  label: Text(l10n.accountBackupRestore),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  onPressed: () => _restoreBackup(context, ref),
                ),
              ],
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  icon: Icon(Icons.delete_forever, size: 18, color: theme.colorScheme.error),
                  label: Text(
                    l10n.accountDelete,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  style: TextButton.styleFrom(minimumSize: const Size(120, 48)),
                  onPressed: () => _confirmDeleteAccount(context, ref),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showUserPaymentProfileDialog(BuildContext context, WidgetRef ref) async {
    final service = ref.read(userPaymentProfileServiceProvider);
    final currentProfile = await service.loadProfile();

    if (!context.mounted) return;

    final nameController = TextEditingController(text: currentProfile.name);
    final ibanController = TextEditingController(text: currentProfile.iban ?? '');
    final paypalController = TextEditingController(text: currentProfile.paypalLink ?? '');
    final revolutController = TextEditingController(text: currentProfile.revolutLink ?? '');
    String? ibanError;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Meine Zahlungsdaten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nur auf diesem Gerät gespeichert. Werden bei Abrechnungen als Empfängerdaten genutzt.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ibanController,
                  decoration: InputDecoration(
                    labelText: 'IBAN',
                    errorText: ibanError,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paypalController,
                  decoration: const InputDecoration(
                    labelText: 'PayPal.Me Link',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: revolutController,
                  decoration: const InputDecoration(
                    labelText: 'Revolut.Me Link',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                final rawIban = ibanController.text.trim();
                final cleanIban = rawIban.replaceAll(RegExp(r'\s+'), '').toUpperCase();
                if (cleanIban.isNotEmpty && !IbanValidator.isValid(cleanIban)) {
                  setDialogState(() {
                    ibanError = 'Ungültige IBAN (Modulo-97 Prüfsummenfehler)';
                  });
                  return;
                }

                await service.saveProfile(
                  UserPaymentProfile(
                    name: nameController.text.trim(),
                    iban: cleanIban.isNotEmpty ? cleanIban : null,
                    paypalLink: paypalController.text.trim().isNotEmpty ? paypalController.text.trim() : null,
                    revolutLink: revolutController.text.trim().isNotEmpty ? revolutController.text.trim() : null,
                  ),
                );
                ref.invalidate(userPaymentProfileProvider);

                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zahlungsdaten gespeichert.')),
                  );
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSuppliersDialog(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final theme = Theme.of(ctx);
          final suppliersAsync = ref.watch(savedSuppliersProvider);

          return Scaffold(
            appBar: AppBar(
              title: const Text('Gespeicherte Lieferanten'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Lieferant hinzufügen',
                  onPressed: () => _showAddEditSupplierDialog(context, ref),
                ),
              ],
            ),
            body: suppliersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Fehler: $err')),
              data: (suppliers) {
                if (suppliers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          const Text(
                            'Noch keine Lieferanten hinterlegt.\nLieferanten können hier oder beim Anfordern einer Lieferung angelegt werden.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Lieferant hinzufügen'),
                            onPressed: () => _showAddEditSupplierDialog(context, ref),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: suppliers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final s = suppliers[i];
                    final subtitleParts = <String>[];
                    if (s.marina != null && s.marina!.isNotEmpty) subtitleParts.add(s.marina!);
                    if (s.phone != null && s.phone!.isNotEmpty) subtitleParts.add(s.phone!);
                    if (s.email != null && s.email!.isNotEmpty) subtitleParts.add(s.email!);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.local_shipping_outlined, color: theme.colorScheme.onPrimaryContainer, size: 20),
                      ),
                      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: subtitleParts.isNotEmpty ? Text(subtitleParts.join(' · ')) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Bearbeiten',
                            onPressed: () => _showAddEditSupplierDialog(context, ref, supplierToEdit: s),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                            tooltip: 'Löschen',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  title: const Text('Lieferant löschen'),
                                  content: Text('Möchtest du "${s.name}" wirklich löschen?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Abbrechen')),
                                    FilledButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Löschen')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(supplierServiceProvider).deleteSupplier(s.id);
                                ref.invalidate(savedSuppliersProvider);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Lieferant hinzufügen'),
                  onPressed: () => _showAddEditSupplierDialog(context, ref),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddEditSupplierDialog(
    BuildContext context,
    WidgetRef ref, {
    SupplierProfile? supplierToEdit,
  }) async {
    final nameCtrl = TextEditingController(text: supplierToEdit?.name ?? '');
    final marinaCtrl = TextEditingController(text: supplierToEdit?.marina ?? '');
    final phoneCtrl = TextEditingController(text: supplierToEdit?.phone ?? '');
    final emailCtrl = TextEditingController(text: supplierToEdit?.email ?? '');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(supplierToEdit != null ? 'Lieferant bearbeiten' : 'Lieferant hinzufügen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name des Lieferanten / Marktes', border: OutlineInputBorder()),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: marinaCtrl,
                decoration: const InputDecoration(labelText: 'Marina / Ort', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Telefonnummer', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'E-Mail', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final newSupplier = SupplierProfile(
                id: supplierToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                marina: marinaCtrl.text.trim().isNotEmpty ? marinaCtrl.text.trim() : null,
                phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
              );
              await ref.read(supplierServiceProvider).saveSupplier(newSupplier);
              ref.invalidate(savedSuppliersProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}
