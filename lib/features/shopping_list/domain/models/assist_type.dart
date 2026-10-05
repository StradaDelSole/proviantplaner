/// Assistenzklassifikation für den assistierten Vorrats-Workflow (PIVOT1).
///
/// Basiert auf `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`:
/// - [needsBased]: Bedarf objektiv berechenbar (z. B. Trinkwasser, Sicherheitsreserve).
///   Provy zeigt einen Richtwert, der Nutzer entscheidet die tatsächliche Menge.
/// - [guided]: Bedarf teilweise ableitbar, stark von Gewohnheiten abhängig
///   (z. B. Brot, Milch, Butter, Toilettenpapier). Provy zeigt Plausibilitäts-/Richtwerthinweise.
/// - [preferenceBased]: Geschmack und Vorlieben (z. B. Pesto, Tofu, Snacks, Alkohol, spezielle Saucen).
///   Keine automatische Mengenempfehlung aus Crew × Tagen als Listenvorschlag.
library;

enum AssistType {
  needsBased,
  guided,
  preferenceBased;

  bool get isNeedsBased => this == AssistType.needsBased;
  bool get isGuided => this == AssistType.guided;
  bool get isPreferenceBased => this == AssistType.preferenceBased;
}

/// Deterministischer Klassifizierer für Gruppen und Varianten.
class AssistClassifier {
  /// Ermittelt die Assistenzklasse anhand der Gruppen-ID.
  static AssistType classifyGroup(String groupId) {
    // 1. Needs-based: Trinkwasser / Sicherheitsreserve
    if (groupId == 'water' || groupId.startsWith('water_')) {
      return AssistType.needsBased;
    }

    // 2. Preference-based: reine Vorlieben / Genuss / Snacks / spezielle Saucen
    const preferenceGroups = {
      'snacks',
      'sweets',
      'sauces_special',
    };
    if (preferenceGroups.contains(groupId)) {
      return AssistType.preferenceBased;
    }

    // 3. Guided: Standardvorräte, bei denen Richtwerte sinnvoll unterstützen
    return AssistType.guided;
  }

  /// Ermittelt die Assistenzklasse für eine konkrete Variante.
  static AssistType classifyVariant({required String variantId, required String groupId}) {
    if (variantId.contains('water') || groupId == 'water' || groupId.startsWith('water_')) {
      return AssistType.needsBased;
    }
    // Explizite Preference-Regressionen aus Praxisaudit (Pesto, Tofu):
    if (variantId == 'pesto' ||
        variantId.contains('pesto') ||
        variantId == 'tofu' ||
        variantId.contains('tofu')) {
      return AssistType.preferenceBased;
    }
    return classifyGroup(groupId);
  }
}
