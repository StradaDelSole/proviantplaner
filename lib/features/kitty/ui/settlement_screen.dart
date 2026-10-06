/// Bildschirm zum Abschluss des Törns und zur Abrechnung (SC-KAS-05).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:proviantplaner/core/routing/not_found_screen.dart';
import 'package:proviantplaner/core/services/pdf_providers.dart';
import '../data/kitty_providers.dart';
import '../data/kitty_service.dart';
import '../domain/models/kitty_models.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';
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
    final tripService = ref.read(tripServiceProvider);
    await tripService.setTripPhase(widget.tripId, TripPhase.conclusion);
    final service = ref.read(kittyServiceProvider);
    await service.archiveTrip(widget.tripId);
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fundArchiveNotice)),
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
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(tripKittyDataProvider(widget.tripId));

    if (asyncData.hasError) {
      if (asyncData.error is LedgerValidationException) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.fundSettlementTitle),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: l10n.previousStep,
              onPressed: () {
                try {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/trips/${widget.tripId}');
                  }
                } catch (_) {
                  Navigator.of(context).maybePop();
                }
              },
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.ledgerDataInvalidTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.ledgerDataInvalidMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      try {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/trips/${widget.tripId}');
                        }
                      } catch (_) {
                        Navigator.of(context).maybePop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.backToHome),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return NotFoundScreen(message: l10n.tripNotFound);
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fundSettlementTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.previousStep,
          onPressed: () {
            try {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/trips/${widget.tripId}');
              }
            } catch (_) {
              Navigator.of(context).maybePop();
            }
          },
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        actions: [
          asyncData.maybeWhen(
            data: (data) => IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: l10n.exportSettlementPdf,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => _exportSettlementPdf(context, data),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.tripNotFound)),
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
          _buildStatusBanner(theme, l10n, data),
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
          _buildExportPdfButton(context, theme, l10n, data),
          const SizedBox(height: 12),
          _buildArchiveButton(context, theme, l10n),
          const SizedBox(height: 12),
          _buildPoweredBy(theme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(ThemeData theme, AppLocalizations l10n, TripKittyData data) {
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
              l10n.settlementStatusMinimalTransfers,
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
        Expanded(
          child: Text(
            l10n.fundWhoPaysWhom.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          l10n.paymentTransfersCount(count),
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

    // Formatierte Zeile laut FEEDBACK_R1 Punkt 9:
    // "bekommt 18,00 € von Anna" oder "zahlt 42,10 € an Anna"
    final String personName;
    final String lineText;
    final isPayout = data.treasurer != null && transfer.fromMember.id == data.treasurer!.id;
    if (isPayout) {
      personName = transfer.toMember.name;
      lineText = l10n.settlementReceivesFrom(transfer.formattedAmount, transfer.fromMember.name);
    } else {
      personName = transfer.fromMember.name;
      lineText = l10n.settlementPaysTo(transfer.formattedAmount, transfer.toMember.name);
    }

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
                personName.isNotEmpty ? personName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: isSettled
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(personName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(
              lineText,
              style: TextStyle(
                color: isSettled ? theme.colorScheme.secondary : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      _expandedIndices.add(index);
                    });
                  },
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(l10n.pay),
                ),
                const SizedBox(width: 4),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
          if (isExpanded)
            _buildExpandedSection(theme, l10n, data, index, transfer, isSettled, isPayout: isPayout),
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
    bool isSettled, {
    required bool isPayout,
  }) {
    final memberIban = transfer.toMember.iban;
    final hasValidIban = memberIban != null &&
        memberIban.isNotEmpty &&
        IbanValidator.isValid(memberIban);

    if (!hasValidIban) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            const Divider(),
            const SizedBox(height: 8),
            _buildMissingPaymentDataBox(theme, l10n, transfer.toMember, index, isSettled, isPayout: isPayout),
            const SizedBox(height: 8),
            _buildMarkSettledRow(theme, l10n, index, isSettled),
          ],
        ),
      );
    }

    final remittance = l10n.settlementRemittance(data.trip.name, transfer.fromMember.name);
    final payload = EpcQrPayload(
      beneficiaryName: transfer.toMember.name,
      iban: memberIban,
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
          _buildTransferDetailsBox(theme, l10n, transfer.toMember.name, memberIban, transfer.formattedAmount, remittance),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(l10n.paidCash),
                  onPressed: () {
                    setState(() {
                      _settledIndices.add(index);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(l10n.adjustIban),
                  onPressed: () => _editMemberPaymentDetails(context, transfer.toMember),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCopyButton(theme, l10n, transfer.toMember.name, memberIban, transfer.formattedAmount, remittance),
          const SizedBox(height: 8),
          _buildShareRow(theme, l10n, transfer, memberIban, remittance),
          const SizedBox(height: 12),
          _buildMarkSettledRow(theme, l10n, index, isSettled),
        ],
      ),
    );
  }

  Widget _buildMissingPaymentDataBox(
    ThemeData theme,
    AppLocalizations l10n,
    KittyMember member,
    int index,
    bool isSettled, {
    required bool isPayout,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.noPaymentDataForMember(member.name),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isPayout)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(l10n.paidCash),
                    onPressed: () {
                      setState(() {
                        _settledIndices.add(index);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.account_balance_outlined),
                    label: Text(l10n.transferMoney),
                    onPressed: () => _editMemberPaymentDetails(context, member),
                  ),
                ),
              ],
            )
          else
            FilledButton.tonalIcon(
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.enterNow),
              onPressed: () => _editMemberPaymentDetails(context, member),
            ),
        ],
      ),
    );
  }

  Future<void> _editMemberPaymentDetails(BuildContext context, KittyMember member) async {
    final ibanController = TextEditingController(text: member.iban ?? '');
    final paypalController = TextEditingController(text: member.paypalLink ?? '');
    final revolutController = TextEditingController(text: member.revolutLink ?? '');
    String? ibanError;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10n.paymentDataForMember(member.name)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ibanController,
                    decoration: InputDecoration(
                      labelText: 'IBAN *',
                      errorText: ibanError,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: paypalController,
                    decoration: const InputDecoration(
                      labelText: 'PayPal.Me Link (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: revolutController,
                    decoration: const InputDecoration(
                      labelText: 'Revolut.Me Link (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  final rawIban = ibanController.text.trim();
                  final cleanIban = rawIban.replaceAll(RegExp(r'\s+'), '').toUpperCase();
                  if (cleanIban.isNotEmpty && !IbanValidator.isValid(cleanIban)) {
                    setDialogState(() {
                      ibanError = l10n.invalidIban;
                    });
                    return;
                  }
                  Navigator.of(ctx).pop();
                  final service = ref.read(kittyServiceProvider);
                  await service.updateMemberPaymentDetails(
                    memberId: member.id,
                    iban: cleanIban.isNotEmpty ? cleanIban : null,
                    paypalLink: paypalController.text.trim().isNotEmpty ? paypalController.text.trim() : null,
                    revolutLink: revolutController.text.trim().isNotEmpty ? revolutController.text.trim() : null,
                  );
                  ref.invalidate(tripKittyDataProvider(widget.tripId));
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatIban(String iban) {
    final clean = iban.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
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
          _detailRow(l10n.fundReceiver, recipient, theme),
          const Divider(height: 12),
          _detailRow(l10n.fundIban, _formatIban(iban), theme, mono: true),
          const Divider(height: 12),
          _detailRow(l10n.fundAmount, amount, theme, mono: true, bold: true),
          const Divider(height: 12),
          _detailRow(l10n.fundRemittance, remittance, theme),
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
      label: Text(l10n.fundCopyIbanData),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        final text = '${l10n.fundReceiver}: $recipient\n${l10n.fundIban}: $iban\n${l10n.fundAmount}: $amount\n${l10n.fundRemittance}: $remittance';
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.fundIbanCopied)),
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
            label: Text(l10n.fundSharePaypal),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final link = transfer.toMember.paypalLink?.trim().isNotEmpty == true
                  ? transfer.toMember.paypalLink!.trim()
                  : 'https://paypal.me/${transfer.toMember.name}/${(transfer.amountInCents / 100).toStringAsFixed(2)}';
              final uri = Uri.parse(link);
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  await Clipboard.setData(ClipboardData(text: link));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.paypalCopied)),
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
            label: Text(l10n.fundShareRevolut),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final revolutUrl = transfer.toMember.revolutLink?.trim().isNotEmpty == true
                  ? transfer.toMember.revolutLink!.trim()
                  : 'https://revolut.me/${transfer.toMember.name}';
              final text = l10n.settlementShareText(
                transfer.fromMember.name,
                transfer.formattedAmount,
                transfer.toMember.name,
                iban,
                remittance,
                revolutUrl,
              );
              try {
                await Share.share(text, subject: l10n.settlementShareSubject(transfer.toMember.name));
              } catch (_) {
                await Clipboard.setData(ClipboardData(text: text));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.paymentDetailsCopied)),
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
      title: Text(isSettled ? l10n.fundSettled : l10n.fundMarkDone),
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
          Expanded(
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 20, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.fundBalancesEqual,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
            l10n.fundSettlementNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportPdfButton(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
  ) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.picture_as_pdf_outlined),
      label: Text(l10n.exportSettlementPdf),
      onPressed: () => _exportSettlementPdf(context, data),
    );
  }

  Future<void> _exportSettlementPdf(BuildContext context, TripKittyData data) async {
    final l10n = AppLocalizations.of(context)!;
    final pdfService = ref.read(pdfExportServiceProvider);
    final bytes = await pdfService.generateSettlementPdf(
      data: data,
    );

    await pdfService.shareOrPrintPdf(
      bytes: bytes,
      filename: l10n.settlementPdfFilename(data.trip.name.replaceAll(' ', '_')),
      subject: l10n.settlementPdfSubject(data.trip.name),
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
          Text(l10n.fundArchiveTrip),
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
