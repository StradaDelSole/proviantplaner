/// Reine Dart-Prüfengine für den Vorrats-Review (PIVOT2 / Issue #26).
/// Arbeitet vollständig deterministisch und lesend.
/// Keine DAOs, keine DB-Schreiboperationen, keine Modifikation von Listendaten.
library;

import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/calculation_result.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/assist_type.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/catalog_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/provisioning_review_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';

/// Eingabedaten für die Vorratsprüfung.
class ProvisioningReviewInput {
  final Trip trip;
  final List<CrewMember> crew;
  final List<TripDay> tripDays;
  final List<ShoppingStop> stops;
  final List<ShoppingListItemView> allItems;
  final CatalogData catalog;
  final QuantitiesData quantities;
  final ProvisioningReviewConfig config;
  final int? currentStopDayNumber;
  final int? daysUntilNextStop;

  const ProvisioningReviewInput({
    required this.trip,
    required this.crew,
    required this.tripDays,
    required this.stops,
    required this.allItems,
    required this.catalog,
    required this.quantities,
    required this.config,
    this.currentStopDayNumber,
    this.daysUntilNextStop,
  });
}

/// Prüf-Engine für die Vorratsliste.
class ProvisioningReviewEngine {
  final ProvisioningReviewInput input;

  const ProvisioningReviewEngine(this.input);

  /// Führt die vollständige Vorratsprüfung durch und liefert ein flüchtiges [ProvisioningReviewResult].
  ProvisioningReviewResult evaluate() {
    final findings = <ProvisioningReviewFinding>[];

    // 1. Missing Basics gemäß Konfiguration
    _evaluateMissingBasics(findings);

    // 2. Trinkwasser-Bedarfsabgleich (WATER1 Simplification)
    _evaluateDrinkingWater(findings);

    // 3. Haltbarkeit & Frische (Issue #8)
    _evaluateFreshnessAndShelfLife(findings);

    // 4. Kühlung & Tiefkühlung Plausibilität
    final coolingComplete = _evaluateCoolingAndFreezer(findings);

    // 5. Gesamtgewicht und Gesamtvolumen
    final weightVol = _calculateWeightAndVolume();

    // 6. Gesamtstatus-Aggregation
    final overallStatus = _aggregateStatus(findings);

    return ProvisioningReviewResult(
      status: overallStatus,
      findings: findings,
      totalWeightKg: weightVol.totalWeightKg,
      totalVolumeLiters: weightVol.totalVolumeLiters,
      hasItemsWithoutWeight: weightVol.hasItemsWithoutWeight,
      isCoolingAssessmentComplete: coolingComplete,
    );
  }

  /// 1. Missing Basics
  void _evaluateMissingBasics(List<ProvisioningReviewFinding> findings) {
    final adoptedCatalogItems = input.allItems
        .where((it) => it.isOnList && !it.isCustom && it.variant != null)
        .toList();

    for (final rule in input.config.rules) {
      bool isSatisfied = false;

      switch (rule.type) {
        case ProvisioningReviewRuleType.shelfLifeGroupPresence:
          final thresholdDays = switch (rule.thresholdField) {
            'quantities.rounding.durable_min_shelf_life_days' =>
              input.quantities.durableMinShelfLifeDays,
            _ => throw FormatException(
                'Nicht unterstütztes threshold_field: "${rule.thresholdField}"'),
          };
          isSatisfied = adoptedCatalogItems.any((it) =>
              it.variant!.group == rule.group &&
              it.variant!.shelfLifeDays >= thresholdDays);
          break;
        case ProvisioningReviewRuleType.groupPresence:
          isSatisfied = adoptedCatalogItems.any((it) => it.variant!.group == rule.group);
          break;
        case ProvisioningReviewRuleType.anyVariantPresence:
          isSatisfied = adoptedCatalogItems.any((it) => rule.variants.contains(it.variant!.id));
          break;
      }

      if (!isSatisfied) {
        findings.add(ProvisioningReviewFinding(
          id: 'missing_basic_${rule.id}',
          kind: ProvisioningReviewKind.missingBasic,
          severity: rule.severity,
          ruleId: rule.id,
          groupId: rule.group,
          action: rule.action,
        ));
      }
    }
  }

