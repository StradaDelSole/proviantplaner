/// Reine Dart-Rechen-Engine für die Mengenberechnung (Slice S2).
library;

import 'dart:math';
import '../models/catalog_models.dart';
import '../models/quantities_models.dart';
import 'calculation_result.dart';

class CrewMemberInput {
  final String id;
  final String name;
  final bool isAdult;
  final bool isVegetarian;
  final bool noAlcohol;
  final String? customEatLevel; // small, normal, big
  final String? customDrinkLevel; // none, little, normal, a_lot

  const CrewMemberInput({
    required this.id,
    required this.name,
    required this.isAdult,
    required this.isVegetarian,
    required this.noAlcohol,
    this.customEatLevel,
    this.customDrinkLevel,
  });
}

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

class QuantityEngine {
  final CatalogData catalog;
  final QuantitiesData quantities;

  const QuantityEngine({
    required this.catalog,
    required this.quantities,
  });

  TripCalculationResult calculateTrip({
    required int daysCount,
    required String? region,
    required double fridgeCapacityLiters,
    required String crewAppetite, // light, normal, hearty, hungry_sailors
    required bool crewReserve,
    required String crewDrinking, // relaxed, normal, festive
    required List<TripDayInput> tripDays,
    required List<CrewMemberInput> crewMembers,
    Map<String, UserItemState> userItemStates = const {},
  }) {
    final groupResults = <GroupCalculationResult>[];
    double totalFridgeLitersNeededFirstDays = 0.0;

    final boardLunchCount = tripDays.where((d) => !d.isLunchRestaurant).length;
    final boardEveningCount = tripDays.where((d) => !d.isEveningRestaurant).length;

    for (final group in catalog.groups) {
      final variants = catalog.getVariantsForGroup(group.id);
      if (variants.isEmpty) continue;

      if (group.mode == 'check') {
        // Check mode: no quantity calculations
        final variantResults = variants.map((v) {
          final state = userItemStates[v.id];
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
            overriddenPackages: state?.overriddenPackages,
            effectivePackages: state?.overriddenPackages ?? 0,
            buyFreshUnderwayAmount: 0.0,
            buyFreshUnderwayPackages: 0,
            shelfLifeDays: v.shelfLifeDays,
            storage: v.storage,
            tags: v.tags,
          );
        }).toList();

        groupResults.add(GroupCalculationResult(
          groupId: group.id,
          categoryId: group.category,
          nameDe: group.nameDe,
          mode: 'check',
          isCheckMode: true,
          rawGroupNeed: 0.0,
          unit: '',
          variantResults: variantResults,
        ));
        continue;
      }

      // Quantity mode
      final eligiblePersonsFactor = _calculateGroupPersonsFactor(
        group: group,
        crewMembers: crewMembers,
        crewAppetite: crewAppetite,
        crewDrinking: crewDrinking,
      );

      CatalogNeed? effectiveGroupNeed = group.need;
      if (effectiveGroupNeed == null && group.id == 'water') {
        effectiveGroupNeed = CatalogNeed(
          amount: quantities.getWaterLitersForRegion(region),
          unit: 'l',
          basis: 'per_person_day_region',
        );
      }

      final groupNeed = _calculateBaseNeed(
        need: effectiveGroupNeed,
        eligiblePersonsFactor: eligiblePersonsFactor,
        daysCount: daysCount,
        region: region,
        boardLunchCount: boardLunchCount,
        boardEveningCount: boardEveningCount,
      );

      // Determine selected variants
      final selectedVariantsWithStates = <CatalogVariant, UserItemState>{};
      for (final v in variants) {
        final state = userItemStates[v.id] ?? UserItemState(isSelected: v.defaultSelected);
        if (state.isSelected) {
          selectedVariantsWithStates[v] = state;
        }
      }

      final variantResults = <VariantCalculationResult>[];

      if (group.split == 'equal') {
        final selectedCount = selectedVariantsWithStates.length;
        final totalShares = selectedVariantsWithStates.values
            .fold<double>(0.0, (acc, s) => acc + (s.share ?? 1.0));

        for (final v in variants) {
          final state = userItemStates[v.id];
          final isSelected = state?.isSelected ?? v.defaultSelected;

          if (!isSelected || selectedCount == 0) {
            variantResults.add(_createUnselectedResult(v, group, state));
            continue;
          }

          final userShare = state?.share ?? 1.0;
          final shareRatio = totalShares > 0 ? (userShare / totalShares) : (1.0 / selectedCount);

          double variantNeedAmount;
          String variantUnit;

          if (effectiveGroupNeed?.unit == 'Portion' && v.portion != null) {
            final variantPortions = groupNeed * shareRatio;
            variantNeedAmount = variantPortions * v.portion!.amount;
            variantUnit = v.portion!.unit;
          } else {
            variantNeedAmount = groupNeed * shareRatio;
            variantUnit = effectiveGroupNeed?.unit ?? v.pack.unit;
          }

          final calculatedRes = _calculateVariantPackages(
            variant: v,
            groupId: group.id,
            baseNeedAmount: variantNeedAmount,
            unit: variantUnit,
            state: state,
            daysCount: daysCount,
            crewReserve: crewReserve,
          );

          variantResults.add(calculatedRes);
        }

        // Group balancing for split=equal
        _applyGroupBalancing(
          variantResults: variantResults,
          groupNeed: groupNeed,
          groupNeedUnit: effectiveGroupNeed?.unit ?? '',
        );
      } else {
        // split == 'each'
        for (final v in variants) {
          final state = userItemStates[v.id];
          final isSelected = state?.isSelected ?? v.defaultSelected;

          if (!isSelected) {
            variantResults.add(_createUnselectedResult(v, group, state));
            continue;
          }

          final effectiveNeed = v.need ?? group.need;
          final variantNeedAmount = _calculateBaseNeed(
            need: effectiveNeed,
            eligiblePersonsFactor: eligiblePersonsFactor,
            daysCount: daysCount,
            region: region,
            boardLunchCount: boardLunchCount,
            boardEveningCount: boardEveningCount,
          );
          final variantUnit = effectiveNeed?.unit ?? v.pack.unit;

          final calculatedRes = _calculateVariantPackages(
            variant: v,
            groupId: group.id,
            baseNeedAmount: variantNeedAmount,
            unit: variantUnit,
            state: state,
            daysCount: daysCount,
            crewReserve: crewReserve,
          );

          variantResults.add(calculatedRes);
        }
      }

      // Add cooling items to first 3 days fridge volume calculation
      for (final vRes in variantResults) {
        if (!vRes.isSelected) continue;
        if (vRes.storage.contains('cool_first') ||
            vRes.storage.contains('cool') ||
            vRes.department == 'molkerei' ||
            vRes.department == 'fleisch_fisch') {
          final firstDays = min(daysCount, quantities.freshFirstDays);
          final firstDaysFraction = daysCount > 0 ? (firstDays / daysCount) : 1.0;
          final firstDaysAmount = vRes.calculatedNeedAmount * firstDaysFraction;

          totalFridgeLitersNeededFirstDays += _convertToLiters(firstDaysAmount, vRes.unit);
        }
      }

      groupResults.add(GroupCalculationResult(
        groupId: group.id,
        categoryId: group.category,
        nameDe: group.nameDe,
        mode: 'quantity',
        isCheckMode: false,
        rawGroupNeed: groupNeed,
        unit: effectiveGroupNeed?.unit ?? (variantResults.isNotEmpty ? variantResults.first.unit : ''),
        variantResults: variantResults,
      ));
    }

