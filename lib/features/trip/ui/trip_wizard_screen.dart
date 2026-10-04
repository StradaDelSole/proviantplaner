/// Einzelschirm mit drei aufklappenden Abschnitten zum Anlegen eines Törns (UX-A, UX-Konzept 2.2).
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import '../data/trip_provider.dart';
import 'widgets/crew_member_dialog.dart';

class TripWizardScreen extends ConsumerStatefulWidget {
  const TripWizardScreen({super.key});

  @override
  ConsumerState<TripWizardScreen> createState() => _TripWizardScreenState();
}

class _TripWizardScreenState extends ConsumerState<TripWizardScreen> {
  // Sektion 1: Törn
  final _nameController = TextEditingController(text: 'Törn Kroatien');
  late final TextEditingController _daysController;
  DateTime _startDate = DateTime.now();
  int _daysCount = 7;
  bool _isCharter = true;

  // Sektion 2: Crew (ohne Zahlungsdaten)
  final List<CrewMemberInput> _crewMembers = [
    const CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
    const CrewMemberInput(id: '2', name: 'Co-Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
    const CrewMemberInput(id: '3', name: 'Gast 1', isAdult: true, isVegetarian: false, noAlcohol: false),
    const CrewMemberInput(id: '4', name: 'Gast 2', isAdult: true, isVegetarian: true, noAlcohol: false),
    const CrewMemberInput(id: '5', name: 'Gast 3', isAdult: true, isVegetarian: false, noAlcohol: true),
  ];

  // Sektion 3: Essen an Bord
  CrewAppetite _crewAppetite = CrewAppetite.normal;
  bool _eatOut = false;
  int _restaurantDinners = 2;
  int _restaurantLunches = 1;
  double _fridgeCapacity = 100.0;
  bool _hasNoFridge = false;
  bool _hasFreezer = false;
  double _freezerCapacity = 20.0;
  double _waterTankLiters = 0.0;
  bool _isWaterTankDrinkable = false;
  bool _crewReserve = false;

  late final TextEditingController _fridgeCapacityController;
  late final TextEditingController _freezerCapacityController;
  late final TextEditingController _waterTankController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _daysController = TextEditingController(text: _daysCount.toString());
    _fridgeCapacityController = TextEditingController(text: _fridgeCapacity.round().toString());
    _freezerCapacityController = TextEditingController(text: _freezerCapacity.round().toString());
    _waterTankController = TextEditingController(text: _waterTankLiters.round().toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _daysController.dispose();
    _fridgeCapacityController.dispose();
    _freezerCapacityController.dispose();
    _waterTankController.dispose();
    super.dispose();
  }

  void _addPerson() async {
    final result = await showDialog<CrewMemberInput>(
      context: context,
      builder: (_) => const CrewMemberDialog(),
    );
    if (result != null) {
      setState(() => _crewMembers.add(result));
    }
  }

  void _editPerson(int index) async {
    final result = await showDialog<CrewMemberInput>(
      context: context,
      builder: (_) => CrewMemberDialog(initialMember: _crewMembers[index]),
    );
    if (result != null) {
      setState(() => _crewMembers[index] = result);
    }
  }

  void _removePerson(int index) {
    setState(() => _crewMembers.removeAt(index));
  }

  void _showDurationWheelPicker() {
    int selected = _daysCount;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            height: 280,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.selectTripDurationTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _daysCount = selected;
                          _daysController.text = selected.toString();
                          _restaurantDinners = _restaurantDinners.clamp(0, _daysCount);
                          _restaurantLunches = _restaurantLunches.clamp(0, _daysCount);
                        });
                        Navigator.of(ctx).pop();
                      },
                      child: Text(AppLocalizations.of(context)!.done),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: (_daysCount - 1).clamp(0, 179)),
                    itemExtent: 40.0,
                    onSelectedItemChanged: (index) {
                      selected = index + 1;
                    },
                    children: List.generate(
                      180,
                      (i) => Center(
                        child: Text(
                          '${i + 1} ${AppLocalizations.of(context)!.daysCount}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitTrip() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final tripService = ref.read(tripServiceProvider);
      final tripId = await tripService.createTripWithCrew(
        name: _nameController.text.trim(),
        startDate: _startDate,
        daysCount: _daysCount,
        isCharter: _isCharter,
        boatType: 'monohull',
        climate: 'warm',
        region: 'warm',
        fridgeCapacityLiters: _hasNoFridge ? 0.0 : _fridgeCapacity,
        hasFreezer: _hasFreezer,
        freezerCapacityLiters: _hasFreezer ? _freezerCapacity : null,
        waterTankLiters: _waterTankLiters > 0 ? _waterTankLiters : null,
        isWaterTankDrinkable: _isWaterTankDrinkable,
        crewAppetite: _crewAppetite,
        crewReserve: _crewReserve,
        crewDrinking: CrewDrinking.normal,
        crewMembers: _crewMembers,
        restaurantDinnersCount: _eatOut ? _restaurantDinners : 0,
        restaurantLunchesCount: _eatOut ? _restaurantLunches : 0,
      );

      ref.read(activeTripIdProvider.notifier).state = tripId;
      ref.invalidate(allTripsProvider);
      ref.invalidate(activeTripProvider);

      if (mounted) {
        // Direkt zur Törn-Übersicht führen (UX-A / UX-Konzept 2.2)
        context.go('/trips/$tripId');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tripWizardTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_crewMembers.length} ${l10n.persons.toUpperCase()}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSection1Trip(l10n, theme),
                        const SizedBox(height: 16),
                        _buildSection2Crew(l10n, theme),
                        const SizedBox(height: 16),
                        _buildSection3Food(l10n, theme),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom Action Bar mit direktem "Törn anlegen"
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _submitTrip,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(l10n.createTrip),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection1Trip(AppLocalizations l10n, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text('1. Törn', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.tripName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.startDate),
              subtitle: Text('${_startDate.day}.${_startDate.month}.${_startDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.daysCount,
                border: const OutlineInputBorder(),
                helperText: 'Törnlänge zwischen 1 und 180 Tagen',
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val.trim());
                if (parsed != null && parsed >= 1 && parsed <= 180) {
                  setState(() {
                    _daysCount = parsed;
                    _restaurantDinners = _restaurantDinners.clamp(0, _daysCount);
                    _restaurantLunches = _restaurantLunches.clamp(0, _daysCount);
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ActionChip(
                  label: Text(l10n.durationOneWeek),
                  onPressed: () {
                    setState(() {
                      _daysCount = 7;
                      _daysController.text = '7';
                      _restaurantDinners = _restaurantDinners.clamp(0, _daysCount);
                      _restaurantLunches = _restaurantLunches.clamp(0, _daysCount);
                    });
                  },
                ),
                ActionChip(
                  label: Text(l10n.durationTwoWeeks),
                  onPressed: () {
                    setState(() {
                      _daysCount = 14;
                      _daysController.text = '14';
                      _restaurantDinners = _restaurantDinners.clamp(0, _daysCount);
                      _restaurantLunches = _restaurantLunches.clamp(0, _daysCount);
                    });
                  },
                ),
                ActionChip(
                  label: Text(l10n.durationOneMonth),
                  onPressed: () {
                    setState(() {
                      _daysCount = 30;
                      _daysController.text = '30';
                      _restaurantDinners = _restaurantDinners.clamp(0, _daysCount);
                      _restaurantLunches = _restaurantLunches.clamp(0, _daysCount);
                    });
                  },
                ),
                ActionChip(
                  label: Text(l10n.durationThreeMonths),
                  onPressed: () {
                    setState(() {
                      _daysCount = 90;
                      _daysController.text = '90';
                      _restaurantDinners = _restaurantDinners.clamp(0, _daysCount);
                      _restaurantLunches = _restaurantLunches.clamp(0, _daysCount);
                    });
                  },
                ),
                ActionChip(
                  label: Text(l10n.durationSixMonths),
                  onPressed: () {
                    setState(() {
                      _daysCount = 180;
                      _daysController.text = '180';
                      _restaurantDinners = _restaurantDinners.clamp(0, _daysCount);
                      _restaurantLunches = _restaurantLunches.clamp(0, _daysCount);
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.tune, size: 16),
                  label: Text(l10n.wheelPickerButton),
                  onPressed: _showDurationWheelPicker,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l10n.isCharter)),
                ButtonSegment(value: false, label: Text(l10n.isOwnBoat)),
              ],
              selected: {_isCharter},
              onSelectionChanged: (val) => setState(() => _isCharter = val.first),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection2Crew(AppLocalizations l10n, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text('2. Crew (${_crewMembers.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            ..._crewMembers.asMap().entries.map((entry) {
              final idx = entry.key;
              final m = entry.value;
              final initials = m.name.isNotEmpty ? m.name.substring(0, 1).toUpperCase() : '?';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        child: Text(initials, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                Chip(
                                  label: Text(m.isAdult ? l10n.isAdult : l10n.isChild),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                                if (m.isVegetarian)
                                  Chip(
                                    label: Text(l10n.isVegetarian),
                                    avatar: const Icon(Icons.eco, size: 14),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: theme.colorScheme.secondaryContainer,
                                  ),
                                if (m.noAlcohol && m.isAdult)
                                  Chip(
                                    label: Text(l10n.noAlcohol),
                                    avatar: const Icon(Icons.no_drinks, size: 14),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: () => _editPerson(idx),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: () => _removePerson(idx),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addPerson,
              icon: const Icon(Icons.person_add),
              label: Text(l10n.addCrewMember),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection3Food(AppLocalizations l10n, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text('3. Essen an Bord', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            // Appetit
            Text(l10n.crewAppetiteQuestion, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.appetiteLight),
                  selected: _crewAppetite == CrewAppetite.light,
                  onSelected: (_) => setState(() => _crewAppetite = CrewAppetite.light),
                ),
                ChoiceChip(
                  label: Text(l10n.appetiteNormal),
                  selected: _crewAppetite == CrewAppetite.normal,
                  onSelected: (_) => setState(() => _crewAppetite = CrewAppetite.normal),
                ),
                ChoiceChip(
                  label: Text(l10n.appetiteHearty),
                  selected: _crewAppetite == CrewAppetite.hearty,
                  onSelected: (_) => setState(() => _crewAppetite = CrewAppetite.hearty),
                ),
                ChoiceChip(
                  label: Text(l10n.appetiteHungrySailors),
                  selected: _crewAppetite == CrewAppetite.hungrySailors,
                  onSelected: (_) => setState(() => _crewAppetite = CrewAppetite.hungrySailors),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Auswärts essen
            Text(l10n.eatOutQuestion, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Nein')),
                ButtonSegment(value: true, label: Text('Ja')),
              ],
              selected: {_eatOut},
              onSelectionChanged: (val) => setState(() => _eatOut = val.first),
            ),
            if (_eatOut) ...[
              const SizedBox(height: 12),
              // Zähler 1: Abendessen im Restaurant
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.dinnerInRestaurant}: $_restaurantDinners von $_daysCount',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _restaurantDinners > 0
                                ? () => setState(() => _restaurantDinners--)
                                : null,
                          ),
                          Text('$_restaurantDinners', style: theme.textTheme.titleMedium),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _restaurantDinners < _daysCount
                                ? () => setState(() => _restaurantDinners++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Zähler 2: Mittagessen im Restaurant
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.lunchInRestaurant}: $_restaurantLunches von $_daysCount',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _restaurantLunches > 0
                                ? () => setState(() => _restaurantLunches--)
                                : null,
                          ),
                          Text('$_restaurantLunches', style: theme.textTheme.titleMedium),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _restaurantLunches < _daysCount
                                ? () => setState(() => _restaurantLunches++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Kühlschrank
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.noFridgeSwitch),
              value: _hasNoFridge,
              onChanged: (val) {
                setState(() {
                  _hasNoFridge = val;
                  if (val) {
                    _fridgeCapacity = 0.0;
                    _fridgeCapacityController.text = '0';
                  } else if (_fridgeCapacity == 0) {
                    _fridgeCapacity = 100.0;
                    _fridgeCapacityController.text = '100';
                  }
                });
              },
            ),
            if (!_hasNoFridge) ...[
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.fridgeCapacity}: ${_fridgeCapacity.round()} l',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _fridgeCapacity >= 10
                                ? () => setState(() {
                                      _fridgeCapacity -= 10;
                                      _fridgeCapacityController.text = _fridgeCapacity.round().toString();
                                    })
                                : null,
                          ),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _fridgeCapacityController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                              onChanged: (val) {
                                final parsed = double.tryParse(val.trim());
                                if (parsed != null && parsed >= 0) {
                                  setState(() => _fridgeCapacity = parsed);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setState(() {
                              _fridgeCapacity += 10;
                              _fridgeCapacityController.text = _fridgeCapacity.round().toString();
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Tiefkühlfach
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.freezerAvailable),
              value: _hasFreezer,
              onChanged: (val) => setState(() => _hasFreezer = val),
            ),
            if (_hasFreezer) ...[
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.freezerCapacityLiters,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _freezerCapacity >= 5
                                ? () => setState(() {
                                      _freezerCapacity -= 5;
                                      _freezerCapacityController.text = _freezerCapacity.round().toString();
                                    })
                                : null,
                          ),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _freezerCapacityController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                              onChanged: (val) {
                                final parsed = double.tryParse(val.trim());
                                if (parsed != null && parsed >= 0) {
                                  setState(() => _freezerCapacity = parsed);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setState(() {
                              _freezerCapacity += 5;
                              _freezerCapacityController.text = _freezerCapacity.round().toString();
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Wassertank an Bord
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.waterTankLiters,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _waterTankLiters >= 50
                              ? () => setState(() {
                                    _waterTankLiters -= 50;
                                    _waterTankController.text = _waterTankLiters.round().toString();
                                  })
                              : null,
                        ),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: _waterTankController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              final parsed = double.tryParse(val.trim());
                              if (parsed != null && parsed >= 0) {
                                setState(() => _waterTankLiters = parsed);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() {
                            _waterTankLiters += 50;
                            _waterTankController.text = _waterTankLiters.round().toString();
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.waterTankDrinkable),
              subtitle: Text(l10n.waterTankDrinkableSubtitle),
              value: _isWaterTankDrinkable,
              onChanged: (val) => setState(() => _isWaterTankDrinkable = val),
            ),
            const SizedBox(height: 16),
            // Reserve Ankertage
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SwitchListTile(
                title: Text(l10n.weatherReserve),
                subtitle: Text(l10n.weatherReserveDescription),
                value: _crewReserve,
                onChanged: (val) => setState(() => _crewReserve = val),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
