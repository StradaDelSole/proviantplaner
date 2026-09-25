/// Datenmodelle für den Vorratskatalog (data/catalog_v0.7.json).
/// Strikte Typisierung mit Enums gemäß GEMINI.md v0.4 Programmierregel 1.
library;

/// Rechenbasis für Bedarfsmengen aus dem Vorratskatalog.
enum CalculationBasis {
  perPersonDay('per_person_day'),
  perPersonDayRegion('per_person_day_region'),
  perPersonWeek('per_person_week'),
  perPersonBoardLunch('per_person_board_lunch'),
  perPersonBoardEvening('per_person_board_evening'),
  perAdultEvening('per_adult_evening'),
  perCrewWeek('per_crew_week'),
  perTrip('per_trip'),
  perPersonTrip('per_person_trip'),
  check('check');

  final String rawValue;
  const CalculationBasis(this.rawValue);

  static CalculationBasis fromString(String val, {required String id, required String field}) {
    for (final b in values) {
      if (b.rawValue == val) return b;
    }
    throw FormatException('catalog_v0.7.json: Unbekannte Rechenbasis "$val" in $field für ID "$id"');
  }
}

/// Aufteilungsmodus für Gruppenvarianten.
enum GroupSplit {
  equal('equal'),
  each('each');

  final String rawValue;
  const GroupSplit(this.rawValue);

  static GroupSplit fromString(String val, {required String id, required String field}) {
    for (final s in values) {
      if (s.rawValue == val) return s;
    }
    throw FormatException('catalog_v0.7.json: Unbekannter Split "$val" in $field für ID "$id"');
  }
}

/// Berechnungsmodus einer Bedarfsgruppe.
enum GroupMode {
  quantity('quantity'),
  check('check');

  final String rawValue;
  const GroupMode(this.rawValue);

  static GroupMode fromString(String val, {required String id, required String field}) {
    for (final m in values) {
      if (m.rawValue == val) return m;
    }
    throw FormatException('catalog_v0.7.json: Unbekannter Mode "$val" in $field für ID "$id"');
  }
}

/// Sichtbarkeit einer Bedarfsgruppe nach Bootstyp.
enum GroupVisibility {
  all('all'),
  owner('owner');

  final String rawValue;
  const GroupVisibility(this.rawValue);

  static GroupVisibility fromString(String val, {required String id, required String field}) {
    for (final v in values) {
      if (v.rawValue == val) return v;
    }
    throw FormatException('catalog_v0.7.json: Unbekannte Visibility "$val" in $field für ID "$id"');
  }
}

/// Konsumprofil-Zuordnung einer Bedarfsgruppe.
enum GroupProfile {
  eat('eat'),
  drink('drink'),
  none('none');

  final String rawValue;
  const GroupProfile(this.rawValue);

  static GroupProfile fromString(String val, {required String id, required String field}) {
    for (final p in values) {
      if (p.rawValue == val) return p;
    }
    throw FormatException('catalog_v0.7.json: Unbekanntes Profile "$val" in $field für ID "$id"');
  }
}

/// Zielgruppe eines Bedarfs (Crew-Filter).
enum AppliesTo {
  all('all'),
  nonVegetarian('non_vegetarian'),
  vegetarian('vegetarian'),
  adults('adults');

  final String rawValue;
  const AppliesTo(this.rawValue);

  static AppliesTo fromString(String val, {required String id, required String field}) {
    for (final a in values) {
      if (a.rawValue == val) return a;
    }
    throw FormatException('catalog_v0.7.json: Unbekanntes applies_to "$val" in $field für ID "$id"');
  }
}

/// Supermarkt-Abteilung im Vorratskatalog.
enum CatalogDepartment {
  backwaren('backwaren'),
  molkerei('molkerei'),
  obstGemuese('obst_gemuese'),
  fleischFisch('fleisch_fisch'),
  trockenware('trockenware'),
  konserven('konserven'),
  getraenke('getraenke'),
  suesswaren('suesswaren'),
  haushalt('haushalt'),
  drogerie('drogerie'),
  technik('technik'),
  apotheke('apotheke');