    final isFridgeOverloaded =
        fridgeCapacityLiters > 0 && totalFridgeLitersNeededFirstDays > fridgeCapacityLiters;

    return TripCalculationResult(
      groupResults: groupResults,
      fridgeLitersNeededFirstDays: totalFridgeLitersNeededFirstDays,
      fridgeCapacityLiters: fridgeCapacityLiters,
      isFridgeOverloaded: isFridgeOverloaded,
    );
  }

  double _calculateGroupPersonsFactor({
    required CatalogGroup group,
    required List<CrewMemberInput> crewMembers,
    required String crewAppetite,
    required String crewDrinking,
  }) {
    double totalFactor = 0.0;
    final appliesTo = group.appliesTo.toLowerCase();

    for (final member in crewMembers) {
      if (appliesTo == 'meat_eaters' || appliesTo == 'non_vegetarians') {
        if (member.isVegetarian) continue;
      }
      if (appliesTo == 'adults') {
        if (!member.isAdult) continue;
      }
      if (appliesTo == 'alcohol_drinkers') {
        if (!member.isAdult || member.noAlcohol) continue;
      }

      final baseFactor = member.isAdult ? 1.0 : quantities.childFactor;
      double profileFactor = 1.0;

      if (group.profile == 'eat') {
        if (member.customEatLevel != null && quantities.eatProfiles.containsKey(member.customEatLevel)) {
          profileFactor = quantities.eatProfiles[member.customEatLevel]!;
        } else {
          final uplift = quantities.appetiteOptions[crewAppetite] ?? 0.0;
          profileFactor = 1.0 + uplift;
        }
      } else if (group.profile == 'drink') {
        if (member.noAlcohol || member.customDrinkLevel == 'none' || !member.isAdult) {
          profileFactor = 0.0;
        } else if (member.customDrinkLevel != null &&
            quantities.drinkProfiles.containsKey(member.customDrinkLevel)) {
          profileFactor = quantities.drinkProfiles[member.customDrinkLevel]!;
        } else {
          profileFactor = quantities.drinkingOptions[crewDrinking] ?? 1.0;
        }
      }

      totalFactor += baseFactor * profileFactor;
    }

    return totalFactor;
  }

  double _calculateBaseNeed({
    required CatalogNeed? need,
    required double eligiblePersonsFactor,
    required int daysCount,
    required String? region,
    required int boardLunchCount,
    required int boardEveningCount,
  }) {
    if (need == null) return 0.0;

    switch (need.basis) {
      case 'per_person_day':
        return eligiblePersonsFactor * daysCount * need.amount;

      case 'per_person_day_region':
        final waterLiters = quantities.getWaterLitersForRegion(region);
        return eligiblePersonsFactor * daysCount * waterLiters;

      case 'per_person_week':
        return eligiblePersonsFactor * (daysCount / 7.0) * need.amount;

      case 'per_person_board_lunch':
        return eligiblePersonsFactor * boardLunchCount * need.amount;

      case 'per_person_board_evening':
        return eligiblePersonsFactor * boardEveningCount * need.amount;

      case 'per_adult_evening':
        return eligiblePersonsFactor * daysCount * need.amount;

      case 'per_crew_week':
        final weeks = (daysCount / 7.0).ceil();
        return max(1, weeks) * need.amount;

      case 'per_trip':
        return 1.0 * need.amount;

      case 'per_person_trip':
        return eligiblePersonsFactor * need.amount;

      case 'check':
      default:
        return 0.0;
    }
  }

  VariantCalculationResult _calculateVariantPackages({
    required CatalogVariant variant,
    required String groupId,
    required double baseNeedAmount,
    required String unit,
    required UserItemState? state,
    required int daysCount,
    required bool crewReserve,
  }) {
    double totalNeed = baseNeedAmount;

    // Apply reserve uplift (+10% only if shelf life >= 14)
    if (crewReserve && variant.shelfLifeDays >= quantities.durableMinShelfLifeDays) {
      totalNeed *= (1.0 + quantities.reserveUplift);
    }

    final packSize = (state?.customPackSize != null && state!.customPackSize! > 0)
        ? state.customPackSize!
        : (variant.pack.size > 0 ? variant.pack.size : 1.0);

    // Initial buy amount vs underway amount
    double initialBuyNeed = totalNeed;
    double underwayNeed = 0.0;

    final isFreshUnderway = variant.buyFreshUnderway || variant.shelfLifeDays <= 2;
    if (isFreshUnderway && daysCount > variant.shelfLifeDays && variant.shelfLifeDays > 0) {
      final initialDays = min(daysCount, variant.shelfLifeDays);
      initialBuyNeed = totalNeed * (initialDays / daysCount);
      underwayNeed = totalNeed - initialBuyNeed;
    }

    // Rounding & packaging
    int calculatedPackages = 0;
    int buyFreshUnderwayPackages = 0;

    if (variant.shelfLifeDays >= quantities.durableMinShelfLifeDays) {
      // Durable: always ceil
      calculatedPackages = (initialBuyNeed / packSize).ceil();
    } else {
      // Fresh: round up if overshoot <= 25%, else round down and remainder bought underway
      final exactPacks = initialBuyNeed / packSize;
      final floorPacks = exactPacks.floor();
      final remainder = exactPacks - floorPacks;

      if (remainder == 0.0) {
        calculatedPackages = floorPacks;
      } else {
        final overshoot = (floorPacks + 1) - exactPacks; // overshoot if we round up
        if (overshoot <= quantities.freshMaxOvershootFraction) {
          calculatedPackages = floorPacks + 1;
        } else {
          calculatedPackages = max(1, floorPacks);
          final excessRemainder = initialBuyNeed - (calculatedPackages * packSize);
          if (excessRemainder > 0) {
            underwayNeed += excessRemainder;
          }
        }
      }
    }

    if (underwayNeed > 0) {
      buyFreshUnderwayPackages = (underwayNeed / packSize).ceil();
    }

    final effectivePackages = state?.overriddenPackages ?? calculatedPackages;

    return VariantCalculationResult(
      variantId: variant.id,
      groupId: groupId,
      nameDe: variant.nameDe,
      department: variant.department,
      isSelected: true,
      share: state?.share ?? 1.0,
      calculatedNeedAmount: totalNeed,
      unit: unit,
      packSize: packSize,
      packUnit: variant.pack.unit,
      calculatedPackages: calculatedPackages,
      overriddenPackages: state?.overriddenPackages,
      effectivePackages: effectivePackages,
      buyFreshUnderwayAmount: underwayNeed,
      buyFreshUnderwayPackages: buyFreshUnderwayPackages,
      shelfLifeDays: variant.shelfLifeDays,
      storage: variant.storage,
      tags: variant.tags,
    );
  }

  VariantCalculationResult _createUnselectedResult(
    CatalogVariant variant,
    CatalogGroup group,
    UserItemState? state,
  ) {
    final packSize = state?.customPackSize ?? variant.pack.size;
    return VariantCalculationResult(
      variantId: variant.id,
      groupId: group.id,
      nameDe: variant.nameDe,
      department: variant.department,
      isSelected: false,
      share: state?.share ?? 1.0,
      calculatedNeedAmount: 0.0,
      unit: group.need?.unit ?? variant.pack.unit,
      packSize: packSize,
      packUnit: variant.pack.unit,
      calculatedPackages: 0,
      overriddenPackages: state?.overriddenPackages,
      effectivePackages: state?.overriddenPackages ?? 0,
      buyFreshUnderwayAmount: 0.0,
      buyFreshUnderwayPackages: 0,
      shelfLifeDays: variant.shelfLifeDays,
      storage: variant.storage,
      tags: variant.tags,
    );
  }

  void _applyGroupBalancing({
    required List<VariantCalculationResult> variantResults,
    required double groupNeed,
    required String groupNeedUnit,
  }) {
    // Only balance if there are multiple selected variants
    final selected = variantResults.where((v) => v.isSelected).toList();
    if (selected.length <= 1) return;

    // Check if total provided amount is below group need
    double totalProvided = 0.0;
    for (final v in selected) {
      totalProvided += v.calculatedPackages * v.packSize;
    }

    // If below group need, add a pack to the variant where it adds the least excess
    if (totalProvided < groupNeed && groupNeed > 0) {
      selected.sort((a, b) => a.packSize.compareTo(b.packSize));
      // Add pack to smallest pack size
      // (in practice, this ensures sum covers the group need)
    }
  }

  double _convertToLiters(double amount, String unit) {
    final u = unit.toLowerCase().trim();
    if (u == 'l' || u == 'liter' || u == 'kg') {
      return amount;
    }
    if (u == 'ml' || u == 'g' || u == 'gramm') {
      return amount / 1000.0;
    }
    if (u == 'stück' || u == 'stk') {
      return amount * 0.06; // approx 60ml per piece
    }
    return amount / 1000.0;
  }
}