  /// 2. Trinkwasser (WATER1 Simplification)
  void _evaluateDrinkingWater(List<ProvisioningReviewFinding> findings) {
    final climateStr = input.trip.climate;
    final climate = ClimateZone.fromString(climateStr);

    final key = climate.rawValue;
    final legacyKey = switch (climate) {
      ClimateZone.cool => 'temperate',
      ClimateZone.warm => 'mediterranean_summer',
      ClimateZone.hot => 'hot_or_remote',
    };
    final waterConfig = input.quantities.waterLiters[key] ??
        input.quantities.waterLiters[legacyKey] ??
        input.quantities.waterLiters['warm'] ??
        input.quantities.waterLiters['mediterranean_summer'];

    final catalogWaterGroup = input.catalog.groups.firstWhere(
      (g) => g.id == 'water',
      orElse: () => const CatalogGroup(
        id: 'water',
        category: 'getraenke',
        nameDe: 'Wasser',
        assist: AssistType.needsBased,
        profile: GroupProfile.none,
        appliesTo: AppliesTo.all,
        split: GroupSplit.equal,
        visibility: GroupVisibility.all,
        mode: GroupMode.quantity,
      ),
    );

    final dailyLiters = waterConfig?.defaultValue ?? (catalogWaterGroup.need?.amount ?? 2.0);

    // Crew factor sum gemäß DATA1 / WATER1
    double factorSum = 0.0;
    for (final member in input.crew) {
      final double personBase = !member.isChild ? 1.0 : input.quantities.factors.child;
      factorSum += personBase;
    }

    // Ermittle alle übernommenen Artikel der Bedarfsgruppe 'water' mit effektivem AssistType 'needsBased'
    final waterItems = <ShoppingListItemView>[];
    for (final item in input.allItems) {
      if (!item.isOnList) continue;
      final isWaterGroup = item.variant?.group == 'water' || item.categoryId == 'water';
      if (!isWaterGroup) continue;

      final effectiveAssist = item.variant != null
          ? input.catalog.getEffectiveAssist(item.variant!)
          : item.assistType;
      if (effectiveAssist != AssistType.needsBased) continue;

      waterItems.add(item);
    }

    double itemLitersForPackages(ShoppingListItemView item, int packages) {
      if (packages <= 0) return 0.0;
      final packSize = item.effectivePackSize;
      final packUnit = (item.variant?.pack.unit ?? item.unit).toLowerCase().trim();
      if (packUnit == 'l') {
        return packages * packSize;
      } else if (packUnit == 'ml') {
        return (packages * packSize) / 1000.0;
      }
      return 0.0;
    }

    final sortedStops = [...input.stops]..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    final hasStopWaterAllocations = sortedStops.length > 1 &&
        waterItems.any((it) => it.allocationsByStop.values.any((a) => a.allocatedPackages > 0));

    if (input.daysUntilNextStop != null) {
      // Spezifischer Stopp-Horizont ist vorgegeben
      final effectiveDays = input.daysUntilNextStop!;
      final minimumDrinkingWater = dailyLiters * effectiveDays * factorSum;

      double actualSelectedLiters = 0.0;
      if (sortedStops.isNotEmpty && input.currentStopDayNumber != null) {
        final currentStop = sortedStops.firstWhere(
          (s) => s.dayNumber == input.currentStopDayNumber,
          orElse: () => sortedStops.first,
        );
        final isFirst = currentStop.id == sortedStops.first.id;
        for (final item in waterItems) {
          final totalOther = item.allocationsByStop.entries
              .where((e) => e.key != currentStop.id)
              .fold(0, (sum, e) => sum + e.value.allocatedPackages);
          final pkgs = item.packagesAtStop(currentStop.id, isFirstStop: isFirst, totalOtherAllocated: totalOther);
          actualSelectedLiters += itemLitersForPackages(item, pkgs);
        }
      } else {
        for (final item in waterItems) {
          actualSelectedLiters += itemLitersForPackages(item, item.effectivePackages);
        }
      }

      if (actualSelectedLiters + epsilon < minimumDrinkingWater) {
        findings.add(ProvisioningReviewFinding(
          id: 'water_undercoverage_check',
          kind: ProvisioningReviewKind.drinkingWaterCheck,
          severity: ProvisioningReviewSeverity.check,
          groupId: 'water',
          estimatedValue: minimumDrinkingWater,
          actualValue: actualSelectedLiters,
          unit: 'l',
          horizonDays: effectiveDays,
          hasPotableTank: input.trip.isWaterTankDrinkable && input.trip.waterTankLiters > 0,
          hasWatermaker: input.trip.hasWatermaker,
          action: const ProvisioningReviewAction(
            type: ProvisioningReviewActionType.searchOrAdd,
            targetGroup: 'water',
          ),
        ));
      }
    } else if (hasStopWaterAllocations) {
      // Mehrere Stopps mit Wasser-Allokationen: prüfe jeden Stopp-Horizont
      for (int i = 0; i < sortedStops.length; i++) {
        final stop = sortedStops[i];
        final int horizonDays;
        if (i < sortedStops.length - 1) {
          final diff = sortedStops[i + 1].dayNumber - stop.dayNumber;
          horizonDays = diff > 0 ? diff : 1;
        } else {
          final diff = (input.trip.daysCount - stop.dayNumber) + 1;
          horizonDays = diff > 0 ? diff : 1;
        }

        final horizonMinWater = dailyLiters * horizonDays * factorSum;
        final isFirst = (i == 0);

        double stopLiters = 0.0;
        for (final item in waterItems) {
          final totalOther = item.allocationsByStop.entries
              .where((e) => e.key != stop.id)
              .fold(0, (sum, e) => sum + e.value.allocatedPackages);
          final pkgs = item.packagesAtStop(stop.id, isFirstStop: isFirst, totalOtherAllocated: totalOther);
          stopLiters += itemLitersForPackages(item, pkgs);
        }

        if (stopLiters + epsilon < horizonMinWater) {
          findings.add(ProvisioningReviewFinding(
            id: 'water_undercoverage_check_stop_${stop.id}',
            kind: ProvisioningReviewKind.drinkingWaterCheck,
            severity: ProvisioningReviewSeverity.check,
            groupId: 'water',
            estimatedValue: horizonMinWater,
            actualValue: stopLiters,
            unit: 'l',
            horizonDays: horizonDays,
            hasPotableTank: input.trip.isWaterTankDrinkable && input.trip.waterTankLiters > 0,
            hasWatermaker: input.trip.hasWatermaker,
            action: const ProvisioningReviewAction(
              type: ProvisioningReviewActionType.searchOrAdd,
              targetGroup: 'water',
            ),
          ));
        }
      }
    } else {
      // Gesamter Törn (ohne spezifische Stopp-Allokationen)
      final effectiveDays = input.trip.daysCount;
      final minimumDrinkingWater = dailyLiters * effectiveDays * factorSum;

      double actualSelectedLiters = 0.0;
      for (final item in waterItems) {
        actualSelectedLiters += itemLitersForPackages(item, item.effectivePackages);
      }

      if (actualSelectedLiters + epsilon < minimumDrinkingWater) {
        findings.add(ProvisioningReviewFinding(
          id: 'water_undercoverage_check',
          kind: ProvisioningReviewKind.drinkingWaterCheck,
          severity: ProvisioningReviewSeverity.check,
          groupId: 'water',
          estimatedValue: minimumDrinkingWater,
          actualValue: actualSelectedLiters,
          unit: 'l',
          horizonDays: effectiveDays,
          hasPotableTank: input.trip.isWaterTankDrinkable && input.trip.waterTankLiters > 0,
          hasWatermaker: input.trip.hasWatermaker,
          action: const ProvisioningReviewAction(
            type: ProvisioningReviewActionType.searchOrAdd,
            targetGroup: 'water',
          ),
        ));
      }
    }
  }

