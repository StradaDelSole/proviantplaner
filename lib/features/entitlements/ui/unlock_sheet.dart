/// Bottom Sheet zur Kontoaktivierung / Freischaltung (SC-ACC-01).
///
/// Törn-Codes sind für v1.1 vorgesehen und in v1 standardmäßig hinter
/// [tripCodeFeatureFlagProvider] verborgen (GEMINI.md Regel 10).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/services/backup_providers.dart';
import '../data/entitlements_providers.dart';

/// Sheet zur Kontoaktivierung / Freischaltung (SC-ACC-01).
class UnlockSheet extends ConsumerStatefulWidget {
  final bool isOffline;

  const UnlockSheet({super.key, this.isOffline = false});

  /// Öffnet das Bottom Sheet modal.
  static Future<bool?> show(BuildContext context, {bool isOffline = false}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => UnlockSheet(isOffline: isOffline),
    );
  }

  @override
  ConsumerState<UnlockSheet> createState() => _UnlockSheetState();
}

class _UnlockSheetState extends ConsumerState<UnlockSheet> {
  // Verbindliche Designregel 4 & GEMINI.md: Checkbox IMMER initial unmarkiert (false)
  bool _newsletterOptIn = false;
  bool _showCodeInput = false;
  bool _showEmailInput = false;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _login(Future<bool> Function() authAction) async {
    final success = await authAction();
    if (success && mounted) {
      await ref.read(authNotifierProvider.notifier).refresh();
      if (!mounted) return;
      try {
        final coordinator = ref.read(backupCoordinatorProvider);
        if (await coordinator.hasBackup()) {
          await coordinator.restoreBackup();
        }
      } catch (_) {}
      if (!mounted) return;
      ref.invalidate(entitlementLevelProvider);
      ref.invalidate(canCreateTripProvider);
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final service = ref.read(entitlementsServiceProvider);
    final success = await service.redeemTripCode(code);
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (success) {
      ref.invalidate(entitlementLevelProvider);
      ref.invalidate(canCreateTripProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tripCodeSuccess)),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tripCodeInvalid)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final showTripCode = ref.watch(tripCodeFeatureFlagProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDragHandle(theme),
            const SizedBox(height: 12),
            _buildHeader(theme, l10n),
            const SizedBox(height: 16),
            _buildFeatureBadges(theme, l10n),
            const SizedBox(height: 20),
            _buildLoginButtons(theme, l10n),
            const SizedBox(height: 12),
            _buildConsentCheckbox(theme, l10n),
            if (showTripCode) ...[
              const SizedBox(height: 16),
              _buildCodeSection(theme, l10n),
            ],
            const SizedBox(height: 16),
            _buildLegalFooter(theme, l10n),
            const SizedBox(height: 12),
            _buildPoweredBy(theme),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(ThemeData theme) {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.unlockTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.unlockSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureBadges(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _featureRow(Icons.all_inclusive, l10n.benefitUnlimitedTrips, theme),
          const Divider(height: 16),
          _featureRow(Icons.cloud_sync_outlined, l10n.benefitBackup, theme),
          const Divider(height: 16),
          _featureRow(Icons.devices_outlined, l10n.benefitDevices, theme),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.secondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButtons(ThemeData theme, AppLocalizations l10n) {
    final auth = ref.read(hullqAuthServiceProvider);
    final disabled = widget.isOffline;

    return Column(
      children: [
        if (widget.isOffline)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 16, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  l10n.offlineLoginNotice,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.g_mobiledata, size: 24),
          label: Text(l10n.loginGoogle),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: disabled ? null : () => _login(() => auth.loginWithGoogle(newsletterOptIn: _newsletterOptIn)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.apple, size: 20),
          label: Text(l10n.loginApple),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: disabled ? null : () => _login(() => auth.loginWithApple(newsletterOptIn: _newsletterOptIn)),
        ),
        const SizedBox(height: 8),
        if (!_showEmailInput)
          FilledButton.icon(
            icon: const Icon(Icons.mail_outline, size: 18),
            label: Text(l10n.loginEmail),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: disabled ? null : () => setState(() => _showEmailInput = true),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.enterEmailTitle,
                    hintText: l10n.emailHint,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: disabled
                      ? null
                      : () {
                          final email = _emailController.text.trim();
                          if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.emailInvalid)),
                            );
                            return;
                          }
                          _login(() => auth.loginWithEmail(email, newsletterOptIn: _newsletterOptIn));
                        },
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: Text(l10n.loginEmail),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildConsentCheckbox(ThemeData theme, AppLocalizations l10n) {
    return CheckboxListTile(
      value: _newsletterOptIn,
      onChanged: (val) => setState(() => _newsletterOptIn = val ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(
        l10n.consentNewsletter,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildCodeSection(ThemeData theme, AppLocalizations l10n) {
    if (!_showCodeInput) {
      return TextButton.icon(
        icon: const Icon(Icons.vpn_key_outlined, size: 18),
        label: Text(l10n.redeemTripCode),
        onPressed: () => setState(() => _showCodeInput = true),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: l10n.tripCodeField,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _redeemCode,
          style: FilledButton.styleFrom(
            minimumSize: const Size(80, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Einlösen'),
        ),
      ],
    );
  }

  Widget _buildLegalFooter(ThemeData theme, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(l10n.privacyPolicy, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('·'),
        ),
        Text(l10n.termsOfUse, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('·'),
        ),
        Text(l10n.imprint, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
      ],
    );
  }

  Widget _buildPoweredBy(ThemeData theme) {
    return Text(
      'POWERED BY HULLQ',
      textAlign: TextAlign.center,
      style: theme.textTheme.labelSmall?.copyWith(
        letterSpacing: 1.5,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
