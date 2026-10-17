/// Hauptbildschirm für die Bordkasse (SC-KAS-01, FB1-D).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:proviantplaner/core/routing/not_found_screen.dart';
import '../data/kitty_providers.dart';
import '../data/kitty_service.dart';
import '../domain/models/kitty_models.dart';
import 'widgets/expense_sheet.dart';
import 'widgets/payment_sheet.dart';
import 'widgets/participation_matrix_sheet.dart';

/// Übersichtsbildschirm Bordkasse (SC-KAS-01, FEEDBACK_R1 Punkt 9).
class KittyScreen extends ConsumerStatefulWidget {
  final int tripId;

  const KittyScreen({super.key, required this.tripId});

  @override
  ConsumerState<KittyScreen> createState() => _KittyScreenState();
}

class _KittyScreenState extends ConsumerState<KittyScreen> {
  bool _promptedTreasurer = false;

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(tripKittyDataProvider(widget.tripId));
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (asyncData.hasError) {
      if (asyncData.error is LedgerValidationException) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.ledgerDataInvalidTitle),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: l10n.previousStep,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/trips/${widget.tripId}');
                }
              },
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
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.ledgerDataInvalidTitle,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.ledgerDataInvalidMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/trips/${widget.tripId}');
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

      if (asyncData.error is TripNotFoundException) {
        return NotFoundScreen(message: l10n.tripNotFound);
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.technicalErrorTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.previousStep,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/trips/${widget.tripId}');
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.technicalErrorTitle,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.technicalErrorMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.invalidate(tripKittyDataProvider(widget.tripId));
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/trips/${widget.tripId}');
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: Text(l10n.backToHome),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Kassenwart beim ersten Öffnen abfragen (FEEDBACK_R1 Punkt 9)
    final data = asyncData.valueOrNull;
    if (data != null &&
        data.trip.treasurerMemberId == null &&
        !_promptedTreasurer &&
        data.members.isNotEmpty) {
      _promptedTreasurer = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showTreasurerDialog(context, ref, data);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.previousStep,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/trips/${widget.tripId}');
            }
          },
        ),
        title: Text(l10n.fundTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.fundParticipationTitle,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () {
              if (data != null) {
                ParticipationMatrixSheet.show(
                  context,
                  tripId: widget.tripId,
                  members: data.members,
                );
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onSelected: (val) => _handleMenuAction(context, ref, val, data),
            itemBuilder: (ctx) => [
              if (data?.model == KittyModel.sharedKitty) ...[
                PopupMenuItem(
                  value: 'deposit',
                  child: Text(l10n.fundAddDeposit),
                ),
                PopupMenuItem(
                  value: 'treasurer',
                  child: Text(l10n.setTreasurer),
                ),
              ],
              PopupMenuItem(
                value: 'settlement',
                child: Text(l10n.fundSettleTrip),
              ),
            ],
          ),
        ],
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('${l10n.genericError}: $err')),
        data: (d) => _buildBody(context, ref, theme, l10n, d),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (data != null) {
            ExpenseSheet.show(
              context,
              tripId: widget.tripId,
              kittyModel: data.model,
              members: data.members,
              currency: data.trip.currency,
            );
          }
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.fundAddExpense),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    TripKittyData? data,
  ) {
    if (data == null) return;
    if (action == 'deposit') {
      PaymentSheet.show(
        context,
        tripId: widget.tripId,
        members: data.members,
        currency: data.trip.currency,
      );
    } else if (action == 'treasurer') {
      _showTreasurerDialog(context, ref, data);
    } else if (action == 'settlement') {
      context.push('/trips/${widget.tripId}/kitty/settlement');
    }
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
  ) {
    final activeSegment = ref.watch(kittyViewSegmentProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSubtitleRow(theme, l10n, data),
          const SizedBox(height: 8),
          if (data.model == KittyModel.sharedKitty) ...[
            _buildTreasurerCard(context, ref, theme, l10n, data),
            const SizedBox(height: 12),
          ],
          if (_shouldShowNachschussHint(data)) ...[
            _buildNachschussBanner(context, theme, l10n, data),
            const SizedBox(height: 12),
          ],
          _buildBentoCard(context, ref, theme, l10n, data),
          const SizedBox(height: 12),
          if (_hasSkipperFree(data.members))
            _buildSkipperSnippet(theme, l10n, data.members),
          const SizedBox(height: 12),
          _buildSegmentedSwitch(ref, theme, l10n, data, activeSegment),
          const SizedBox(height: 16),
          if (activeSegment == KittyViewSegment.expenses)
            _buildExpenseList(context, ref, theme, l10n, data)
          else
            _buildPeopleList(context, theme, l10n, data),
        ],
      ),
    );
  }

  Widget _buildSubtitleRow(ThemeData theme, AppLocalizations l10n, TripKittyData data) {
    return Text(
      l10n.tripSubtitleInfo(data.trip.name, data.members.length, data.trip.daysCount),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  bool _shouldShowNachschussHint(TripKittyData data) {
    if (data.model != KittyModel.sharedKitty) return false;
    // Zeigt Hinweis, wenn Kassenstand unter 50 € liegt
    if (data.deposits.isEmpty) return false;
    return data.cashBalanceCents < 5000;
  }

  Widget _buildNachschussBanner(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.35),
        border: Border.all(color: theme.colorScheme.tertiary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.fundLowNachschussPrompt,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () {
              PaymentSheet.show(
                context,
                tripId: widget.tripId,
                members: data.members,
                currency: data.trip.currency,
                initialAmountInCents: 5000,
              );
            },
            child: Text(l10n.takeOver),
          ),
        ],
      ),
    );
  }

  Widget _buildTreasurerCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
  ) {
    final treasurerName = data.treasurer?.name ?? l10n.noneSelected;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showTreasurerDialog(context, ref, data),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '${l10n.treasurer}: ',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            Expanded(
              child: Text(
                treasurerName,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Icon(Icons.edit_outlined, size: 16, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }

  void _showTreasurerDialog(BuildContext context, WidgetRef ref, TripKittyData data) {
    final l10n = AppLocalizations.of(context)!;
    int? selectedId = data.treasurer?.id ?? data.members.firstOrNull?.id;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.whoManagesFund),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.treasurerExplainer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ...data.members.map((m) {
                return RadioListTile<int>(
                  value: m.id,
                  groupValue: selectedId,
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Text(m.name),
                      if (m.isSkipperFree) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(l10n.skipper, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ],
                  ),
                  onChanged: (val) => setDialogState(() => selectedId = val),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: selectedId != null
                  ? () async {
                      Navigator.of(ctx).pop();
                      final service = ref.read(kittyServiceProvider);
                      await service.setTreasurer(widget.tripId, selectedId);
                      ref.invalidate(tripKittyDataProvider(widget.tripId));
                    }
                  : null,
              child: Text(l10n.setAsTreasurer),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasSkipperFree(List<KittyMember> members) {
    return members.any((m) => m.isSkipperFree);
  }

  Widget _buildSkipperSnippet(ThemeData theme, AppLocalizations l10n, List<KittyMember> members) {
    final skipper = members.firstWhere((m) => m.isSkipperFree);
    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                skipper.name.isNotEmpty ? skipper.name[0].toUpperCase() : 'S',
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skipper.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    l10n.crewTakesOverFund,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Chip(
              backgroundColor: theme.colorScheme.secondaryContainer,
              label: Text(
                l10n.skipperFree,
                style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
  ) {
    final isShared = data.model == KittyModel.sharedKitty;
    return Card(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModelHeader(context, ref, theme, l10n, data, isShared),
            const SizedBox(height: 12),
            if (isShared)
              _buildSharedKittyBento(theme, l10n, data)
            else
              _buildIndividualBento(theme, l10n, data),
          ],
        ),
      ),
    );
  }

  Widget _buildModelHeader(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
    bool isShared,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showSwitchModelDialog(context, ref, data),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isShared ? Icons.account_balance : Icons.groups,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      isShared ? l10n.fundModelShared : l10n.fundModelIndividual,
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 16, color: theme.colorScheme.outline),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _currencyHeaderLabel(data.trip.currency),
          style: theme.textTheme.labelSmall?.copyWith(
            fontFamily: 'JetBrains Mono',
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  String _currencyHeaderLabel(String currency) {
    if (currency == 'EUR') return 'EUR (€) TABULAR';
    return '$currency TABULAR';
  }

  Widget _buildSharedKittyBento(
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
  ) {
    final shared = data.sharedResult;
    final balanceCents = shared?.currentBalanceInCents ?? 0;
    final depositsCents = shared?.totalDepositsInCents ?? 0;
    final expensesCents = shared?.totalExpensesInCents ?? 0;
    final kittyPaidCents = shared?.kittyPaidExpensesInCents ?? expensesCents;
    final currency = data.trip.currency;

    final balanceFormatted = _formatCents(balanceCents, currency);
    final depositsFormatted = _formatCents(depositsCents, currency);
    final expensesFormatted = _formatCents(expensesCents, currency);

    final ratio = depositsCents > 0
        ? (kittyPaidCents / depositsCents).clamp(0.0, 1.0)
        : 0.0;
    final percent = (ratio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.fundCurrentBalance.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          balanceFormatted,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.bold,
            color: balanceCents < 0 ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                l10n.fundUsagePercent(percent),
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.fundRemaining(balanceFormatted),
                style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'JetBrains Mono'),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.fundTotalDeposits, style: theme.textTheme.bodySmall),
                  Text(depositsFormatted, style: theme.textTheme.titleSmall?.copyWith(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(width: 1, height: 36, color: theme.colorScheme.outlineVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.fundTotalExpenses, style: theme.textTheme.bodySmall),
                  Text(expensesFormatted, style: theme.textTheme.titleSmall?.copyWith(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIndividualBento(
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
  ) {
    final ind = data.individualResult;
    final totalExpensesCents = ind?.totalExpensesInCents ?? 0;
    final totalFormatted = _formatCents(totalExpensesCents, data.trip.currency);
    final openCount = data.transfers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.fundTotalExpensesLabel.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          totalFormatted,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.fundOpenTransfers(openCount),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  void _showSwitchModelDialog(BuildContext context, WidgetRef ref, TripKittyData data) {
    final l10n = AppLocalizations.of(context)!;
    if (data.expenses.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.fundSwitchModel),
          content: Text(l10n.fundSwitchModelBlocked),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final newModel = data.model == KittyModel.sharedKitty
        ? KittyModel.individualSettlement
        : KittyModel.sharedKitty;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.fundSwitchModel),
        content: Text(
          l10n.fundSwitchModelConfirm(newModel == KittyModel.sharedKitty ? l10n.fundModelShared : l10n.fundModelIndividual),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final service = ref.read(kittyServiceProvider);
              await service.switchKittyModel(widget.tripId, newModel);
              ref.invalidate(tripKittyDataProvider(widget.tripId));
            },
            child: Text(l10n.takeOver),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedSwitch(
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
    KittyViewSegment activeSegment,
  ) {
    return SegmentedButton<KittyViewSegment>(
      segments: [
        ButtonSegment(
          value: KittyViewSegment.expenses,
          label: Text('${l10n.fundExpensesSegment} (${data.expenses.length})'),
        ),
        ButtonSegment(
          value: KittyViewSegment.people,
          label: Text(l10n.fundPeopleSegment),
        ),
      ],
      selected: {activeSegment},
      onSelectionChanged: (set) {
        ref.read(kittyViewSegmentProvider.notifier).state = set.first;
      },
    );
  }

  Widget _buildExpenseList(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
  ) {
    if (data.expenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text(l10n.fundNoExpenses, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    final sortedExpenses = List<KittyExpense>.from(data.expenses)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Card(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedExpenses.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, idx) {
          final exp = sortedExpenses[idx];
          return _buildExpenseTile(ctx, ref, theme, l10n, data, exp);
        },
      ),
    );
  }

  Future<void> _deleteExpenseWithUndo(
    BuildContext context,
    WidgetRef ref,
    TripKittyData data,
    KittyExpense exp,
  ) async {
    final service = ref.read(kittyServiceProvider);
    await service.deleteExpense(exp.id);
    ref.invalidate(tripKittyDataProvider(widget.tripId));

    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(l10n.fundExpenseDeletedTitle(exp.title)),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () async {
            await service.restoreExpense(exp);
            ref.invalidate(tripKittyDataProvider(widget.tripId));
          },
        ),
      ),
    );
  }

  Widget _buildExpenseTile(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
    KittyExpense exp,
  ) {
    final payerName = exp.isPaidFromKitty
        ? l10n.fundPaidFromFund
        : l10n.fundPaidBy(data.members.firstWhere((m) => m.id == exp.paidByMemberId, orElse: () => const KittyMember(id: 0, name: 'Crew', categoryParticipation: {})).name);

    return Dismissible(
      key: Key('expense_${exp.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await _deleteExpenseWithUndo(context, ref, data, exp);
      },
      child: ListTile(
        onTap: () async {
          final res = await ExpenseSheet.show(
            context,
            tripId: widget.tripId,
            kittyModel: data.model,
            members: data.members,
            currency: data.trip.currency,
            expenseToEdit: exp,
          );
          if (res == 'delete' && context.mounted) {
            await _deleteExpenseWithUndo(context, ref, data, exp);
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Icon(exp.category.icon, size: 20, color: theme.colorScheme.primary),
        ),
        title: Text(exp.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                '${exp.category.localizedName(l10n)} • $payerName',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (exp.receipts.isNotEmpty) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.receipt_long_outlined,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              if (exp.receipts.length > 1) ...[
                const SizedBox(width: 2),
                Text(
                  '${exp.receipts.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ],
        ),
        trailing: Text(
          '-${_formatCents(exp.amountInCents, exp.currency)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }


  Widget _buildPeopleList(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
  ) {
    final balances = data.balances;
    return Card(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: balances.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, idx) {
          final b = balances[idx];
          return ListTile(
            onTap: () {
              ParticipationMatrixSheet.show(context, tripId: widget.tripId, members: data.members);
            },
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                b.member.name.isNotEmpty ? b.member.name[0].toUpperCase() : '?',
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
            title: Row(
              children: [
                Text(b.member.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                if (b.isTreasurer) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(l10n.treasurer, style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ],
            ),
            subtitle: Text(
              b.member.isSkipperFree
                  ? l10n.skipperFree
                  : l10n.participatingInCategories(b.member.categoryParticipation.values.where((v) => v).length, 7),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            trailing: Text(
              b.formatNetBalance(data.trip.currency),
              style: theme.textTheme.titleSmall?.copyWith(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.bold,
                color: b.netBalanceInCents > 0
                    ? theme.colorScheme.secondary
                    : (b.netBalanceInCents < 0 ? theme.colorScheme.error : theme.colorScheme.onSurface),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatCents(int cents, [String currency = 'EUR']) {
    return formatMoneyCents(cents, currency);
  }
}