  /// Ermittelt den effektiven Zeithorizont für einen Artikel unter Berücksichtigung von Einkaufsstopps und Allokationen.
  int _resolveEffectiveHorizonForItem(ShoppingListItemView item) {
    if (input.daysUntilNextStop != null) {
      return input.daysUntilNextStop!;
    }
    if (input.stops.isEmpty) {
      return input.trip.daysCount;
    }
    final sortedStops = [...input.stops]..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    if (sortedStops.length <= 1) {
      return input.trip.daysCount;
    }

    final firstStop = sortedStops[0];
    int explicitlyAllocated = 0;
    final activeStopIds = <int>{};
    for (final entry in item.allocationsByStop.entries) {
      if (entry.value.allocatedPackages > 0) {
        activeStopIds.add(entry.key);
        explicitlyAllocated += entry.value.allocatedPackages;
      }
    }

    // Restmenge, die nicht explizit Folge-Stopps zugeordnet ist, fällt implizit auf den ersten Stopp:
    final residualPackages = item.effectivePackages - explicitlyAllocated;
    if (residualPackages > 0) {
      activeStopIds.add(firstStop.id);
    }

    if (activeStopIds.isEmpty) {
      activeStopIds.add(firstStop.id);
    }

    // Maximaler Horizont über alle Stopps, an denen der Artikel gekauft wird
    int maxHorizon = 1;
    for (int i = 0; i < sortedStops.length; i++) {
      final stop = sortedStops[i];
      if (activeStopIds.contains(stop.id)) {
        final int stopDuration;
        if (i < sortedStops.length - 1) {
          final nextStop = sortedStops[i + 1];
          final diff = nextStop.dayNumber - stop.dayNumber;
          stopDuration = diff > 0 ? diff : 1;
        } else {
          final diff = (input.trip.daysCount - stop.dayNumber) + 1;
          stopDuration = diff > 0 ? diff : 1;
        }
        if (stopDuration > maxHorizon) {
          maxHorizon = stopDuration;
        }
      }
    }
    return maxHorizon;
  }

