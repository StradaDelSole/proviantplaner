/// Ergebnis-Datenmodelle für die Mengen-Berechnung (Slice S2a).
/// Gemäß REVIEW_S2_v0.1.md: Keine automatische Aufteilung von Frischem mehr;
/// stattdessen Resthinweis `remainderNotice`, wenn Frisches abgerundet wurde.
library;

import '../models/catalog_models.dart';

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
  final bool buyFreshUnderway;
  final String? remainderNotice;
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
    required this.buyFreshUnderway,
    this.remainderNotice,
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

  const TripCalculationResult({
    required this.groupResults,
    required this.fridgeLitersNeededFirstDays,
    required this.fridgeCapacityLiters,
    required this.isFridgeOverloaded,
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
