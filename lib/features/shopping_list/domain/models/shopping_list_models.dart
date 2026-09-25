/// Domänen- und UI-Modelle für die Vorrats- und Einkaufsliste (Slice S4).
library;

import 'package:flutter/material.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'catalog_models.dart';

/// Deckungsstatus einer Bedarfsgruppe in der Planungsansicht.
enum GroupCoverageStatus {
  covered,
  scarce,
  noneSelected,
  checklist,
}

/// Repräsentiert ein aggregiertes Element in der Vorratsliste.
class ShoppingListItemView {
  final ListItem item;
  final CatalogVariant? variant;
  final String id;
  final String name;
  final String unit;
  final CatalogDepartment department;
  final String categoryId;
  final int calculatedPackages;
  final int? overriddenPackages;
  final double calculatedQuantity;
  final double customPackageSize;
  final bool isSelected;
  final double share;
  final bool isCustom;
  final int shelfLifeDays;
  final List<String> storageHints;
  final Map<int, ListItemAllocation> allocationsByStop;

  const ShoppingListItemView({
    required this.item,
    required this.variant,
    required this.id,
    required this.name,
    required this.unit,
    required this.department,
    required this.categoryId,
    required this.calculatedPackages,
    required this.overriddenPackages,
    required this.calculatedQuantity,
    required this.customPackageSize,
    required this.isSelected,
    required this.share,
    required this.isCustom,
    required this.shelfLifeDays,
    required this.storageHints,
    required this.allocationsByStop,
  });

  /// Effektive Packungsanzahl (überschrieben oder berechnet).
  int get effectivePackages => overriddenPackages ?? calculatedPackages;

  /// Gibt an, ob der Benutzer die Packungszahl manuell überschrieben hat.
  bool get isOverridden => overriddenPackages != null;

  /// Effektive Packungsgröße (benutzerdefiniert oder Standard).
  double get effectivePackSize =>
      item.customPackageSize ?? (variant?.pack.size ?? customPackageSize);

  /// Gibt an, ob der Artikel gekühlt gelagert werden muss.
  bool get isCooled =>
      storageHints.contains('cool_first') || (shelfLifeDays > 0 && shelfLifeDays <= 3);

  /// Prüft, ob der Artikel für einen Stopp abgehakt (gekauft) ist.
  bool isBoughtAtStop(int stopId) =>
      allocationsByStop[stopId]?.isBought ?? false;

  /// Ermittelt die zugeordnete Packungsmenge für einen Stopp.
  int packagesAtStop(int stopId, {required bool isFirstStop, required int totalOtherAllocated}) {
    final alloc = allocationsByStop[stopId];
    if (alloc != null) return alloc.allocatedPackages;
    if (isFirstStop) {
      final remaining = effectivePackages - totalOtherAllocated;
      return remaining < 0 ? 0 : remaining;
    }
    return 0;
  }

  /// Formatierte Anzeige der Packungsangabe, z. B. "3 × 750 g" oder "2 × 1 l".
  String get packDisplay {
    final size = effectivePackSize;
    final sizeFormatted = (size % 1 == 0) ? size.toInt().toString() : size.toStringAsFixed(1);
    final packUnit = variant?.pack.unit ?? unit;
    return '$effectivePackages × $sizeFormatted $packUnit';
  }

  /// Formatierte Anzeige des berechneten Bedarfs inklusive Reserve.
  String get demandDisplay {
    if (isCustom) return 'Eigene Position';
    final qty = calculatedQuantity;
    final qtyFormatted = (qty % 1 == 0) ? qty.toInt().toString() : qty.toStringAsFixed(1);
    return 'Bedarf ca. $qtyFormatted $unit';
  }
}

/// Gruppe in der Sicht "Planen".
class ShoppingListGroupView {
  final CatalogGroup group;
  final List<ShoppingListItemView> variants;

  const ShoppingListGroupView({
    required this.group,
    required this.variants,
  });

  /// Gesamtanzahl der Packungen aller gewählten Varianten.
  int get totalPackages {
    return variants
        .where((v) => v.isSelected)
        .fold<int>(0, (sum, v) => sum + v.effectivePackages);
  }

  /// Deckungsstatus der Gruppe.
  GroupCoverageStatus get coverageStatus {
    if (group.mode == GroupMode.check) {
      return GroupCoverageStatus.checklist;
    }
    final selected = variants.where((v) => v.isSelected).toList();
    if (selected.isEmpty) return GroupCoverageStatus.noneSelected;
    if (totalPackages >= 1) return GroupCoverageStatus.covered;
    return GroupCoverageStatus.scarce;
  }

  /// Anzahl geprüfter Varianten bei Prüflisten.
  int get checkedCount =>
      variants.where((v) => v.isSelected).length;

  /// Nur für Bootseigner relevant (beim Charter standardmäßig eingeklappt).
  bool get isOwnerOnly => group.visibility == GroupVisibility.owner;
}

/// Kategorie in der Sicht "Planen".
class ShoppingListCategoryView {
  final CatalogCategory category;
  final List<ShoppingListGroupView> groups;

  const ShoppingListCategoryView({
    required this.category,
    required this.groups,
  });

  /// Anzahl noch nicht gedeckter Gruppen.
  int get openCount {
    return groups.where((g) {
      if (g.group.mode == GroupMode.check) {
        return g.checkedCount < g.variants.length;
      }
      return g.coverageStatus != GroupCoverageStatus.covered;
    }).length;
  }
}

/// Supermarkt-Abteilung in der Sicht "Einkaufen".
class ShoppingListDepartmentView {
  final CatalogDepartment department;
  final List<ShoppingListItemView> items;

  const ShoppingListDepartmentView({
    required this.department,
    required this.items,
  });

  /// Name der Abteilung in deutscher Sprache.
  String get displayName => switch (department) {
        CatalogDepartment.obstGemuese => 'Obst und Gemüse',
        CatalogDepartment.backwaren => 'Backwaren',
        CatalogDepartment.molkerei => 'Molkerei und Kühlregal',
        CatalogDepartment.fleischFisch => 'Fleisch und Fisch',
        CatalogDepartment.trockenware => 'Trockenware',
        CatalogDepartment.konserven => 'Konserven',
        CatalogDepartment.suesswaren => 'Süßwaren',
        CatalogDepartment.getraenke => 'Getränke',
        CatalogDepartment.drogerie => 'Drogerie',
        CatalogDepartment.haushalt => 'Haushalt',
        CatalogDepartment.apotheke => 'Apotheke / Drogerie',
        CatalogDepartment.technik => 'Technik / Bootszubehör',
      };

  /// Icon der Abteilung gemäß Design-Brief Abschnitt 2.
  IconData get icon => switch (department) {
        CatalogDepartment.obstGemuese => Icons.eco_outlined,
        CatalogDepartment.backwaren => Icons.bakery_dining_outlined,
        CatalogDepartment.molkerei => Icons.egg_outlined,
        CatalogDepartment.fleischFisch => Icons.set_meal_outlined,
        CatalogDepartment.trockenware => Icons.grain_outlined,
        CatalogDepartment.konserven => Icons.soup_kitchen_outlined,
        CatalogDepartment.suesswaren => Icons.cookie_outlined,
        CatalogDepartment.getraenke => Icons.local_drink_outlined,
        CatalogDepartment.haushalt => Icons.cleaning_services_outlined,
        CatalogDepartment.drogerie => Icons.soap_outlined,
        CatalogDepartment.apotheke => Icons.medical_services_outlined,
        CatalogDepartment.technik => Icons.build_outlined,
      };
}