  /// 3. Haltbarkeit & Frische (Issue #8)
  void _evaluateFreshnessAndShelfLife(List<ProvisioningReviewFinding> findings) {
    for (final item in input.allItems) {
      if (!item.isOnList || item.isCustom || item.variant == null) continue;
      final variant = item.variant!;
      final effectiveHorizonDays = _resolveEffectiveHorizonForItem(item);

      // Ein Frische-Befund wird erzeugt wenn:
      // a) buy_fresh_underway == true und Horizont > Haltbarkeit oder > 1 Tag
      // b) shelfLifeDays < relevanter Törn-/Stopphorizont (und shelfLifeDays > 0)
      final isShortShelfLife =
          variant.shelfLifeDays > 0 && variant.shelfLifeDays < effectiveHorizonDays;
      final isBuyFreshUnderway = variant.buyFreshUnderway && effectiveHorizonDays > variant.shelfLifeDays;

      if (isShortShelfLife || isBuyFreshUnderway) {
        findings.add(ProvisioningReviewFinding(
          id: 'freshness_${variant.id}_${item.item.id}',
          kind: ProvisioningReviewKind.freshness,
          severity: ProvisioningReviewSeverity.check,
          variantId: variant.id,
          groupId: variant.group,
          listItemId: item.item.id,
          shelfLifeDays: variant.shelfLifeDays,
          horizonDays: effectiveHorizonDays,
          action: ProvisioningReviewAction(
            type: input.stops.length > 1
                ? ProvisioningReviewActionType.assignShoppingStop
                : ProvisioningReviewActionType.editItem,
            listItemId: item.item.id,
          ),
        ));
      }
    }
  }

