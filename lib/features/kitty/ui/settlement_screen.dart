/// Bildschirm zum Abschluss des Törns und zur Abrechnung (SC-KAS-05).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../data/kitty_providers.dart';
import '../data/kitty_service.dart';
import '../domain/models/kitty_models.dart';
import 'widgets/epc_qr_widget.dart';

/// Screen für den Törnabschluss mit Ausgleichszahlungen und EPC-QR-Code.
class SettlementScreen extends ConsumerStatefulWidget {
  final int tripId;

  const SettlementScreen({super.key, required this.tripId});

  @override
  ConsumerState<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends ConsumerState<SettlementScreen> {
  final Set<int> _expandedIndices = {0};
  final Set<int> _settledIndices = {};

  void _toggleExpanded(int index) {
    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices.remove(index);
      } else {
        _expandedIndices.add(index);
      }
    });
  }

  void _toggleSettled(int index) {
    setState(() {
      if (_settledIndices.contains(index)) {
        _settledIndices.remove(index);
      } else {
        _settledIndices.add(index);
      }
    });
  }

  Future<void> _archiveTrip(BuildContext context) async {
    final service = ref.read(kittyServiceProvider);
    await service.archiveTrip(widget.tripId);
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.kittyArchiveNotice)),
      );
      try {
        context.go('/');
      } catch (_) {
        Navigator.of(context).maybePop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(tripKittyDataProvider(widget.tripId));
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.kittySettlementTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Fehler: $err')),
        data: (data) => _buildContent(context, theme, l10n, data),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
  ) {
    final transfers = data.transfers;
    final totalTransferCents = transfers.fold<int>(0, (sum, t) => sum + t.amountInCents);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusBanner(theme, data),
          const SizedBox(height: 16),
          _buildSectionHeader(theme, l10n, transfers.length),
          const SizedBox(height: 12),
          ...transfers.asMap().entries.map((entry) {
            return _buildTransferCard(
              theme,
              l10n,
              data,
              entry.key,
              entry.value,
            );
          }),
          const SizedBox(height: 16),
          _buildFootnoteCard(theme, l10n, totalTransferCents),
          const SizedBox(height: 12),
          _buildComplianceNotice(theme, l10n),
          const SizedBox(height: 24),
          _buildArchiveButton(context, theme, l10n),
          const SizedBox(height: 12),
          _buildPoweredBy(theme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(ThemeData theme, TripKittyData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'STATUS // AUSGLEICHSBERECHNUNG · MINIMAL TRANSFERS',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Icon(Icons.tune, size: 18, color: theme.colorScheme.outline),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, AppLocalizations l10n, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.kittyWhoPaysWhom.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          '$count Zahlungen',
          style: theme.textTheme.labelSmall?.copyWith(
            fontFamily: 'JetBrains Mono',
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildTransferCard(
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
    int index,
    PaymentTransfer transfer,
  ) {
    final isExpanded = _expandedIndices.contains(index);
    final isSettled = _settledIndices.contains(index);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpanded ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: isExpanded ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => _toggleExpanded(index),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isSettled
                  ? theme.colorScheme.secondaryContainer
                  : theme.colorScheme.primaryContainer,
              child: Text(
                transfer.fromMember.name.isNotEmpty
                    ? transfer.fromMember.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: isSettled
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(transfer.fromMember.name, style: theme.textTheme.titleSmall),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 16),
                const SizedBox(width: 6),
                Text(
                  transfer.toMember.name,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            subtitle: Text(
              isSettled ? l10n.kittySettled : 'Bereit zur Überweisung',
              style: TextStyle(
                color: isSettled ? theme.colorScheme.secondary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transfer.formattedAmount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
          if (isExpanded)
            _buildExpandedSection(theme, l10n, data, index, transfer, isSettled),
        ],
      ),
    );
  }

  Widget _buildExpandedSection(
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
    int index,
    PaymentTransfer transfer,
    bool isSettled,
  ) {
    const iban = 'DE89370400440532013000';
    final remittance = 'Törn ${data.trip.name} Bordkasse ${transfer.fromMember.name}';
    final payload = EpcQrPayload(
      beneficiaryName: transfer.toMember.name,
      iban: iban,
      amountInCents: transfer.amountInCents,
      remittanceInformation: remittance,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          EpcQrWidget(payload: payload),
          const SizedBox(height: 16),
          _buildTransferDetailsBox(theme, l10n, transfer.toMember.name, iban, transfer.formattedAmount, remittance),
          const SizedBox(height: 12),
          _buildCopyButton(theme, l10n, transfer.toMember.name, iban, transfer.formattedAmount, remittance),
          const SizedBox(height: 8),
          _buildShareRow(theme, l10n, transfer, iban, remittance),
          const SizedBox(height: 12),
          _buildMarkSettledRow(theme, l10n, index, isSettled),
        ],
      ),
    );
  }

  Widget _buildTransferDetailsBox(
    ThemeData theme,
    AppLocalizations l10n,
    String recipient,
    String iban,
    String amount,
    String remittance,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _detailRow(l10n.kittyReceiver, recipient, theme),
          const Divider(height: 12),
          _detailRow(l10n.kittyIban, 'DE89 5001 •••• •••• 42', theme, mono: true),
          const Divider(height: 12),
          _detailRow(l10n.kittyAmount, amount, theme, mono: true, bold: true),
          const Divider(height: 12),
          _detailRow(l10n.kittyRemittance, remittance, theme),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, ThemeData theme, {bool mono = false, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: mono ? 'JetBrains Mono' : null,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyButton(
    ThemeData theme,
    AppLocalizations l10n,
    String recipient,
    String iban,
    String amount,
    String remittance,
  ) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.content_copy, size: 18),
      label: Text(l10n.kittyCopyIbanData),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        final text = 'Empfänger: $recipient\nIBAN: $iban\nBetrag: $amount\nVerwendungszweck: $remittance';
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.kittyIbanCopied)),
        );
      },
    );
  }

  Widget _buildShareRow(
    ThemeData theme,
    AppLocalizations l10n,
    PaymentTransfer transfer,
    String iban,
    String remittance,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.link, size: 16),
            label: Text(l10n.kittySharePaypal),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final link = 'https://paypal.me/${transfer.toMember.name}/${(transfer.amountInCents / 100).toStringAsFixed(2)}';
              final uri = Uri.parse(link);
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  await Clipboard.setData(ClipboardData(text: link));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PayPal-Link in Zwischenablage kopiert')),
                    );
                  }
                }
              } catch (_) {
                await Clipboard.setData(ClipboardData(text: link));
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.share, size: 16),
            label: Text(l10n.kittyShareRevolut),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final text = 'Bordkasse: ${transfer.fromMember.name} zahlt ${transfer.formattedAmount} an ${transfer.toMember.name}.\n'
                  'IBAN: $iban\n'
                  'Verwendungszweck: $remittance\n'
                  'Revolut: https://revolut.me/${transfer.toMember.name}';
              try {
                await Share.share(text, subject: 'Bordkassen-Ausgleich ${transfer.toMember.name}');
              } catch (_) {
                await Clipboard.setData(ClipboardData(text: text));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zahlungsdetails in Zwischenablage kopiert')),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMarkSettledRow(ThemeData theme, AppLocalizations l10n, int index, bool isSettled) {
    return CheckboxListTile(
      value: isSettled,
      title: Text(isSettled ? l10n.kittySettled : l10n.kittyMarkDone),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      onChanged: (_) => _toggleSettled(index),
    );
  }

  Widget _buildFootnoteCard(ThemeData theme, AppLocalizations l10n, int totalCents) {
    final euros = totalCents ~/ 100;
    final cents = totalCents % 100;
    final totalFormatted = '$euros,${cents.toString().padLeft(2, '0')} €';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 20, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text(l10n.kittyBalancesEqual, style: theme.textTheme.bodyMedium),
            ],
          ),
          Text(
            'Σ $totalFormatted',
            style: theme.textTheme.labelMedium?.copyWith(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceNotice(ThemeData theme, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l10n.kittySettlementNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArchiveButton(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => _archiveTrip(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.archive_outlined),
          const SizedBox(width: 8),
          Text(l10n.kittyArchiveTrip),
        ],
      ),
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
