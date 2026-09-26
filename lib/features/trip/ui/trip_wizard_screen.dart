/// Mehrschritt-Assistent zum Anlegen eines Törns (Slice S3, Mockup 01).
library;

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
  int _currentStep = 0;

  // Step 1: Basisdaten
  final _nameController = TextEditingController(text: 'Törn Kroatien');
  late final TextEditingController _daysController;
  DateTime _startDate = DateTime.now();
  int _daysCount = 7;

  // Step 2: Boot & Bedingungen
  bool _isCharter = true;
  String _boatType = 'monohull';
  String _climate = 'warm';
  double _fridgeCapacity = 100.0;
  bool _hasNoFridge = false;

  // Step 3: Crew & Verpflegungs-Profil
  final List<CrewMemberInput> _crewMembers = [
    const CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
    const CrewMemberInput(id: '2', name: 'Co-Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
    const CrewMemberInput(id: '3', name: 'Gast 1', isAdult: true, isVegetarian: false, noAlcohol: false),
    const CrewMemberInput(id: '4', name: 'Gast 2', isAdult: true, isVegetarian: true, noAlcohol: false),
    const CrewMemberInput(id: '5', name: 'Gast 3', isAdult: true, isVegetarian: false, noAlcohol: true),
  ];

  CrewAppetite _crewAppetite = CrewAppetite.normal;
  CrewDrinking _crewDrinking = CrewDrinking.normal;
  bool _crewReserve = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _daysController = TextEditingController(text: _daysCount.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _daysController.dispose();
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
        boatType: _boatType,
        climate: _climate,
        region: _climate,
        fridgeCapacityLiters: _hasNoFridge ? 0.0 : _fridgeCapacity,
        crewAppetite: _crewAppetite,
        crewReserve: _crewReserve,
        crewDrinking: _crewDrinking,
        crewMembers: _crewMembers,
      );

      ref.read(activeTripIdProvider.notifier).state = tripId;
      ref.invalidate(allTripsProvider);
      ref.invalidate(activeTripProvider);

      if (mounted) {
        context.go('/trips/$tripId/timeline');
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
            // Linear Progress Indicator for Steps
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _buildCurrentStepContent(l10n, theme),
                  ),
                ),
              ),
            ),
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _currentStep--),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(l10n.previousStep),
                    )
                  else
                    const SizedBox(width: 8),
                  const Spacer(),
                  if (_currentStep < 2)
                    FilledButton.icon(
                      onPressed: () => setState(() => _currentStep++),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(l10n.nextStep),
                    )
                  else
                    FilledButton.icon(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(AppLocalizations l10n, ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(l10n, theme);
      case 1:
        return _buildStep2(l10n, theme);
      case 2:
      default:
        return _buildStep3(l10n, theme);
    }
  }

  Widget _buildStep1(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.stepBasic, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
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
              setState(() => _daysCount = parsed);
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
                });
              },
            ),
            ActionChip(
              label: Text(l10n.durationTwoWeeks),
              onPressed: () {
                setState(() {
                  _daysCount = 14;
                  _daysController.text = '14';
                });
              },
            ),
            ActionChip(
              label: Text(l10n.durationOneMonth),
              onPressed: () {
                setState(() {
                  _daysCount = 30;
                  _daysController.text = '30';
                });
              },
            ),
            ActionChip(
              label: Text(l10n.durationThreeMonths),
              onPressed: () {
                setState(() {
                  _daysCount = 90;
                  _daysController.text = '90';
                });
              },
            ),
            ActionChip(
              label: Text(l10n.durationSixMonths),
              onPressed: () {
                setState(() {
                  _daysCount = 180;
                  _daysController.text = '180';
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _daysCount.clamp(1, 180).toDouble(),
          min: 1,
          max: 180,
          divisions: 179,
          label: '$_daysCount Tage',
          onChanged: (val) {
            setState(() {
              _daysCount = val.round();
              _daysController.text = '$_daysCount';
            });
          },
        ),
      ],
    );
  }

  Widget _buildStep2(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.stepBoat, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(l10n.isCharter)),
            ButtonSegment(value: false, label: Text(l10n.isOwnBoat)),
          ],
          selected: {_isCharter},
          onSelectionChanged: (val) => setState(() => _isCharter = val.first),
        ),
        const SizedBox(height: 16),
        Text(l10n.boatType, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'monohull', label: Text(l10n.boatMonohull)),
            ButtonSegment(value: 'catamaran', label: Text(l10n.boatCatamaran)),
          ],
          selected: {_boatType},
          onSelectionChanged: (val) {
            setState(() {
              _boatType = val.first;
              if (!_hasNoFridge) {
                _fridgeCapacity = _boatType == 'catamaran' ? 150.0 : 100.0;
              }
            });
          },
        ),
        const SizedBox(height: 16),
        Text(l10n.climateQuestion, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _climate,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: [
            DropdownMenuItem(value: 'cool', child: Text(l10n.climateCool)),
            DropdownMenuItem(value: 'warm', child: Text(l10n.climateWarm)),
            DropdownMenuItem(value: 'hot', child: Text(l10n.climateHot)),
          ],
          onChanged: (val) => setState(() => _climate = val ?? 'warm'),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.noFridgeSwitch),
          value: _hasNoFridge,
          onChanged: (val) {
            setState(() {
              _hasNoFridge = val;
              if (val) {
                _fridgeCapacity = 0.0;
              } else if (_fridgeCapacity == 0) {
                _fridgeCapacity = _boatType == 'catamaran' ? 150.0 : 100.0;
              }
            });
          },
        ),
        if (!_hasNoFridge) ...[
          Text('${l10n.fridgeCapacity}: ${_fridgeCapacity.round()} l', style: theme.textTheme.titleMedium),
          Slider(
            value: _fridgeCapacity.clamp(0, 300),
            min: 0,
            max: 300,
            divisions: 60,
            label: '${_fridgeCapacity.round()} l',
            onChanged: (val) {
              setState(() {
                _fridgeCapacity = val;
                if (val == 0) {
                  _hasNoFridge = true;
                }
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStep3(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.crewSectionTitle, style: theme.textTheme.headlineSmall),
            Text(
              '${_crewMembers.length} ${l10n.crewCount.toUpperCase()}',
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // List of crew members
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
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        Text(l10n.profilTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        // Question 1: Appetit
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
        const SizedBox(height: 16),
        // Question 2: Trinken
        Text(l10n.crewDrinkingQuestion, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.drinkingRelaxed),
              selected: _crewDrinking == CrewDrinking.relaxed,
              onSelected: (_) => setState(() => _crewDrinking = CrewDrinking.relaxed),
            ),
            ChoiceChip(
              label: Text(l10n.drinkingNormal),
              selected: _crewDrinking == CrewDrinking.normal,
              onSelected: (_) => setState(() => _crewDrinking = CrewDrinking.normal),
            ),
            ChoiceChip(
              label: Text(l10n.drinkingFestive),
              selected: _crewDrinking == CrewDrinking.festive,
              onSelected: (_) => setState(() => _crewDrinking = CrewDrinking.festive),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Reserve Wetter Switch
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
    );
  }
}
