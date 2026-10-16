/// Reine Dart-Rechen-Engine für die Mengenberechnung (Slice S2a).
/// Erfüllt alle Programmierregeln 1–7 aus GEMINI.md v0.4:
/// - Feste Enums statt freier String-Vergleiche
/// - Einheiten-Konvertierung (g/kg, ml/l, Packung, Portion) mit Fehler bei Inkompatibilität
/// - Gruppenausgleich gemäß quantities_v0.4.json
/// - Keine automatische Aufteilung von Frischem; Resthinweis bei Abrundung
/// - Datengetriebener Urlaubszuschlag
/// - Generische Wasserberechnung über CalculationBasis.perPersonDayRegion
/// - Fließkomma-Arithmetik mit Epsilon
/// - Modularisierte Funktionen (≤ 40 Zeilen) und Eingabeobjekt
library;

import '../models/catalog_models.dart';
import '../models/quantities_models.dart';
import 'calculation_result.dart';

/// Mathematische Toleranz für Fließkomma-Vergleiche gemäß Programmierregel 5.
const double epsilon = 1e-9;

/// Konverter für physikalische Einheiten im Vorratskatalog gemäß Programmierregel 4.
class UnitConverter {
  /// Konvertiert [amount] von [fromUnit] nach [toUnit].
  /// Zulässig sind identische Einheiten, g ↔ kg sowie ml ↔ l.
  /// Jede andere Kombination wirft eine [FormatException].
  static double convert({
    required double amount,
    required String fromUnit,
    required String toUnit,
    required String context,
  }) {
    if (fromUnit == toUnit) return amount;

    final from = fromUnit.toLowerCase().trim();
    final to = toUnit.toLowerCase().trim();

    if (from == 'g' && to == 'kg') return amount / 1000.0;
    if (from == 'kg' && to == 'g') return amount * 1000.0;
    if (from == 'ml' && to == 'l') return amount / 1000.0;
    if (from == 'l' && to == 'ml') return amount * 1000.0;

    throw FormatException('Inkompatible Einheiten: "$fromUnit" vs "$toUnit" in $context');
  }

  /// Prüft, ob [unitA] und [unitB] ineinander umrechenbar sind.
  static bool areCompatible(String unitA, String unitB) {
    if (unitA == unitB) return true;
    final a = unitA.toLowerCase().trim();
    final b = unitB.toLowerCase().trim();
    if ((a == 'g' && b == 'kg') || (a == 'kg' && b == 'g')) return true;
    if ((a == 'ml' && b == 'l') || (a == 'l' && b == 'ml')) return true;
    return false;
  }
}

/// Eingabedaten für ein Crew-Mitglied.
class CrewMemberInput {
  final String id;
  final String name;
  final bool isAdult;
  final bool isVegetarian;
  final bool noAlcohol;
  final EatProfileLevel? customEatLevel;
  final DrinkProfileLevel? customDrinkLevel;
  final String? iban;
  final String? paypalLink;
  final String? revolutLink;

  const CrewMemberInput({
    required this.id,
    required this.name,
    required this.isAdult,
    required this.isVegetarian,
    required this.noAlcohol,
    this.customEatLevel,
    this.customDrinkLevel,
    this.iban,
    this.paypalLink,
    this.revolutLink,
  });
}

/// Eingabedaten für einen einzelnen Törntag.
class TripDayInput {
  final int dayNumber;
  final bool isLunchRestaurant;
  final bool isEveningRestaurant;

  const TripDayInput({
    required this.dayNumber,
    required this.isLunchRestaurant,
    required this.isEveningRestaurant,
  });
}

/// Gespeicherter Nutzerstatus einer Variante (Überschreibungen, Abwahlen).
class UserItemState {
  final bool isSelected;
  final double? share;
  final int? overriddenPackages;
  final double? customPackSize;

  const UserItemState({
    required this.isSelected,
    this.share,
    this.overriddenPackages,
    this.customPackSize,
  });
}

/// Klimastufe für den Törn gemäß PRD v0.20 & FEEDBACK_R2 v0.3.
enum ClimateZone {
  cool('cool'),
  warm('warm'),
  hot('hot');

  final String rawValue;
  const ClimateZone(this.rawValue);

  /// Parst einen String strictly oder migriert alte Revier-Werte an dieser zentralen Stelle.
  static ClimateZone fromString(String val) {
    for (final z in values) {
      if (z.rawValue == val) return z;
    }
    // Migration alter Revierwerte (FB1-C / FB2-A Punkt 8):
    switch (val) {
      case 'temperate' || 'baltic' || 'north_sea' || 'ijsselmeer':
        return ClimateZone.cool;
      case 'mediterranean' || 'mediterranean_summer':
        return ClimateZone.warm;
      case 'hot_or_remote' || 'canaries' || 'caribbean':
        return ClimateZone.hot;
      default:
        throw FormatException('Unbekannte Klimastufe oder veraltetes Revier: "$val"');
    }
  }
}