  final String rawValue;
  const CatalogDepartment(this.rawValue);

  static CatalogDepartment fromString(String val, {required String id, required String field}) {
    for (final d in values) {
      if (d.rawValue == val) return d;
    }
    throw FormatException('catalog_v0.7.json: Unbekannte Abteilung "$val" in $field für ID "$id"');
  }

  /// Deutscher Anzeigename der Abteilung.
  String get displayName => switch (this) {
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
}

/// Bedarfsangabe (Menge, Einheit, Rechenbasis).
class CatalogNeed {
  final double amount;
  final String unit;
  final CalculationBasis basis;

  const CatalogNeed({
    required this.amount,
    required this.unit,
    required this.basis,
  });

  factory CatalogNeed.fromJson(Map<String, dynamic> json, {required String id}) {
    final amountVal = json['amount'];
    if (amountVal == null || amountVal is! num) {
      throw FormatException('catalog_v0.7.json: Fehlende oder ungültige Need-Menge in ID "$id"');
    }
    final unitVal = json['unit'];
    if (unitVal == null || unitVal is! String || unitVal.isEmpty) {
      throw FormatException('catalog_v0.7.json: Fehlende Need-Einheit in ID "$id"');
    }
    final basisStr = json['basis'];
    if (basisStr == null || basisStr is! String) {
      throw FormatException('catalog_v0.7.json: Fehlende Need-Basis in ID "$id"');
    }

    return CatalogNeed(
      amount: amountVal.toDouble(),
      unit: unitVal,
      basis: CalculationBasis.fromString(basisStr, id: id, field: 'need.basis'),
    );
  }
}

/// Packungsinformation einer Variante.
class PackInfo {
  final double size;
  final String unit;

  const PackInfo({
    required this.size,
    required this.unit,
  });

  factory PackInfo.fromJson(Map<String, dynamic> json, {required String id}) {
    final sizeVal = json['size'];
    if (sizeVal == null || sizeVal is! num) {
      throw FormatException('catalog_v0.7.json: Ungültige Packungsgröße in Variante "$id"');
    }
    final unitVal = json['unit'];
    if (unitVal == null || unitVal is! String || unitVal.isEmpty) {
      throw FormatException('catalog_v0.7.json: Fehlende Packungseinheit in Variante "$id"');
    }

    return PackInfo(
      size: sizeVal.toDouble(),
      unit: unitVal,
    );
  }
}

/// Portionsangabe einer Variante (z. B. 130 g Pasta oder 70 g Reis).
class PortionInfo {
  final double amount;
  final String unit;

  const PortionInfo({
    required this.amount,
    required this.unit,
  });

  factory PortionInfo.fromJson(dynamic json, {required String id}) {
    if (json is List && json.length >= 2 && json[0] is num && json[1] is String) {
      return PortionInfo(
        amount: (json[0] as num).toDouble(),
        unit: json[1] as String,
      );
    }
    throw FormatException('catalog_v0.7.json: Ungültige Portionsangabe in Variante "$id": $json');
  }
}

/// Bedarfsgruppe im Katalog.
class CatalogGroup {
  final String id;
  final String category;
  final String nameDe;
  final CatalogNeed? need;
  final GroupProfile profile;
  final AppliesTo appliesTo;
  final GroupSplit split;
  final GroupVisibility visibility;
  final GroupMode mode;
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
    final id = json['id'] as String? ?? '';
    if (id.isEmpty) {
      throw const FormatException('catalog_v0.7.json: Fehlende ID in Gruppe');
    }