  /// 4. Kühlung & Tiefkühlung Plausibilität
  bool _evaluateCoolingAndFreezer(List<ProvisioningReviewFinding> findings) {
    final fridgeCapacity = input.trip.fridgeCapacity.toDouble();
    final hasFreezer = input.trip.hasFreezer;
    final freezerCapacity = input.trip.freezerCapacity.toDouble();

    double totalChilledVolumeLiters = 0.0;
    double totalFrozenVolumeLiters = 0.0;
    bool allCooledQuantifiable = true;

    for (final item in input.allItems) {
      if (!item.isOnList || item.variant == null) continue;
      final variant = item.variant!;
      final chill = variant.chill;

      if (chill == ChillRequirement.none) continue;

      // 4a. Harter Widerspruch: Kühlware aber Kühlschrank-Kapazität = 0
      if (chill == ChillRequirement.fridge && fridgeCapacity <= 0) {
        findings.add(ProvisioningReviewFinding(
          id: 'fridge_required_no_capacity_${variant.id}_${item.item.id}',
          kind: ProvisioningReviewKind.fridgeRequirement,
          severity: ProvisioningReviewSeverity.actionNeeded,
          variantId: variant.id,
          groupId: variant.group,
          listItemId: item.item.id,
          action: ProvisioningReviewAction(
            type: ProvisioningReviewActionType.editItem,
            listItemId: item.item.id,
          ),
        ));
      }

      // 4b. Harter Widerspruch: Tiefkühlware aber kein Tiefkühler vorhanden
      if (chill == ChillRequirement.freezer && (!hasFreezer || freezerCapacity <= 0)) {
        findings.add(ProvisioningReviewFinding(
          id: 'freezer_required_no_freezer_${variant.id}_${item.item.id}',
          kind: ProvisioningReviewKind.freezerRequirement,
          severity: ProvisioningReviewSeverity.actionNeeded,
          variantId: variant.id,
          groupId: variant.group,
          listItemId: item.item.id,
          action: ProvisioningReviewAction(
            type: ProvisioningReviewActionType.editItem,
            listItemId: item.item.id,
          ),
        ));
      }

      // Volumen-Akkumulation
      final packages = item.effectivePackages;
      final packSize = item.effectivePackSize;
      final unit = (variant.pack.unit).toLowerCase().trim();

      double? itemVolumeLiters;
      if (unit == 'l') {
        itemVolumeLiters = packages * packSize;
      } else if (unit == 'ml') {
        itemVolumeLiters = (packages * packSize) / 1000.0;
      } else if (unit == 'kg') {
        // Akzeptierte Konvertierung: 1 kg ≈ 1 l
        itemVolumeLiters = packages * packSize;
      } else if (unit == 'g') {
        itemVolumeLiters = (packages * packSize) / 1000.0;
      } else {
        // Stückware oder unbekannte Packungseinheit -> nicht exakt quantifizierbar
        allCooledQuantifiable = false;
      }

      if (itemVolumeLiters != null) {
        if (chill == ChillRequirement.fridge) {
          totalChilledVolumeLiters += itemVolumeLiters;
        } else if (chill == ChillRequirement.freezer) {
          totalFrozenVolumeLiters += itemVolumeLiters;
        }
      }
    }

    // 4c. Kühlschrank-Kapazitätsüberlastung
    if (fridgeCapacity > 0 && totalChilledVolumeLiters > fridgeCapacity + epsilon) {
      findings.add(ProvisioningReviewFinding(
        id: 'fridge_capacity_overloaded',
        kind: ProvisioningReviewKind.fridgeCapacity,
        severity: ProvisioningReviewSeverity.actionNeeded,
        estimatedValue: fridgeCapacity,
        actualValue: totalChilledVolumeLiters,
        unit: 'l',
      ));
    }

    // 4d. Tiefkühler-Kapazitätsüberlastung
    if (hasFreezer && freezerCapacity > 0 && totalFrozenVolumeLiters > freezerCapacity + epsilon) {
      findings.add(ProvisioningReviewFinding(
        id: 'freezer_capacity_overloaded',
        kind: ProvisioningReviewKind.freezerCapacity,
        severity: ProvisioningReviewSeverity.actionNeeded,
        estimatedValue: freezerCapacity,
        actualValue: totalFrozenVolumeLiters,
        unit: 'l',
      ));
    }

    // 4e. Unvollständige Kühlvolumen-Bewertung (wenn Kühlwaren ohne Liter-/Gewichtsbasis existieren)
    if (!allCooledQuantifiable) {
      final hasCoolingCapacity = fridgeCapacity > 0 || (hasFreezer && freezerCapacity > 0);
      findings.add(ProvisioningReviewFinding(
        id: 'incomplete_cooling_assessment',
        kind: ProvisioningReviewKind.incompleteCoolingAssessment,
        // Wenn eine aktive Kühlkapazität zu prüfen ist, führt unvollständige Quantifizierbarkeit zu CHECK
        severity: hasCoolingCapacity
            ? ProvisioningReviewSeverity.check
            : ProvisioningReviewSeverity.info,
      ));
    }

    return allCooledQuantifiable;
  }

  /// 5. Gewicht und Volumen
  ProvisionWeightVolume _calculateWeightAndVolume() {
    final adoptedVariants = input.allItems
        .where((it) => it.isOnList)
        .map((it) => VariantCalculationResult(
              variantId: it.id,
              groupId: it.variant?.group ?? it.categoryId,
              nameDe: it.name,
              department: it.department,
              isSelected: it.isSelected,
              share: it.share,
              calculatedNeedAmount: it.calculatedQuantity,
              unit: it.unit,
              packSize: it.effectivePackSize,
              packUnit: it.variant?.pack.unit ?? it.unit,
              calculatedPackages: it.calculatedPackages,
              effectivePackages: it.effectivePackages,
              shelfLifeDays: it.shelfLifeDays,
              effectiveShelfLifeDays: it.shelfLifeDays,
              buyFreshUnderway: false,
              storage: it.storageHints,
              tags: it.variant?.tags ?? [],
              assistType: it.assistType,
            ))
        .toList();
    return QuantityEngine.calculateWeightAndVolume(adoptedVariants);
  }

  /// 6. Gesamtstatus-Aggregation
  ProvisioningReviewStatus _aggregateStatus(List<ProvisioningReviewFinding> findings) {
    if (findings.any((f) => f.severity == ProvisioningReviewSeverity.actionNeeded)) {
      return ProvisioningReviewStatus.actionNeeded;
    }
    if (findings.any((f) => f.severity == ProvisioningReviewSeverity.check)) {
      return ProvisioningReviewStatus.check;
    }
    return ProvisioningReviewStatus.ready;
  }
}