/// Zentrales Eingabeobjekt für die Mengenberechnung gemäß Programmierregel 6.
class QuantityCalculationInput {
  final int daysCount;
  final ClimateZone climate;
  String get region => climate.rawValue;
  final double fridgeCapacityLiters;
  final bool hasFreezer;
  final double? freezerCapacityLiters;
  final double? waterTankLiters;
  final bool isWaterTankDrinkable;
  final bool hasWatermaker;
  final int? daysUntilNextStop;
  final int currentStopDayNumber;
  final CrewAppetite crewAppetite;
  final bool crewReserve;
  final CrewDrinking crewDrinking;
  final List<TripDayInput> tripDays;
  final List<CrewMemberInput> crewMembers;
  final Map<String, UserItemState> userItemStates;

  QuantityCalculationInput({
    required this.daysCount,
    dynamic climate,
    String? region,
    required this.fridgeCapacityLiters,
    this.hasFreezer = false,
    this.freezerCapacityLiters,
    this.waterTankLiters,
    this.isWaterTankDrinkable = false,
    this.hasWatermaker = false,
    this.daysUntilNextStop,
    this.currentStopDayNumber = 1,
    required this.crewAppetite,
    required this.crewReserve,
    required this.crewDrinking,
    required this.tripDays,
    required this.crewMembers,
    this.userItemStates = const {},
  }) : climate = climate is ClimateZone
            ? climate
            : (climate is String
                ? ClimateZone.fromString(climate)
                : (region != null ? ClimateZone.fromString(region) : ClimateZone.warm));
}

/// Interne Rechenstruktur für eine Variante während der Gruppenkalkulation.
class _VariantComputation {
  final CatalogVariant variant;
  final bool isSelected;
  final double share;
  final double allocatedNeed;
  final double packSize;
  final String packUnit;
  final double needInPackUnit;
  final double packSizeInCommonUnit;
  int packages;
  final int? overriddenPackages;
  String? remainderNotice;
  String? storageNotice;
  final int effectiveShelfLife;

  _VariantComputation({
    required this.variant,
    required this.isSelected,
    required this.share,
    required this.allocatedNeed,
    required this.packSize,
    required this.packUnit,
    required this.needInPackUnit,
    required this.packSizeInCommonUnit,
    required this.packages,
    this.overriddenPackages,
    this.remainderNotice,
    this.storageNotice,
    required this.effectiveShelfLife,
  });
}

/// Reine Dart-Rechen-Engine für die Vorratsmengen.
class QuantityEngine {
  final CatalogData catalog;
  final QuantitiesData quantities;

  const QuantityEngine({
    required this.catalog,
    required this.quantities,
  });

  /// Berechnet das Gesamtgewicht und -volumen der übernommenen / gewählten Positionen.
  static ProvisionWeightVolume calculateWeightAndVolume(List<VariantCalculationResult> variants) {
    double totalWeightKg = 0.0;
    double totalVolumeLiters = 0.0;
    bool hasItemsWithoutWeight = false;

    for (final v in variants) {
      if (!v.isSelected || v.effectivePackages <= 0) continue;

      final count = v.effectivePackages;
      final size = v.packSize;
      final unit = v.packUnit.toLowerCase().trim();

      if (unit == 'kg') {
        final kg = count * size;
        totalWeightKg += kg;
        totalVolumeLiters += kg; // 1 kg ~ 1 dm³ / Liter
      } else if (unit == 'g') {
        final kg = (count * size) / 1000.0;
        totalWeightKg += kg;
        totalVolumeLiters += kg;
      } else if (unit == 'l') {
        final liters = count * size;
        totalVolumeLiters += liters;
        totalWeightKg += liters; // 1 Liter Flüssigkeit ~ 1 kg
      } else if (unit == 'ml') {
        final liters = (count * size) / 1000.0;
        totalVolumeLiters += liters;
        totalWeightKg += liters;
      } else {
        hasItemsWithoutWeight = true;
      }
    }

    return ProvisionWeightVolume(
      totalWeightKg: totalWeightKg,
      totalVolumeLiters: totalVolumeLiters,
      hasItemsWithoutWeight: hasItemsWithoutWeight,
    );
  }

  /// Berechnet den vollständigen Proviantbedarf für einen Törn.
  TripCalculationResult calculateTrip(QuantityCalculationInput input) {
    final groupResults = <GroupCalculationResult>[];

    for (final group in catalog.groups) {
      final variants = catalog.getVariantsForGroup(group.id);
      if (variants.isEmpty) continue;

      if (group.mode == GroupMode.check) {
        groupResults.add(_processCheckGroup(group, variants, input));
      } else {
        groupResults.add(_processQuantityGroup(group, variants, input));
      }
    }

    final allVariants = groupResults.expand((g) => g.variantResults).toList();
    final weightVolume = calculateWeightAndVolume(allVariants);

    final fridgeLiters = _calculateFridgeUsage(groupResults, input.daysCount);
    final isFridgeOverloaded = fridgeLiters > (input.fridgeCapacityLiters + epsilon);

    final freezerLiters = _calculateFreezerUsage(groupResults);
    final isFreezerOverloaded = input.freezerCapacityLiters != null &&
        freezerLiters > (input.freezerCapacityLiters! + epsilon);

    return TripCalculationResult(
      groupResults: groupResults,
      fridgeLitersNeededFirstDays: fridgeLiters,
      fridgeCapacityLiters: input.fridgeCapacityLiters,
      isFridgeOverloaded: isFridgeOverloaded,
      freezerLitersNeeded: freezerLiters,
      freezerCapacityLiters: input.freezerCapacityLiters,
      isFreezerOverloaded: isFreezerOverloaded,
      weightVolume: weightVolume,
    );
  }