    return CatalogGroup(
      id: id,
      category: json['category'] as String? ?? '',
      nameDe: json['name_de'] as String? ?? '',
      need: json['need'] != null
          ? CatalogNeed.fromJson(json['need'] as Map<String, dynamic>, id: id)
          : null,
      profile: GroupProfile.fromString(json['profile'] as String? ?? 'none', id: id, field: 'profile'),
      appliesTo: AppliesTo.fromString(json['applies_to'] as String? ?? 'all', id: id, field: 'applies_to'),
      split: GroupSplit.fromString(json['split'] as String? ?? 'equal', id: id, field: 'split'),
      visibility: GroupVisibility.fromString(json['visibility'] as String? ?? 'all', id: id, field: 'visibility'),
      mode: GroupMode.fromString(json['mode'] as String? ?? 'quantity', id: id, field: 'mode'),
      source: json['source'] as String?,
      note: json['note'] as String?,
    );
  }
}

/// Konkrete Produktvariante einer Bedarfsgruppe.
class CatalogVariant {
  final String id;
  final String group;
  final String nameDe;
  final PackInfo pack;
  final int shelfLifeDays;
  final bool buyFreshUnderway;
  final CatalogDepartment department;
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
    final id = json['id'] as String? ?? '';
    if (id.isEmpty) {
      throw const FormatException('catalog_v0.7.json: Fehlende ID in Variante');
    }
    final packJson = json['pack'];
    if (packJson == null || packJson is! Map<String, dynamic>) {
      throw FormatException('catalog_v0.7.json: Fehlendes pack-Objekt in Variante "$id"');
    }
    final deptStr = json['department'] as String? ?? '';

    return CatalogVariant(
      id: id,
      group: json['group'] as String? ?? '',
      nameDe: json['name_de'] as String? ?? '',
      pack: PackInfo.fromJson(packJson, id: id),
      shelfLifeDays: json['shelf_life_days'] as int? ?? 14,
      buyFreshUnderway: json['buy_fresh_underway'] as bool? ?? false,
      department: CatalogDepartment.fromString(deptStr, id: id, field: 'department'),
      defaultSelected: json['default_selected'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      storage: (json['storage'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      note: json['note'] as String?,
      portion: json['portion'] != null ? PortionInfo.fromJson(json['portion'], id: id) : null,
      need: json['need'] != null ? CatalogNeed.fromJson(json['need'] as Map<String, dynamic>, id: id) : null,
    );
  }
}

/// Kategorie im Vorratskatalog.
class CatalogCategory {
  final String id;
  final String nameDe;

  const CatalogCategory({
    required this.id,
    required this.nameDe,
  });

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      id: json['id'] as String? ?? '',
      nameDe: json['name_de'] as String? ?? '',
    );
  }
}

/// Gesamter eingelesener Vorratskatalog (catalog_v0.7.json).
class CatalogData {
  final String version;
  final List<CatalogCategory> categories;
  final List<CatalogGroup> groups;
  final List<CatalogVariant> variants;
  final Map<String, String> storageHints;

  const CatalogData({
    required this.version,
    required this.categories,
    required this.groups,
    required this.variants,
    required this.storageHints,
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

    final hints = <String, String>{};
    if (json['storage_hints'] is Map) {
      (json['storage_hints'] as Map<String, dynamic>).forEach((k, v) {
        hints[k] = v.toString();
      });
    }

    return CatalogData(
      version: json['version'] as String? ?? '0.7',
      categories: categoriesList,
      groups: groupsList,
      variants: variantsList,
      storageHints: hints,
    );
  }

  CatalogGroup? getGroup(String groupId) {
    for (final g in groups) {
      if (g.id == groupId) return g;
    }
    return null;
  }

  List<CatalogVariant> getVariantsForGroup(String groupId) =>
      variants.where((v) => v.group == groupId).toList();

  CatalogVariant? getVariant(String variantId) {
    for (final v in variants) {
      if (v.id == variantId) return v;
    }
    return null;
  }
}