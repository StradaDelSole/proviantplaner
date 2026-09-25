/// Hauptbildschirm für die Bordkasse (SC-KAS-01).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/trip_bottom_bar.dart';
import '../data/kitty_providers.dart';
import '../data/kitty_service.dart';
import '../domain/models/kitty_models.dart';
import 'widgets/expense_sheet.dart';
import 'widgets/payment_sheet.dart';
import 'widgets/participation_matrix_sheet.dart';

/// Übersichtsbildschirm Bordkasse (SC-KAS-01).
class KittyScreen extends ConsumerWidget {
  final int tripId;

  const KittyScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(tripKittyDataProvider(tripId));
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.kittyTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.kittyParticipationTitle,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () {
              final data = asyncData.valueOrNull;
              if (data != null) {
                ParticipationMatrixSheet.show(
                  context,
                  tripId: tripId,
                  members: data.members,
                );
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onSelected: (val) => _handleMenuAction(context, ref, val, asyncData.valueOrNull),
            itemBuilder: (ctx) => [
              if (asyncData.valueOrNull?.model == KittyModel.sharedKitty)
                PopupMenuItem(
                  value: 'deposit',
                  child: Text(l10n.kittyAddDeposit),
                ),
              PopupMenuItem(
                value: 'settlement',
                child: Text(l10n.kittySettleTrip),
              ),
            ],
          ),
        ],
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Fehler: $err')),
        data: (data) => _buildBody(context, ref, theme, l10n, data),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final data = asyncData.valueOrNull;
          if (data != null) {
            ExpenseSheet.show(
              context,
              tripId: tripId,
              kittyModel: data.model,
              members: data.members,
            );
          }
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.kittyAddExpense),
      ),
      bottomNavigationBar: TripBottomBar(
        tripId: tripId,
        currentIndex: 2,
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
      PaymentSheet.show(context, tripId: tripId, members: data.members);
    } else if (action == 'settlement') {
      context.push('/trips/$tripId/kitty/settlement');
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
          _buildSubtitleRow(theme, data),
          const SizedBox(height: 12),
          _buildBentoCard(context, ref, theme, l10n, data),
          const SizedBox(height: 12),
          if (_hasSkipperFree(data.members))
            _buildSkipperSnippet(theme, data.members),
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

  Widget _buildSubtitleRow(ThemeData theme, TripKittyData data) {
    return Text(
      'Törn ${data.trip.name} · ${data.members.length} Personen · ${data.trip.daysCount} Tage',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  bool _hasSkipperFree(List<KittyMember> members) {
    return members.any((m) => m.isSkipperFree);
  }

  Widget _buildSkipperSnippet(ThemeData theme, List<KittyMember> members) {
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
                    'Crew übernimmt Bordkasse',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Chip(
              backgroundColor: theme.colorScheme.secondaryContainer,
              label: Text(
                'Skipper frei',
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
        InkWell(
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
                Text(
                  isShared ? l10n.kittyModelShared : l10n.kittyModelIndividual,
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 16, color: theme.colorScheme.outline),
              ],
            ),
          ),
        ),
        Text(
          'EUR (€) TABULAR',
          style: theme.textTheme.labelSmall?.copyWith(
            fontFamily: 'JetBrains Mono',
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
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

    final balanceFormatted = _formatCents(balanceCents);
    final depositsFormatted = _formatCents(depositsCents);
    final expensesFormatted = _formatCents(expensesCents);

    final ratio = depositsCents > 0
        ? (expensesCents / depositsCents).clamp(0.0, 1.0)
        : 0.0;
    final percent = (ratio * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.kittyCurrentBalance.toUpperCase(),
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
            Text('Auslastung: $percent% verbraucht', style: theme.textTheme.bodySmall),
            Text('Rest: $balanceFormatted', style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'JetBrains Mono')),
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
                  Text(l10n.kittyTotalDeposits, style: theme.textTheme.bodySmall),
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
                  Text(l10n.kittyTotalExpenses, style: theme.textTheme.bodySmall),
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
    final totalFormatted = _formatCents(totalExpensesCents);
    final openCount = data.transfers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.kittyTotalExpensesLabel.toUpperCase(),
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
          l10n.kittyOpenTransfers(openCount),
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
          title: Text(l10n.kittySwitchModel),
          content: Text(l10n.kittySwitchModelBlocked),
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
        title: Text(l10n.kittySwitchModel),
        content: Text(
          'Möchtest du das Modell zu "${newModel == KittyModel.sharedKitty ? l10n.kittyModelShared : l10n.kittyModelIndividual}" wechseln?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final service = ref.read(kittyServiceProvider);
              await service.switchKittyModel(tripId, newModel);
              ref.invalidate(tripKittyDataProvider(tripId));
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
          label: Text('${l10n.kittyExpensesSegment} (${data.expenses.length})'),
        ),
        ButtonSegment(
          value: KittyViewSegment.people,
          label: Text(l10n.kittyPeopleSegment),
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
              Text(l10n.kittyNoExpenses, style: theme.textTheme.bodyMedium),
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

  Widget _buildExpenseTile(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    TripKittyData data,
    KittyExpense exp,
  ) {
    final payerName = exp.isPaidFromKitty
        ? l10n.kittyPaidFromKitty
        : l10n.kittyPaidBy(data.members.firstWhere((m) => m.id == exp.paidByMemberId, orElse: () => const KittyMember(id: 0, name: 'Crew', categoryParticipation: {})).name);

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
        final service = ref.read(kittyServiceProvider);
        await service.deleteExpense(exp.id);
        ref.invalidate(tripKittyDataProvider(tripId));
      },
      child: ListTile(
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
        subtitle: Text(
          '${exp.category.displayName} • $payerName',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Text(
          '-${_formatCents(exp.amountInCents)}',
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
              ParticipationMatrixSheet.show(context, tripId: tripId, members: data.members);
            },
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                b.member.name.isNotEmpty ? b.member.name[0].toUpperCase() : '?',
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
            title: Text(b.member.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(
              b.member.isSkipperFree
                  ? 'Skipper frei'
                  : 'beteiligt an ${b.member.categoryParticipation.values.where((v) => v).length} von 7 Kategorien',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            trailing: Text(
              b.formattedNetBalance,
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

  String _formatCents(int cents) {
    final isNegative = cents < 0;
    final abs = cents.abs();
    final euros = abs ~/ 100;
    final c = abs % 100;
    final prefix = isNegative ? '-' : '';
    return '$prefix$euros,${c.toString().padLeft(2, '0')} €';
  }
}