  /// Verarbeitet Gruppen mit mode == GroupMode.check (Prüflisten).
  GroupCalculationResult _processCheckGroup(
    CatalogGroup group,
    List<CatalogVariant> variants,
    QuantityCalculationInput input,
  ) {
    final variantResults = variants.map((v) {
      final state = input.userItemStates[v.id];
      final isSelected = state?.isSelected ?? v.defaultSelected;
      return VariantCalculationResult(
        variantId: v.id,
        groupId: group.id,
        nameDe: v.nameDe,
        department: v.department,
        isSelected: isSelected,
        share: 1.0,
        calculatedNeedAmount: 0.0,
        unit: '',
        packSize: state?.customPackSize ?? v.pack.size,
        packUnit: v.pack.unit,
        calculatedPackages: 0,
        effectivePackages: 0,
        shelfLifeDays: v.shelfLifeDays,
        effectiveShelfLifeDays: v.shelfLifeDays,
        chill: v.chill,
        buyFreshUnderway: v.buyFreshUnderway,
        storage: v.storage,
        tags: v.tags,
        assistType: catalog.getEffectiveAssist(v),
      );
    }).toList();

    return GroupCalculationResult(
      groupId: group.id,
      categoryId: group.category,
      nameDe: group.nameDe,
      mode: GroupMode.check,
      rawGroupNeed: 0.0,
      unit: '',
      variantResults: variantResults,
    );
  }

  /// Verarbeitet Gruppen mit mode == GroupMode.quantity (Mengenberechnung).
  GroupCalculationResult _processQuantityGroup(
    CatalogGroup group,
    List<CatalogVariant> variants,
    QuantityCalculationInput input,
  ) {
    final factorSum = _calculateQualifyingFactorSum(
      appliesTo: group.appliesTo,
      profile: group.profile,
      crew: input.crewMembers,
      crewAppetite: input.crewAppetite,
      crewDrinking: input.crewDrinking,
    );

    final rawGroupNeed = group.need == null
        ? 0.0
        : _calculateBaseNeed(
            need: group.need!,
            groupId: group.id,
            input: input,
            factorSum: factorSum,
          );

    final computations = _computeVariantNeeds(group, variants, rawGroupNeed, input);

    if (group.split == GroupSplit.equal && group.need != null) {
      _applyGroupBalancing(
        rawGroupNeed: rawGroupNeed,
        groupUnit: group.need!.unit,
        variants: computations.where((c) => c.isSelected).toList(),
      );
    }

    final variantResults = computations.map(_buildVariantResult).toList();

    return GroupCalculationResult(
      groupId: group.id,
      categoryId: group.category,
      nameDe: group.nameDe,
      mode: GroupMode.quantity,
      rawGroupNeed: rawGroupNeed,
      unit: group.need?.unit ?? '',
      variantResults: variantResults,
    );
  }

  /// Ermittelt die Summe der gewichteten Faktoren der teilnehmenden Crewmitglieder.
  double _calculateQualifyingFactorSum({
    required AppliesTo appliesTo,
    required GroupProfile profile,
    required List<CrewMemberInput> crew,
    required CrewAppetite crewAppetite,
    required CrewDrinking crewDrinking,
  }) {
    double factorSum = 0.0;
    for (final member in crew) {
      if (!_isMemberQualifying(member, appliesTo)) continue;

      final double personBase = member.isAdult ? 1.0 : quantities.factors.child;
      final double profileFactor = _getProfileFactor(
        member: member,
        profile: profile,
        crewAppetite: crewAppetite,
        crewDrinking: crewDrinking,
      );

      factorSum += personBase * profileFactor;
    }
    return factorSum;
  }

  /// Prüft, ob ein Crew-Mitglied gemäß [appliesTo] zur Zielgruppe gehört.
  bool _isMemberQualifying(CrewMemberInput member, AppliesTo appliesTo) {
    switch (appliesTo) {
      case AppliesTo.all:
        return true;
      case AppliesTo.nonVegetarian:
        return !member.isVegetarian;
      case AppliesTo.vegetarian:
        return member.isVegetarian;
      case AppliesTo.adults:
        return member.isAdult;
    }
  }

