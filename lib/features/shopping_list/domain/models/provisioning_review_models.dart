/// Domänenmodelle für die Vorratsprüfung (PIVOT2 / Issue #26).
library;

import 'catalog_models.dart';

/// Gesamtstatus der Vorratsprüfung.
enum ProvisioningReviewStatus {
  ready('ready'),
  check('check'),
  actionNeeded('action_needed');

  final String rawValue;
  const ProvisioningReviewStatus(this.rawValue);

  static ProvisioningReviewStatus fromString(String val) {
    for (final s in values) {
      if (s.rawValue == val) return s;
    }
    throw FormatException('Unbekannter ProvisioningReviewStatus: "$val"');
  }
}

/// Dringlichkeit eines Prüfbefunds.
enum ProvisioningReviewSeverity {
  info('info'),
  check('check'),
  actionNeeded('action_needed');

  final String rawValue;
  const ProvisioningReviewSeverity(this.rawValue);

  static ProvisioningReviewSeverity fromString(String val) {
    for (final s in values) {
      if (s.rawValue == val) return s;
    }
    throw FormatException('Unbekannte ProvisioningReviewSeverity: "$val"');
  }
}

/// Art / Kategorie eines Prüfbefunds.
enum ProvisioningReviewKind {
  missingBasic('missing_basic'),
  drinkingWaterCheck('drinking_water_check'),
  freshness('freshness'),
  fridgeRequirement('fridge_requirement'),
  freezerRequirement('freezer_requirement'),
  fridgeCapacity('fridge_capacity'),
  freezerCapacity('freezer_capacity'),
  incompleteCoolingAssessment('incomplete_cooling_assessment'),
  weightVolumeInfo('weight_volume_info');

  final String rawValue;
  const ProvisioningReviewKind(this.rawValue);

  static ProvisioningReviewKind fromString(String val) {
    for (final k in values) {
      if (k.rawValue == val) return k;
    }
    throw FormatException('Unbekannter ProvisioningReviewKind: "$val"');
  }
}

/// Art der Interaktion / des Absprungs bei einem Finding.
enum ProvisioningReviewActionType {
  noAction('no_action'),
  searchOrAdd('search_or_add'),
  editItem('edit_item'),
  assignShoppingStop('assign_shopping_stop');

  final String rawValue;
  const ProvisioningReviewActionType(this.rawValue);

  static ProvisioningReviewActionType fromString(String val) {
    for (final a in values) {
      if (a.rawValue == val) return a;
    }
    throw FormatException('Unbekannter ProvisioningReviewActionType: "$val"');
  }
}

/// Strukturierte Handlungsoption zu einem Finding.
class ProvisioningReviewAction {
  final ProvisioningReviewActionType type;
  final String? targetGroup;
  final List<String> targetVariants;
  final int? listItemId;

  const ProvisioningReviewAction({
    required this.type,
    this.targetGroup,
    this.targetVariants = const [],
    this.listItemId,
  });

  factory ProvisioningReviewAction.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'no_action';
    final targetGroup = json['target_group'] as String?;
    final targetVars = (json['target_variants'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    return ProvisioningReviewAction(
      type: ProvisioningReviewActionType.fromString(typeStr),
      targetGroup: targetGroup,
      targetVariants: targetVars,
      listItemId: json['list_item_id'] as int?,
    );
  }
}

/// Strikt typisierte Regel-Typen für die Konfiguration (PIVOT2).
enum ProvisioningReviewRuleType {
  shelfLifeGroupPresence('shelf_life_group_presence'),
  anyVariantPresence('any_variant_presence'),
  groupPresence('group_presence');

  final String rawValue;
  const ProvisioningReviewRuleType(this.rawValue);

  static ProvisioningReviewRuleType fromString(String val) {
    for (final t in values) {
      if (t.rawValue == val) return t;
    }
    throw FormatException('provisioning_review_v0.1.json: Unbekannter ProvisioningReviewRuleType: "$val"');
  }
}

/// Regeldefinition aus provisioning_review_v0.1.json.
class ProvisioningReviewRule {
  final String id;
  final ProvisioningReviewRuleType type;
  final ProvisioningReviewSeverity severity;
  final String? group;
  final List<String> variants;
  final String? thresholdField;
  final ProvisioningReviewAction action;

