/// Datenmodelle für den Vorratskatalog (docs/KATALOG_v0.6.md / data/catalog_v0.6.json).
library;

class CatalogNeed {
  final double amount;
  final String unit;
  final String basis;

  const CatalogNeed({
    required this.amount,
    required this.unit,
    required this.basis,
  });

  factory CatalogNeed.fromJson(Map<String, dynamic> json) {
    return CatalogNeed(
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String? ?? '',
      basis: json['basis'] as String? ?? 'per_person_day',
    );
  }
}

class CatalogGroup {
  final String id;
  final String category;
  final String nameDe;
  final CatalogNeed? need;
  final String profile; // eat, drink, none
  final String appliesTo; // all, meat_eaters, alcohol_drinkers, adults
  final String split; // equal, each
  final String visibility; // all, owner
  final String mode; // quantity, check
  final String? source;
  final String? note;

  const CatalogGroup({
    required this.id,
    required this.category,
    required this.nameDe,
    this.need,
    required this.profile,
    required this.appliesTo,
    required this.split,
    required this.visibility,
    required this.mode,
    this.source,
    this.note,
  });

  factory CatalogGroup.fromJson(Map<String, dynamic> json) {
    return CatalogGroup(
      id: json['id'] as String,
      category: json['category'] as String,
      nameDe: json['name_de'] as String,
      need: json['need'] != null
          ? CatalogNeed.fromJson(json['need'] as Map<String, dynamic>)
          : null,
      profile: json['profile'] as String? ?? 'none',
      appliesTo: json['applies_to'] as String? ?? 'all',
      split: json['split'] as String? ?? 'equal',
      visibility: json['visibility'] as String? ?? 'all',
      mode: json['mode'] as String? ?? 'quantity',
      source: json['source'] as String?,
      note: json['note'] as String?,
    );
  }
}

class PackInfo {
  final double size;
  final String unit;

  const PackInfo({
    required this.size,
    required this.unit,
  });

  factory PackInfo.fromJson(Map<String, dynamic> json) {
    return PackInfo(
      size: (json['size'] as num).toDouble(),
      unit: json['unit'] as String? ?? '',
    );
  }
}

class PortionInfo {
  final double amount;
  final String unit;

  const PortionInfo({
    required this.amount,
    required this.unit,
  });

  factory PortionInfo.fromJson(dynamic json) {
    if (json is List && json.length >= 2) {
      return PortionInfo(
        amount: (json[0] as num).toDouble(),
        unit: json[1] as String? ?? 'g',
      );
    }
    return const PortionInfo(amount: 100, unit: 'g');
  }
}

class CatalogVariant {
  final String id;
  final String group;
  final String nameDe;
  final PackInfo pack;
  final int shelfLifeDays;
  final bool buyFreshUnderway;
  final String department;
  final bool defaultSelected;
  final List<String> tags;
  final List<String> storage;
  final String? note;
  final PortionInfo? portion;
  final CatalogNeed? need;

  const CatalogVariant({
    required this.id,
    required this.group,
    required this.nameDe,
    required this.pack,
    required this.shelfLifeDays,
    required this.buyFreshUnderway,
    required this.department,
    required this.defaultSelected,
    this.tags = const [],
    this.storage = const [],
    this.note,
    this.portion,
    this.need,
  });

  factory CatalogVariant.fromJson(Map<String, dynamic> json) {
    return CatalogVariant(
      id: json['id'] as String,
      group: json['group'] as String,
      nameDe: json['name_de'] as String,
      pack: PackInfo.fromJson(json['pack'] as Map<String, dynamic>),
      shelfLifeDays: json['shelf_life_days'] as int? ?? 14,
      buyFreshUnderway: json['buy_fresh_underway'] as bool? ?? false,
      department: json['department'] as String? ?? '',
      defaultSelected: json['default_selected'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      storage: (json['storage'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      note: json['note'] as String?,
      portion: json['portion'] != null ? PortionInfo.fromJson(json['portion']) : null,
      need: json['need'] != null ? CatalogNeed.fromJson(json['need'] as Map<String, dynamic>) : null,
    );
  }
}

class CatalogCategory {
  final String id;
  final String nameDe;

  const CatalogCategory({
    required this.id,
    required this.nameDe,
  });

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      id: json['id'] as String,
      nameDe: json['name_de'] as String,
    );
  }
}

class CatalogData {
  final String version;
  final List<CatalogCategory> categories;
  final List<CatalogGroup> groups;
  final List<CatalogVariant> variants;

  const CatalogData({
    required this.version,
    required this.categories,
    required this.groups,
    required this.variants,
  });

  factory CatalogData.fromJson(Map<String, dynamic> json) {
    final categoriesList = (json['categories'] as List<dynamic>?)
            ?.map((c) => CatalogCategory.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];
    final groupsList = (json['groups'] as List<dynamic>?)
            ?.map((g) => CatalogGroup.fromJson(g as Map<String, dynamic>))
            .toList() ??
        [];
    final variantsList = (json['variants'] as List<dynamic>?)
            ?.map((v) => CatalogVariant.fromJson(v as Map<String, dynamic>))
            .toList() ??
        [];

    return CatalogData(
      version: json['version'] as String? ?? '0.6',
      categories: categoriesList,
      groups: groupsList,
      variants: variantsList,
    );
  }

  CatalogGroup? getGroup(String groupId) =>
      groups.cast<CatalogGroup?>().firstWhere((g) => g?.id == groupId, orElse: () => null);

  List<CatalogVariant> getVariantsForGroup(String groupId) =>
      variants.where((v) => v.group == groupId).toList();

  CatalogVariant? getVariant(String variantId) =>
      variants.cast<CatalogVariant?>().firstWhere((v) => v?.id == variantId, orElse: () => null);
}