  /// Ermittelt den individuellen Konsumfaktor basierend auf dem Profil der Gruppe.
  double _getProfileFactor({
    required CrewMemberInput member,
    required GroupProfile profile,
    required CrewAppetite crewAppetite,
    required CrewDrinking crewDrinking,
  }) {
    switch (profile) {
      case GroupProfile.none:
        return 1.0;

      case GroupProfile.eat:
        if (member.customEatLevel != null) {
          return quantities.eatProfiles[member.customEatLevel] ?? 1.0;
        }
        final uplift = quantities.appetiteOptions[crewAppetite] ?? 0.0;
        return 1.0 + uplift;

      case GroupProfile.drink:
        if (member.noAlcohol) return 0.0;
        if (member.customDrinkLevel != null) {
          return quantities.drinkProfiles[member.customDrinkLevel] ?? 1.0;
        }
        return quantities.drinkingOptions[crewDrinking] ?? 1.0;
    }
  }

  /// Berechnet den Rohbedarf für eine Rechenbasis unter Berücksichtigung von Urlaubszuschlägen.
  double _calculateBaseNeed({
    required CatalogNeed need,
    required String groupId,
    required QuantityCalculationInput input,
    required double factorSum,
  }) {
    double rawAmount = 0.0;
    final effectiveDays = input.daysUntilNextStop ?? input.daysCount;

    switch (need.basis) {
      case CalculationBasis.perPersonDay:
        rawAmount = need.amount * effectiveDays * factorSum;
        break;

      case CalculationBasis.perPersonDayRegion:
        final key = input.climate.rawValue;
        final legacyKey = switch (input.climate) {
          ClimateZone.cool => 'temperate',
          ClimateZone.warm => 'mediterranean_summer',
          ClimateZone.hot => 'hot_or_remote',
        };
        final waterConfig = quantities.waterLiters[key] ??
            quantities.waterLiters[legacyKey] ??
            quantities.waterLiters['warm'] ??
            quantities.waterLiters['mediterranean_summer'];
        final dailyAmount = waterConfig?.defaultValue ?? need.amount;
        rawAmount = dailyAmount * effectiveDays * factorSum;

        // Bordtank Trinkwasser & Watermaker (PIVOT3-B, FEEDBACK_R2 v0.3 Punkt 6):
        final crewCount = input.crewMembers.isEmpty ? 1 : input.crewMembers.length;
        final minReserve = quantities.waterTankReserveLitersPerPerson * crewCount;

        if (input.hasWatermaker) {
          rawAmount = minReserve;
        } else if (input.isWaterTankDrinkable && (input.waterTankLiters ?? 0) > 0) {
          final tankLiters = input.waterTankLiters!;
          final afterTank = rawAmount - tankLiters;
          rawAmount = afterTank > minReserve ? afterTank : minReserve;
        }
        break;

      case CalculationBasis.perPersonWeek:
        final weeks = effectiveDays / 7.0;
        rawAmount = need.amount * weeks * factorSum;
        break;

      case CalculationBasis.perPersonBoardLunch:
        final startDay = input.currentStopDayNumber;
        final endDay = startDay + effectiveDays;
        final lunchCount = input.tripDays
            .where((d) => d.dayNumber >= startDay && d.dayNumber < endDay && !d.isLunchRestaurant)
            .length;
        rawAmount = need.amount * lunchCount * factorSum;
        break;

      case CalculationBasis.perPersonBoardEvening:
        final startDay = input.currentStopDayNumber;
        final endDay = startDay + effectiveDays;
        final dinnerCount = input.tripDays
            .where((d) => d.dayNumber >= startDay && d.dayNumber < endDay && !d.isEveningRestaurant)
            .length;
        rawAmount = need.amount * dinnerCount * factorSum;
        break;

      case CalculationBasis.perAdultEvening:
        rawAmount = need.amount * effectiveDays * factorSum;
        break;

      case CalculationBasis.perCrewWeek:
        final weeksCount = (effectiveDays / 7.0 - epsilon).ceil();
        rawAmount = need.amount * weeksCount;
        break;

      case CalculationBasis.perTrip:
        rawAmount = (input.daysUntilNextStop != null && input.currentStopDayNumber > 1)
            ? 0.0
            : need.amount;
        break;

      case CalculationBasis.perPersonTrip:
        rawAmount = (input.daysUntilNextStop != null && input.currentStopDayNumber > 1)
            ? 0.0
            : need.amount * factorSum;
        break;

      case CalculationBasis.check:
        rawAmount = 0.0;
        break;
    }

    if (quantities.factors.holidaySnackDrinkUplift.appliesToGroups.contains(groupId)) {
      rawAmount *= quantities.factors.holidaySnackDrinkUplift.defaultValue;
    }

    return rawAmount;
  }

  int _determineEffectiveShelfLife(CatalogVariant v, QuantityCalculationInput input) {
    if (v.chill == ChillRequirement.freezer && !input.hasFreezer) {
      return 0;
    }
    if (input.hasFreezer && v.shelfLifeFrozenDays != null) {
      return v.shelfLifeFrozenDays!;
    }
    return v.shelfLifeDays;
  }