  /// Unterstützte Threshold-Feld-Referenzen in Regelkonfigurationen.
  static const Set<String> supportedThresholdFields = {
    'quantities.rounding.durable_min_shelf_life_days',
  };

  const ProvisioningReviewRule({
    required this.id,
    required this.type,
    required this.severity,
    this.group,
    this.variants = const [],
    this.thresholdField,
    required this.action,
  });

  factory ProvisioningReviewRule.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const FormatException('provisioning_review_v0.1.json: Fehlende Regel-ID');
    }
    final typeStr = json['type'] as String?;
    if (typeStr == null || typeStr.isEmpty) {
      throw FormatException('provisioning_review_v0.1.json: Fehlender Regel-Typ in $id');
    }
    final type = ProvisioningReviewRuleType.fromString(typeStr);

    final severityStr = json['severity'] as String? ?? 'check';
    final group = json['group'] as String?;
    final variants = (json['variants'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final threshold = json['threshold_field'] as String?;

    if (threshold != null && !supportedThresholdFields.contains(threshold)) {
      throw FormatException(
          'provisioning_review_v0.1.json: Unbekanntes threshold_field "$threshold" in Regel "$id"');
    }

    // Validierung der Pflichtfelder je Regeltyp
    switch (type) {
      case ProvisioningReviewRuleType.shelfLifeGroupPresence:
        if (group == null || group.isEmpty) {
          throw FormatException(
              'provisioning_review_v0.1.json: Regel "$id" vom Typ "$typeStr" erfordert ein "group"-Feld');
        }
        if (threshold == null || threshold.isEmpty) {
          throw FormatException(
              'provisioning_review_v0.1.json: Regel "$id" vom Typ "$typeStr" erfordert ein "threshold_field"-Feld');
        }
        break;
      case ProvisioningReviewRuleType.anyVariantPresence:
        if (variants.isEmpty) {
          throw FormatException(
              'provisioning_review_v0.1.json: Regel "$id" vom Typ "$typeStr" erfordert nicht-leere "variants"');
        }
        break;
      case ProvisioningReviewRuleType.groupPresence:
        if (group == null || group.isEmpty) {
          throw FormatException(
              'provisioning_review_v0.1.json: Regel "$id" vom Typ "$typeStr" erfordert ein "group"-Feld');
        }
        break;
    }

    final actionJson = json['action'] as Map<String, dynamic>?;
    if (actionJson == null) {
      throw FormatException('provisioning_review_v0.1.json: Fehlende "action" in Regel "$id"');
    }
    final action = ProvisioningReviewAction.fromJson(actionJson);

    return ProvisioningReviewRule(
      id: id,
      type: type,
      severity: ProvisioningReviewSeverity.fromString(severityStr),
      group: group,
      variants: variants,
      thresholdField: threshold,
      action: action,
    );
  }

  /// Validiert referenzierte Gruppen, Varianten, Actions und Action-Ziele gegen den Katalog.
  void validateAgainstCatalog(CatalogData catalog) {
    if (group != null) {
      final exists = catalog.groups.any((g) => g.id == group);
      if (!exists) {
        throw FormatException(
            'provisioning_review_v0.1.json: Unbekannte Gruppe "$group" in Regel "$id"');
      }
    }
    for (final v in variants) {
      final exists = catalog.variants.any((variant) => variant.id == v);
      if (!exists) {
        throw FormatException(
            'provisioning_review_v0.1.json: Unbekannte Variante "$v" in Regel "$id"');
      }
    }
    if (action.targetGroup != null) {
      final exists = catalog.groups.any((g) => g.id == action.targetGroup);
      if (!exists) {
        throw FormatException(
            'provisioning_review_v0.1.json: Unbekannte Zielgruppe "${action.targetGroup}" in Aktion von Regel "$id"');
      }
    }
    for (final tv in action.targetVariants) {
      final exists = catalog.variants.any((variant) => variant.id == tv);
      if (!exists) {
        throw FormatException(
            'provisioning_review_v0.1.json: Unbekannte Zielvariante "$tv" in Aktion von Regel "$id"');
      }
    }
  }
}

/// Konfigurationsdaten aus provisioning_review_v0.1.json.
class ProvisioningReviewConfig {
  final String version;
  final List<ProvisioningReviewRule> rules;

  const ProvisioningReviewConfig({
    required this.version,
    required this.rules,
  });

