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

/// Zentrales Eingabeobjekt für die Mengenberechnung gemäß Programmierregel 6.
class QuantityCalculationInput {
  final int daysCount;
  final String region;
  final double fridgeCapacityLiters;
  final CrewAppetite crewAppetite;
  final bool crewReserve;
  final CrewDrinking crewDrinking;
  final List<TripDayInput> tripDays;
  final List<CrewMemberInput> crewMembers;
  final Map<String, UserItemState> userItemStates;

  const QuantityCalculationInput({
    required this.daysCount,
    required this.region,
    required this.fridgeCapacityLiters,
    required this.crewAppetite,
    required this.crewReserve,
    required this.crewDrinking,
    required this.tripDays,
    required this.crewMembers,
    this.userItemStates = const {},
  });
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

    final fridgeLiters = _calculateFridgeUsage(groupResults, input.daysCount);
    final isOverloaded = fridgeLiters > (input.fridgeCapacityLiters + epsilon);

    return TripCalculationResult(
      groupResults: groupResults,
      fridgeLitersNeededFirstDays: fridgeLiters,
      fridgeCapacityLiters: input.fridgeCapacityLiters,
      isFridgeOverloaded: isOverloaded,
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
        buyFreshUnderway: v.buyFreshUnderway,
        storage: v.storage,
        tags: v.tags,
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

    switch (need.basis) {
      case CalculationBasis.perPersonDay:
        rawAmount = need.amount * input.daysCount * factorSum;
        break;

      case CalculationBasis.perPersonDayRegion:
        final waterConfig = quantities.waterLiters[input.region] ??
            quantities.waterLiters['mediterranean_summer'];
        final dailyAmount = waterConfig?.defaultValue ?? need.amount;
        rawAmount = dailyAmount * input.daysCount * factorSum;
        break;

      case CalculationBasis.perPersonWeek:
        final weeks = input.daysCount / 7.0;
        rawAmount = need.amount * weeks * factorSum;
        break;

      case CalculationBasis.perPersonBoardLunch:
        final lunchCount = input.tripDays.where((d) => !d.isLunchRestaurant).length;
        rawAmount = need.amount * lunchCount * factorSum;
        break;

      case CalculationBasis.perPersonBoardEvening:
        final dinnerCount = input.tripDays.where((d) => !d.isEveningRestaurant).length;
        rawAmount = need.amount * dinnerCount * factorSum;
        break;

      case CalculationBasis.perAdultEvening:
        rawAmount = need.amount * input.daysCount * factorSum;
        break;

      case CalculationBasis.perCrewWeek:
        final weeksCount = (input.daysCount / 7.0 - epsilon).ceil();
        rawAmount = need.amount * weeksCount;
        break;

      case CalculationBasis.perTrip:
        rawAmount = need.amount;
        break;

      case CalculationBasis.perPersonTrip:
        rawAmount = need.amount * factorSum;
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

  /// Berechnet die Vorbedarfe und initialen Packungen für alle Varianten einer Gruppe.
  List<_VariantComputation> _computeVariantNeeds(
    CatalogGroup group,
    List<CatalogVariant> variants,
    double rawGroupNeed,
    QuantityCalculationInput input,
  ) {
    final selectedVariants = <CatalogVariant>[];
    for (final v in variants) {
      final state = input.userItemStates[v.id];
      final isSel = state?.isSelected ?? v.defaultSelected;
      if (isSel) selectedVariants.add(v);
    }

    final double totalShares = selectedVariants.fold(0.0, (sum, v) {
      final state = input.userItemStates[v.id];
      return sum + (state?.share ?? 1.0);
    });

    final computations = <_VariantComputation>[];
    for (final v in variants) {
      final state = input.userItemStates[v.id];
      final isSel = state?.isSelected ?? v.defaultSelected;
      final share = state?.share ?? 1.0;
      final packSize = state?.customPackSize ?? v.pack.size;

      if (!isSel) {
        computations.add(_createUnselectedComputation(v, share, packSize, state?.overriddenPackages));
        continue;
      }

      final allocatedNeed = _resolveAllocatedNeed(
        group: group,
        variant: v,
        rawGroupNeed: rawGroupNeed,
        share: share,
        totalShares: totalShares,
        input: input,
      );

      computations.add(_createSelectedComputation(
        group: group,
        variant: v,
        allocatedNeed: allocatedNeed,
        packSize: packSize,
        share: share,
        state: state,
        input: input,
      ));
    }

    return computations;
  }

  _VariantComputation _createUnselectedComputation(
    CatalogVariant variant,
    double share,
    double packSize,
    int? overriddenPackages,
  ) {
    return _VariantComputation(
      variant: variant,
      isSelected: false,
      share: share,
      allocatedNeed: 0.0,
      packSize: packSize,
      packUnit: variant.pack.unit,
      needInPackUnit: 0.0,
      packSizeInCommonUnit: 1.0,
      packages: 0,
      overriddenPackages: overriddenPackages,
    );
  }

  double _resolveAllocatedNeed({
    required CatalogGroup group,
    required CatalogVariant variant,
    required double rawGroupNeed,
    required double share,
    required double totalShares,
    required QuantityCalculationInput input,
  }) {
    if (group.split == GroupSplit.equal) {
      if (totalShares <= epsilon) return 0.0;
      return rawGroupNeed * (share / totalShares);
    }

    // split == GroupSplit.each
    if (variant.need != null) {
      final factorSum = _calculateQualifyingFactorSum(
        appliesTo: group.appliesTo,
        profile: group.profile,
        crew: input.crewMembers,
        crewAppetite: input.crewAppetite,
        crewDrinking: input.crewDrinking,
      );
      return _calculateBaseNeed(
        need: variant.need!,
        groupId: group.id,
        input: input,
        factorSum: factorSum,
      );
    }
    return rawGroupNeed;
  }

  _VariantComputation _createSelectedComputation({
    required CatalogGroup group,
    required CatalogVariant variant,
    required double allocatedNeed,
    required double packSize,
    required double share,
    required UserItemState? state,
    required QuantityCalculationInput input,
  }) {
    final needUnit = variant.need?.unit ?? group.need?.unit ?? variant.pack.unit;
    double effectiveNeed = allocatedNeed;

    // Reservezuschlag (+10 %) nur auf haltbare Produkte
    if (input.crewReserve && variant.shelfLifeDays >= quantities.durableMinShelfLifeDays) {
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
      shelfLifeDays: variant.shelfLifeDays,
      packUnit: variant.pack.unit,
      overriddenPackages: state?.overriddenPackages,
    );

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
      remainderNotice: initialPackInfo.remainderNotice,
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
    if (variants.isEmpty || rawGroupNeed <= epsilon) return;

    double sumProvided = variants.fold(0.0, (sum, v) {
      final effPacks = v.overriddenPackages ?? v.packages;
      return sum + (effPacks * v.packSizeInCommonUnit);
    });

    // 1. Deckung sicherstellen: bei Unterdeckung Packung bei Variante mit geringstem Packmaß ergänzen
    while (sumProvided + epsilon < rawGroupNeed) {
      _VariantComputation? bestCandidate;
      for (final v in variants) {
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
      for (final v in variants) {
        if (v.overriddenPackages != null || v.packages <= 0) continue;
        if (sumProvided - v.packSizeInCommonUnit + epsilon >= rawGroupNeed) {
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
      buyFreshUnderway: v.buyFreshUnderway,
      remainderNotice: c.remainderNotice,
      storage: v.storage,
      tags: v.tags,
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
        if (!v.isSelected) continue;

        final isCool = v.storage.contains('cool') ||
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
}