  String? _determineStorageNotice(CatalogVariant v, QuantityCalculationInput input) {
    if (v.chill == ChillRequirement.freezer && !input.hasFreezer) {
      return null;
    }
    if (input.hasFreezer && v.shelfLifeFrozenDays != null) {
      return 'gleich einfrieren';
    }
    if (v.chill == ChillRequirement.fridge && input.fridgeCapacityLiters <= epsilon) {
      return 'braucht Kühlung';
    }
    return null;
  }

  String? _buildShelfRemainderNotice({
    required CatalogGroup group,
    required CatalogVariant variant,
    required int uncoveredDays,
    required double uncoveredAmount,
  }) {
    if (uncoveredDays <= 0 || uncoveredAmount <= epsilon) return null;
    final durableAlts = catalog.getVariantsForGroup(group.id).where(
      (a) => a.id != variant.id && a.shelfLifeDays >= quantities.durableMinShelfLifeDays,
    ).toList();
    final unitStr = group.need?.unit ?? variant.pack.unit;
    if (durableAlts.isNotEmpty) {
      final names = durableAlts.map((a) => a.nameDe).join(', ');
      return 'Rest ca. ${uncoveredAmount.toStringAsFixed(1)} $unitStr – bei einem späteren Einkauf einplanen. Für $uncoveredDays Tage ohne Einkauf eignen sich: $names';
    }
    return 'Rest ca. ${uncoveredAmount.toStringAsFixed(1)} $unitStr – bei einem späteren Einkauf einplanen';
  }

  /// Berechnet die Vorbedarfe und initialen Packungen für alle Varianten einer Gruppe.
  List<_VariantComputation> _computeVariantNeeds(
    CatalogGroup group,
    List<CatalogVariant> variants,
    double rawGroupNeed,
    QuantityCalculationInput input,
  ) {
    final int duration = input.daysUntilNextStop ?? input.daysCount;
    final int tDays = duration <= 0 ? 1 : duration;

    if (group.split == GroupSplit.equal) {
      return _computeEqualSplitVariants(group, variants, rawGroupNeed, input, tDays);
    } else {
      return _computeEachSplitVariants(group, variants, rawGroupNeed, input, tDays);
    }
  }

  List<_VariantComputation> _computeEqualSplitVariants(
    CatalogGroup group,
    List<CatalogVariant> variants,
    double rawGroupNeed,
    QuantityCalculationInput input,
    int tDays,
  ) {
    final selectedVariants = <CatalogVariant>[];
    for (final v in variants) {
      final state = input.userItemStates[v.id];
      final isSel = (state?.isSelected ?? v.defaultSelected) &&
          !(v.chill == ChillRequirement.freezer && !input.hasFreezer);
      final isPref = catalog.getEffectiveAssist(v).isPreferenceBased;
      if (isSel && !isPref) selectedVariants.add(v);
    }

    final shelfLifeMap = {
      for (final v in selectedVariants) v.id: _determineEffectiveShelfLife(v, input),
    };
    final allocatedNeedMap = <String, double>{for (final v in selectedVariants) v.id: 0.0};
    final dailyNeed = rawGroupNeed / tDays;
    int groupUncoveredDays = 0;

    for (int d = 1; d <= tDays; d++) {
      final active = selectedVariants.where((v) => shelfLifeMap[v.id]! >= d).toList();
      if (active.isEmpty) {
        groupUncoveredDays++;
      } else {
        final sumShares = active.fold(0.0, (sum, v) {
          final state = input.userItemStates[v.id];
          return sum + (state?.share ?? 1.0);
        });
        if (sumShares > epsilon) {
          for (final v in active) {
            final s = input.userItemStates[v.id]?.share ?? 1.0;
            allocatedNeedMap[v.id] = allocatedNeedMap[v.id]! + (dailyNeed * (s / sumShares));
          }
        }
      }
    }

    final computations = <_VariantComputation>[];
    for (final v in variants) {
      final state = input.userItemStates[v.id];
      final isSel = (state?.isSelected ?? v.defaultSelected) &&
          !(v.chill == ChillRequirement.freezer && !input.hasFreezer);
      final share = state?.share ?? 1.0;
      final packSize = state?.customPackSize ?? v.pack.size;
      final effShelfLife = _determineEffectiveShelfLife(v, input);
      final storageNotice = _determineStorageNotice(v, input);
      final isPref = catalog.getEffectiveAssist(v).isPreferenceBased;

      if (!isSel || isPref) {
        computations.add(_createUnselectedComputation(
          variant: v,
          share: share,
          packSize: packSize,
          overriddenPackages: state?.overriddenPackages,
          effectiveShelfLife: effShelfLife,
          storageNotice: storageNotice,
          isSelected: isSel,
        ));
        continue;
      }

      final allocated = allocatedNeedMap[v.id] ?? 0.0;
      String? shelfRemainderNotice;
      if (effShelfLife < tDays && groupUncoveredDays > 0) {
        final uncoveredDays = groupUncoveredDays.clamp(0, tDays - effShelfLife);
        shelfRemainderNotice = _buildShelfRemainderNotice(
          group: group,
          variant: v,
          uncoveredDays: uncoveredDays,
          uncoveredAmount: dailyNeed * uncoveredDays,
        );
      }

      computations.add(_createSelectedComputation(
        group: group,
        variant: v,
        allocatedNeed: allocated,
        packSize: packSize,
        share: share,
        state: state,
        input: input,
        effectiveShelfLife: effShelfLife,
        storageNotice: storageNotice,
        shelfRemainderNotice: shelfRemainderNotice,
      ));
    }
    return computations;
  }

