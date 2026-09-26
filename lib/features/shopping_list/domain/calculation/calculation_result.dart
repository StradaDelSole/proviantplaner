/// Ergebnis-Datenmodelle für die Mengen-Berechnung (Slice S2a).
/// Gemäß REVIEW_S2_v0.1.md: Keine automatische Aufteilung von Frischem mehr;
/// stattdessen Resthinweis `remainderNotice`, wenn Frisches abgerundet wurde.
library;

import '../models/catalog_models.dart';

/// Gesamtgewicht und -volumen einer Proviantliste gemäß FEEDBACK_R2 v0.3 Punkt 6.
class ProvisionWeightVolume {
  final double totalWeightKg;
  final double totalVolumeLiters;
  final bool hasItemsWithoutWeight;

  const ProvisionWeightVolume({
    required this.totalWeightKg,
    required this.totalVolumeLiters,
    required this.hasItemsWithoutWeight,
  });

  static const zero = ProvisionWeightVolume(
    totalWeightKg: 0.0,
    totalVolumeLiters: 0.0,
    hasItemsWithoutWeight: false,
  );
}

/// Berechnetes Ergebnis einer einzelnen Produktvariante.
class VariantCalculationResult {
  final String variantId;
  final String groupId;
  final String nameDe;
  final CatalogDepartment department;
  final bool isSelected;
  final double share;
  final double calculatedNeedAmount;
  final String unit;
  final double packSize;
  final String packUnit;
  final int calculatedPackages;
  final int? overriddenPackages;
  final int effectivePackages;
  final int shelfLifeDays;
  final int effectiveShelfLifeDays;
  final ChillRequirement chill;
  final bool buyFreshUnderway;
  final String? remainderNotice;
  final String? storageNotice;
  final List<String> storage;
  final List<String> tags;

  const VariantCalculationResult({
    required this.variantId,
    required this.groupId,
    required this.nameDe,
    required this.department,
    required this.isSelected,
    required this.share,
    required this.calculatedNeedAmount,
    required this.unit,
    required this.packSize,
    required this.packUnit,
    required this.calculatedPackages,
    this.overriddenPackages,
    required this.effectivePackages,
    required this.shelfLifeDays,
    required this.effectiveShelfLifeDays,
    this.chill = ChillRequirement.none,
    required this.buyFreshUnderway,
    this.remainderNotice,
    this.storageNotice,
    required this.storage,
    required this.tags,
  });
}

/// Berechnetes Ergebnis einer Bedarfsgruppe.
class GroupCalculationResult {
  final String groupId;
  final String categoryId;
  final String nameDe;
  final GroupMode mode;
  final double rawGroupNeed;
  final String unit;
  final List<VariantCalculationResult> variantResults;

  const GroupCalculationResult({
    required this.groupId,
    required this.categoryId,
    required this.nameDe,
    required this.mode,
    required this.rawGroupNeed,
    required this.unit,
    required this.variantResults,
  });

  bool get isCheckMode => mode == GroupMode.check;
}

/// Gesamtergebnis einer Törn-Bedarfsberechnung.
class TripCalculationResult {
  final List<GroupCalculationResult> groupResults;
  final double fridgeLitersNeededFirstDays;
  final double fridgeCapacityLiters;
  final bool isFridgeOverloaded;
  final double freezerLitersNeeded;
  final double? freezerCapacityLiters;
  final bool isFreezerOverloaded;
  final ProvisionWeightVolume weightVolume;

  double get totalWeightKg => weightVolume.totalWeightKg;
  double get totalVolumeLiters => weightVolume.totalVolumeLiters;
  bool get hasItemsWithoutWeight => weightVolume.hasItemsWithoutWeight;

  const TripCalculationResult({
    required this.groupResults,
    required this.fridgeLitersNeededFirstDays,
    required this.fridgeCapacityLiters,
    required this.isFridgeOverloaded,
    this.freezerLitersNeeded = 0.0,
    this.freezerCapacityLiters,
    this.isFreezerOverloaded = false,
    required this.weightVolume,
  });

  VariantCalculationResult? getVariantResult(String variantId) {
    for (final g in groupResults) {
      for (final v in g.variantResults) {
        if (v.variantId == variantId) return v;
      }
    }
    return null;
  }
}