  factory ProvisioningReviewConfig.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as String? ?? '0.1';
    final rulesJson = json['rules'] as List<dynamic>?;
    if (rulesJson == null) {
      throw const FormatException('provisioning_review_v0.1.json: Fehlendes "rules"-Feld');
    }

    final rulesList = <ProvisioningReviewRule>[];
    final seenIds = <String>{};
    for (final r in rulesJson) {
      if (r is! Map<String, dynamic>) {
        throw const FormatException('provisioning_review_v0.1.json: Ungültiger Regeleintrag');
      }
      final rule = ProvisioningReviewRule.fromJson(r);
      if (seenIds.contains(rule.id)) {
        throw FormatException('provisioning_review_v0.1.json: Duplizierte Regel-ID "${rule.id}"');
      }
      seenIds.add(rule.id);
      rulesList.add(rule);
    }

    return ProvisioningReviewConfig(
      version: version,
      rules: rulesList,
    );
  }

  void validateAgainstCatalog(CatalogData catalog) {
    for (final r in rules) {
      r.validateAgainstCatalog(catalog);
    }
  }
}

/// Ein einzelner strukturierter Prüfbefund.
class ProvisioningReviewFinding {
  final String id;
  final ProvisioningReviewKind kind;
  final ProvisioningReviewSeverity severity;
  final String? ruleId;
  final String? groupId;
  final String? variantId;
  final int? listItemId;
  final double? estimatedValue;
  final double? actualValue;
  final String? unit;
  final bool hasPotableTank;
  final bool hasWatermaker;
  final int? shelfLifeDays;
  final int? horizonDays;
  final ProvisioningReviewAction action;

  const ProvisioningReviewFinding({
    required this.id,
    required this.kind,
    required this.severity,
    this.ruleId,
    this.groupId,
    this.variantId,
    this.listItemId,
    this.estimatedValue,
    this.actualValue,
    this.unit,
    this.hasPotableTank = false,
    this.hasWatermaker = false,
    this.shelfLifeDays,
    this.horizonDays,
    this.action = const ProvisioningReviewAction(type: ProvisioningReviewActionType.noAction),
  });
}

/// Ergebnis der Vorratsprüfung (rein flüchtig im Speicher).
class ProvisioningReviewResult {
  final ProvisioningReviewStatus status;
  final List<ProvisioningReviewFinding> findings;
  final double totalWeightKg;
  final double totalVolumeLiters;
  final bool hasItemsWithoutWeight;
  final bool isCoolingAssessmentComplete;

  const ProvisioningReviewResult({
    required this.status,
    required this.findings,
    required this.totalWeightKg,
    required this.totalVolumeLiters,
    required this.hasItemsWithoutWeight,
    required this.isCoolingAssessmentComplete,
  });

  /// Befunde sortiert nach Dringlichkeit (actionNeeded, check, info).
  List<ProvisioningReviewFinding> get findingsByUrgency {
    final list = List<ProvisioningReviewFinding>.from(findings);
    list.sort((a, b) {
      final aPrio = switch (a.severity) {
        ProvisioningReviewSeverity.actionNeeded => 0,
        ProvisioningReviewSeverity.check => 1,
        ProvisioningReviewSeverity.info => 2,
      };
      final bPrio = switch (b.severity) {
        ProvisioningReviewSeverity.actionNeeded => 0,
        ProvisioningReviewSeverity.check => 1,
        ProvisioningReviewSeverity.info => 2,
      };
      return aPrio.compareTo(bPrio);
    });
    return list;
  }

  /// Findet das höchstpriorisierte Finding für ein spezifisches Listenelement.
  ProvisioningReviewFinding? highestPriorityFindingForListItem(int listItemId) {
    final itemFindings = findings.where((f) => f.listItemId == listItemId).toList();
    if (itemFindings.isEmpty) return null;
    itemFindings.sort((a, b) {
      final aPrio = switch (a.severity) {
        ProvisioningReviewSeverity.actionNeeded => 0,
        ProvisioningReviewSeverity.check => 1,
        ProvisioningReviewSeverity.info => 2,
      };
      final bPrio = switch (b.severity) {
        ProvisioningReviewSeverity.actionNeeded => 0,
        ProvisioningReviewSeverity.check => 1,
        ProvisioningReviewSeverity.info => 2,
      };
      return aPrio.compareTo(bPrio);
    });
    return itemFindings.first;
  }
}