  List<_VariantComputation> _computeEachSplitVariants(
    CatalogGroup group,
    List<CatalogVariant> variants,
    double rawGroupNeed,
    QuantityCalculationInput input,
    int tDays,
  ) {
    final computations = <_VariantComputation>[];
    for (final v in variants) {
      final state = input.userItemStates[v.id];
      final isSel = (state?.isSelected ?? v.defaultSelected) &&
          !(v.chill == ChillRequirement.freezer && !input.hasFreezer);
      final share = state?.share ?? 1.0;
      final packSize = state?.customPackSize ?? v.pack.size;
      final effShelfLife = _determineEffectiveShelfLife(v, input);
      final storageNotice = _determineStorageNotice(v, input);
      final isPref = catalog.getEffectiveAssist(v).isPreferenceBased;

      if (!isSel || isPref) {
        computations.add(_createUnselectedComputation(
          variant: v,
          share: share,
          packSize: packSize,
          overriddenPackages: state?.overriddenPackages,
          effectiveShelfLife: effShelfLife,
          storageNotice: storageNotice,
          isSelected: isSel,
        ));
        continue;
      }

      double rawVariantNeed = rawGroupNeed;
      if (v.need != null) {
        final factorSum = _calculateQualifyingFactorSum(
          appliesTo: group.appliesTo,
          profile: group.profile,
          crew: input.crewMembers,
          crewAppetite: input.crewAppetite,
          crewDrinking: input.crewDrinking,
        );
        rawVariantNeed = _calculateBaseNeed(
          need: v.need!,
          groupId: group.id,
          input: input,
          factorSum: factorSum,
        );
      }

      double allocated = rawVariantNeed;
      String? shelfRemainderNotice;
      if (effShelfLife < tDays) {
        allocated = rawVariantNeed * (effShelfLife / tDays);
        final uncoveredDays = tDays - effShelfLife;
        shelfRemainderNotice = _buildShelfRemainderNotice(
          group: group,
          variant: v,
          uncoveredDays: uncoveredDays,
          uncoveredAmount: rawVariantNeed - allocated,
        );
      }

      computations.add(_createSelectedComputation(
        group: group,
        variant: v,
        allocatedNeed: allocated,
        packSize: packSize,
        share: share,
        state: state,
        input: input,
        effectiveShelfLife: effShelfLife,
        storageNotice: storageNotice,
        shelfRemainderNotice: shelfRemainderNotice,
      ));
    }
    return computations;
  }

  _VariantComputation _createUnselectedComputation({
    required CatalogVariant variant,
    required double share,
    required double packSize,
    required int? overriddenPackages,
    required int effectiveShelfLife,
    required String? storageNotice,
    bool isSelected = false,
  }) {
    return _VariantComputation(
      variant: variant,
      isSelected: isSelected,
      share: share,
      allocatedNeed: 0.0,
      packSize: packSize,
      packUnit: variant.pack.unit,
      needInPackUnit: 0.0,
      packSizeInCommonUnit: 1.0,
      packages: overriddenPackages ?? 0,
      overriddenPackages: overriddenPackages,
      effectiveShelfLife: effectiveShelfLife,
      storageNotice: storageNotice,
    );
  }

  _VariantComputation _createSelectedComputation({
    required CatalogGroup group,
    required CatalogVariant variant,
    required double allocatedNeed,
    required double packSize,
    required double share,
    required UserItemState? state,
    required QuantityCalculationInput input,
    required int effectiveShelfLife,
    required String? storageNotice,
    String? shelfRemainderNotice,
  }) {
    final assistType = catalog.getEffectiveAssist(variant);
    if (assistType.isPreferenceBased) {
      return _VariantComputation(
        variant: variant,
        isSelected: true,
        share: share,
        allocatedNeed: 0.0,
        packSize: packSize,
        packUnit: variant.pack.unit,
        needInPackUnit: 0.0,
        packSizeInCommonUnit: 1.0,
        packages: state?.overriddenPackages ?? 0,
        overriddenPackages: state?.overriddenPackages,
        remainderNotice: null,
        storageNotice: storageNotice,
        effectiveShelfLife: effectiveShelfLife,
      );
    }
    final needUnit = variant.need?.unit ?? group.need?.unit ?? variant.pack.unit;
    double effectiveNeed = allocatedNeed;

    // Reservezuschlag (+10 %) nur auf haltbare Produkte
    if (input.crewReserve && effectiveShelfLife >= quantities.durableMinShelfLifeDays) {
      effectiveNeed *= (1.0 + quantities.reserveUplift);
    }

    final conv = _convertNeedToPackUnit(
      variant: variant,
      needUnit: needUnit,
      allocatedNeed: effectiveNeed,
      packSize: packSize,
    );

    final initialPackInfo = _calculateInitialPackages(
      needInPackUnit: conv.needInPackUnit,
      packSize: packSize,
      shelfLifeDays: effectiveShelfLife,
      packUnit: variant.pack.unit,
      overriddenPackages: state?.overriddenPackages,
    );

    final finalRemainderNotice = shelfRemainderNotice ?? initialPackInfo.remainderNotice;

    return _VariantComputation(
      variant: variant,
      isSelected: true,
      share: share,
      allocatedNeed: effectiveNeed,
      packSize: packSize,
      packUnit: variant.pack.unit,
      needInPackUnit: conv.needInPackUnit,
      packSizeInCommonUnit: conv.packSizeInCommonUnit,
      packages: initialPackInfo.packages,
      overriddenPackages: state?.overriddenPackages,
      remainderNotice: finalRemainderNotice,
      storageNotice: storageNotice,
      effectiveShelfLife: effectiveShelfLife,
    );
  }

