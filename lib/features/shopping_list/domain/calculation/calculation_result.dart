/// Ergebnis-Datenmodelle für die Mengen-Berechnung (Slice S2).
library;

class VariantCalculationResult {
  final String variantId;
  final String groupId;
  final String nameDe;
  final String department;
  final bool isSelected;
  final double share;
  final double calculatedNeedAmount;
  final String unit;
  final double packSize;
  final String packUnit;
  final int calculatedPackages;
  final int? overriddenPackages;
  final int effectivePackages;
  final double buyFreshUnderwayAmount;
  final int buyFreshUnderwayPackages;
  final int shelfLifeDays;
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
    required this.buyFreshUnderwayAmount,
    required this.buyFreshUnderwayPackages,
    required this.shelfLifeDays,
    required this.storage,
    required this.tags,
  });
}

class GroupCalculationResult {
  final String groupId;
  final String categoryId;
  final String nameDe;
  final String mode; // quantity, check
  final bool isCheckMode;
  final double rawGroupNeed;
  final String unit;
  final List<VariantCalculationResult> variantResults;

  const GroupCalculationResult({
    required this.groupId,
    required this.categoryId,
    required this.nameDe,
    required this.mode,
    required this.isCheckMode,
    required this.rawGroupNeed,
    required this.unit,
    required this.variantResults,
  });
}

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
