/// Sheet zur Konfiguration der Kategorie-Beteiligung je Person (SC-KAS-04).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../data/kitty_providers.dart';
import '../../domain/models/kitty_models.dart';

/// Sheet zur Verwaltung der Kostenbeteiligung pro Crew-Mitglied.
class ParticipationMatrixSheet extends ConsumerStatefulWidget {
  final int tripId;
  final List<KittyMember> members;

  const ParticipationMatrixSheet({
    super.key,
    required this.tripId,
    required this.members,
  });

  /// Zeigt das Bottom Sheet an.
  static Future<void> show(
    BuildContext context, {
    required int tripId,
    required List<KittyMember> members,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ParticipationMatrixSheet(
        tripId: tripId,
        members: members,
      ),
    );
  }

  @override
  ConsumerState<ParticipationMatrixSheet> createState() =>
      _ParticipationMatrixSheetState();
}

class _ParticipationMatrixSheetState
    extends ConsumerState<ParticipationMatrixSheet> {
  late Map<int, Map<ExpenseCategory, bool>> _participation;
  late Map<int, bool> _skipperFree;
  late Map<int, String?> _skipperScope;

  @override
  void initState() {
    super.initState();
    _participation = {};
    _skipperFree = {};
    _skipperScope = {};

    for (final m in widget.members) {
      _participation[m.id] = Map<ExpenseCategory, bool>.from(m.categoryParticipation);
      _skipperFree[m.id] = m.isSkipperFree;
      _skipperScope[m.id] = m.skipperFreeScope;
    }
  }

  void _applyProfile(int memberId, ParticipationProfile profile) {
    setState(() {
      switch (profile) {
        case ParticipationProfile.all:
          _skipperFree[memberId] = false;
          _skipperScope[memberId] = null;
          _participation[memberId] = {
            for (final c in ExpenseCategory.values) c: true
          };
          break;
        case ParticipationProfile.skipperFreeFull:
          _skipperFree[memberId] = true;
          _skipperScope[memberId] = 'all';
          _participation[memberId] = {
            for (final c in ExpenseCategory.values) c: false
          };
          break;
        case ParticipationProfile.skipperFreePartial:
          _skipperFree[memberId] = true;
          _skipperScope[memberId] = 'exclude_food';
          _participation[memberId] = {
            ExpenseCategory.provisions: true,
            ExpenseCategory.drinks: true,
            ExpenseCategory.restaurant: true,
            ExpenseCategory.other: true,
            ExpenseCategory.charterDeposit: false,
            ExpenseCategory.marinaBerth: false,
            ExpenseCategory.fuel: false,
          };
          break;
        case ParticipationProfile.noAlcohol:
          _skipperFree[memberId] = false;
          _skipperScope[memberId] = null;
          _participation[memberId] = {
            for (final c in ExpenseCategory.values)
              c: c != ExpenseCategory.drinks,
          };
          break;
        case ParticipationProfile.custom:
          break;
      }
    });
  }

  Future<void> _saveAll() async {
    final service = ref.read(kittyServiceProvider);
    for (final m in widget.members) {
      await service.updateMemberParticipation(
        memberId: m.id,
        participation: _participation[m.id] ?? {},
        isSkipperFree: _skipperFree[m.id] ?? false,
        skipperFreeScope: _skipperScope[m.id],
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
      ref.invalidate(tripKittyDataProvider(widget.tripId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fundParticipationTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        actions: [
          TextButton(
            onPressed: _saveAll,
            child: Text(l10n.takeOver),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.members.length,
        itemBuilder: (ctx, idx) {
          final member = widget.members[idx];
          return _buildMemberCard(theme, l10n, member);
        },
      ),
    );
  }

  Widget _buildMemberCard(
    ThemeData theme,
    AppLocalizations l10n,
    KittyMember member,
  ) {
    final memberParts = _participation[member.id] ?? {};
    final isFullFree = _skipperFree[member.id] == true &&
        _skipperScope[member.id] == 'all';
    final isPartialFree = _skipperFree[member.id] == true &&
        _skipperScope[member.id] == 'exclude_food';
    final isNoAlc = memberParts[ExpenseCategory.drinks] == false &&
        !(_skipperFree[member.id] == true);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  member.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProfileChips(theme, l10n, member.id, isFullFree, isPartialFree, isNoAlc),
            const Divider(height: 24),
            _buildCategoryGrid(theme, member.id, memberParts),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileChips(
    ThemeData theme,
    AppLocalizations l10n,
    int memberId,
    bool isFullFree,
    bool isPartialFree,
    bool isNoAlc,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          label: Text(l10n.fundProfileAll),
          onPressed: () => _applyProfile(memberId, ParticipationProfile.all),
        ),
        ActionChip(
          backgroundColor: isFullFree ? theme.colorScheme.secondaryContainer : null,
          label: Text(l10n.fundProfileSkipperFull),
          onPressed: () => _applyProfile(memberId, ParticipationProfile.skipperFreeFull),
        ),
        ActionChip(
          backgroundColor: isPartialFree ? theme.colorScheme.secondaryContainer : null,
          label: Text(l10n.fundProfileSkipperPartial),
          onPressed: () => _applyProfile(memberId, ParticipationProfile.skipperFreePartial),
        ),
        ActionChip(
          backgroundColor: isNoAlc ? theme.colorScheme.secondaryContainer : null,
          label: Text(l10n.fundProfileNoAlcohol),
          onPressed: () => _applyProfile(memberId, ParticipationProfile.noAlcohol),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(
    ThemeData theme,
    int memberId,
    Map<ExpenseCategory, bool> memberParts,
  ) {
    return Column(
      children: ExpenseCategory.values.map((cat) {
        final participating = memberParts[cat] ?? true;
        return CheckboxListTile(
          value: participating,
          title: Text(cat.displayName),
          secondary: Icon(cat.icon, size: 20),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            setState(() {
              _participation[memberId]![cat] = val ?? false;
            });
          },
        );
      }).toList(),
    );
  }
}