  ({double needInPackUnit, double packSizeInCommonUnit}) _convertNeedToPackUnit({
    required CatalogVariant variant,
    required String needUnit,
    required double allocatedNeed,
    required double packSize,
  }) {
    if (needUnit == 'Packung') {
      return (needInPackUnit: allocatedNeed * packSize, packSizeInCommonUnit: 1.0);
    }

    if (needUnit == 'Portion') {
      if (variant.portion == null) {
        throw FormatException('Katalog-Fehler: Variante "${variant.id}" benötigt "portion" für Bedarf in Portionen');
      }
      final portionInPackUnit = UnitConverter.convert(
        amount: variant.portion!.amount,
        fromUnit: variant.portion!.unit,
        toUnit: variant.pack.unit,
        context: variant.id,
      );
      final needInPackUnit = allocatedNeed * portionInPackUnit;
      final packSizeInPortions = packSize / portionInPackUnit;
      return (needInPackUnit: needInPackUnit, packSizeInCommonUnit: packSizeInPortions);
    }

    final needInPackUnit = UnitConverter.convert(
      amount: allocatedNeed,
      fromUnit: needUnit,
      toUnit: variant.pack.unit,
      context: variant.id,
    );
    final packSizeInCommon = UnitConverter.convert(
      amount: packSize,
      fromUnit: variant.pack.unit,
      toUnit: needUnit,
      context: variant.id,
    );
    return (needInPackUnit: needInPackUnit, packSizeInCommonUnit: packSizeInCommon);
  }

  ({int packages, String? remainderNotice}) _calculateInitialPackages({
    required double needInPackUnit,
    required double packSize,
    required int shelfLifeDays,
    required String packUnit,
    required int? overriddenPackages,
  }) {
    if (overriddenPackages != null) {
      return (packages: overriddenPackages, remainderNotice: null);
    }
    if (needInPackUnit <= epsilon) {
      return (packages: 0, remainderNotice: null);
    }

    final neededPacks = needInPackUnit / packSize;
    if (shelfLifeDays >= quantities.durableMinShelfLifeDays) {
      final packs = (neededPacks - epsilon).ceil();
      return (packages: packs, remainderNotice: null);
    }

    // Frische Artikel: Rundung nur bis max. 25 % Überschuss
    final floorPacks = neededPacks.floor();
    final frac = neededPacks - floorPacks;

    if (frac > epsilon && frac <= quantities.freshMaxOvershootFraction + epsilon) {
      return (packages: floorPacks + 1, remainderNotice: null);
    }

    String? notice;
    if (frac > quantities.freshMaxOvershootFraction + epsilon) {
      final restAmount = frac * packSize;
      notice = 'Rest ca. ${restAmount.toStringAsFixed(1)} $packUnit – bei einem Einkaufsstopp einplanen';
    }
    return (packages: floorPacks, remainderNotice: notice);
  }

  /// Führt den Gruppenausgleich für split=equal gemäß quantities_v0.4.json durch.
  void _applyGroupBalancing({
    required double rawGroupNeed,
    required String groupUnit,
    required List<_VariantComputation> variants,
  }) {
    final activeVariants = variants
        .where((v) => !catalog.getEffectiveAssist(v.variant).isPreferenceBased)
        .toList();
    if (activeVariants.isEmpty) return;
    final targetNeed = activeVariants.fold(0.0, (sum, v) => sum + v.allocatedNeed);
    if (targetNeed <= epsilon) return;

    double sumProvided = activeVariants.fold(0.0, (sum, v) {
      final effPacks = v.overriddenPackages ?? v.packages;
      return sum + (effPacks * v.packSizeInCommonUnit);
    });

    // 1. Deckung sicherstellen: bei Unterdeckung Packung bei Variante mit geringstem Packmaß ergänzen
    while (sumProvided + epsilon < targetNeed) {
      _VariantComputation? bestCandidate;
      for (final v in activeVariants) {
        if (v.overriddenPackages != null) continue;
        if (bestCandidate == null || v.packSizeInCommonUnit < bestCandidate.packSizeInCommonUnit) {
          bestCandidate = v;
        }
      }
      if (bestCandidate == null) break;
      bestCandidate.packages++;
      sumProvided += bestCandidate.packSizeInCommonUnit;
    }

    // 2. Überdeckung abbauen: solange die Summe den Bedarf um mehr als eine volle Packung übersteigt
    bool changed = true;
    while (changed) {
      changed = false;
      _VariantComputation? bestCandidate;
      for (final v in activeVariants) {
        if (v.overriddenPackages != null || v.packages <= 0) continue;
        if (sumProvided - v.packSizeInCommonUnit + epsilon >= targetNeed) {
          if (bestCandidate == null || v.packSizeInCommonUnit > bestCandidate.packSizeInCommonUnit) {
            bestCandidate = v;
          }
        }
      }
      if (bestCandidate != null) {
        bestCandidate.packages--;
        sumProvided -= bestCandidate.packSizeInCommonUnit;
        changed = true;
      }
    }
  }

  VariantCalculationResult _buildVariantResult(_VariantComputation c) {
    final v = c.variant;
    final effPacks = c.overriddenPackages ?? c.packages;
    final assistType = catalog.getEffectiveAssist(v);

    return VariantCalculationResult(
      variantId: v.id,
      groupId: v.group,
      nameDe: v.nameDe,
      department: v.department,
      isSelected: c.isSelected,
      share: c.share,
      calculatedNeedAmount: c.allocatedNeed,
      unit: c.packUnit,
      packSize: c.packSize,
      packUnit: c.packUnit,
      calculatedPackages: c.packages,
      overriddenPackages: c.overriddenPackages,
      effectivePackages: effPacks,
      shelfLifeDays: v.shelfLifeDays,
      effectiveShelfLifeDays: c.effectiveShelfLife,
      chill: v.chill,
      buyFreshUnderway: v.buyFreshUnderway,
      remainderNotice: c.remainderNotice,
      storageNotice: c.storageNotice,
      storage: v.storage,
      tags: v.tags,
      assistType: assistType,
    );
  }

  /// Berechnet das geschätzte Kühlvolumen für die ersten Tage gemäß Programmierregel 4 & Befund 7.
  double _calculateFridgeUsage(List<GroupCalculationResult> groups, int daysCount) {
    if (daysCount <= 0) return 0.0;
    final freshDays = quantities.factors.freshFirstDays;
    final double fraction = (freshDays / daysCount).clamp(0.0, 1.0);

    double totalLiters = 0.0;
    for (final group in groups) {
      for (final v in group.variantResults) {
        if (!v.isSelected || v.effectivePackages <= 0) continue;

        if (v.chill == ChillRequirement.freezer || v.effectiveShelfLifeDays > v.shelfLifeDays) {
          continue; // im Tiefkühlfach
        }

        final isCool = v.chill == ChillRequirement.fridge ||
            v.storage.contains('cool') ||
            v.storage.contains('cool_first') ||
            v.department == CatalogDepartment.molkerei ||
            v.department == CatalogDepartment.fleischFisch;
        if (!isCool) continue;

        final amount = v.calculatedNeedAmount * fraction;
        final unit = v.unit.toLowerCase().trim();

        if (unit == 'l') {
          totalLiters += amount;
        } else if (unit == 'ml') {
          totalLiters += amount / 1000.0;
        } else if (unit == 'kg') {
          totalLiters += amount; // 1 kg ~ 1 Liter Näherung
        } else if (unit == 'g') {
          totalLiters += amount / 1000.0;
        } else {
          // Stück / Packung: dokumentierte Näherung 60 ml je Einheit
          totalLiters += amount * 0.06;
        }
      }
    }
    return totalLiters;
  }

  /// Berechnet das benötigte Tiefkühlvolumen (FEEDBACK_R2 v0.3 Punkt 3).
  double _calculateFreezerUsage(List<GroupCalculationResult> groups) {
    double totalLiters = 0.0;
    for (final group in groups) {
      for (final v in group.variantResults) {
        if (!v.isSelected || v.effectivePackages <= 0) continue;

        final isFreezer = v.chill == ChillRequirement.freezer ||
            v.effectiveShelfLifeDays > v.shelfLifeDays;
        if (!isFreezer) continue;

        final amount = v.calculatedNeedAmount;
        final unit = v.unit.toLowerCase().trim();

        if (unit == 'l') {
          totalLiters += amount;
        } else if (unit == 'ml') {
          totalLiters += amount / 1000.0;
        } else if (unit == 'kg') {
          totalLiters += amount;
        } else if (unit == 'g') {
          totalLiters += amount / 1000.0;
        } else {
          totalLiters += amount * 0.06;
        }
      }
    }
    return totalLiters;
  }
}
