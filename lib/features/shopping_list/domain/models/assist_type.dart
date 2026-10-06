/// Assistenzklassifikation für den assistierten Vorrats-Workflow (PIVOT1).
///
/// Basiert auf `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md` Abschnitt 4:
/// - [needsBased]: Bedarf objektiv berechenbar (z. B. Trinkwasser, Sicherheitsreserve).
///   Provy zeigt einen Richtwert, der Nutzer entscheidet die tatsächliche Menge.
/// - [guided]: Bedarf teilweise ableitbar, stark von Gewohnheiten abhängig
///   (z. B. Brot, Milch, Butter, Toilettenpapier, Bier/Wein mit Crew-Trinkprofil).
///   Provy zeigt Plausibilitäts-/Richtwerthinweise, keine automatische Aufnahme.
/// - [preferenceBased]: Geschmack und Vorlieben (z. B. Pesto, Tofu, salzige Snacks,
///   Süßigkeiten, Aufstriche, spezielle Saucen, Spezialkäse, Spirituosen).
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

/// Deterministischer Klassifizierer für Gruppen und Varianten anhand des Katalogs.
class AssistClassifier {
  /// Kanonische Gruppen-IDs aus `data/catalog_v0.10.json`, die reine Präferenzartikel darstellen.
  static const Set<String> preferenceGroupIds = {
    'savory_snacks', // Chips, Nüsse, Salzstangen, Cracker
    'sweets',        // Schokolade, Kekse, Gummibärchen, Müsliriegel
    'spread_sweet',  // Marmelade, Honig, Nutella, Erdnussbutter
    'spread_savory', // Frischkäse, Hummus, Streichwurst
    'spirits',       // Rum, Gin, Aperol, lokale Spezialitäten (Genussmittel)
  };

  /// Kanonische Varianten-IDs aus `data/catalog_v0.10.json`, die innerhalb sonst geführter Gruppen
  /// (z. B. condiments, sauces_pasta, cheese, veg_protein) reine Präferenzartikel darstellen.
  static const Set<String> preferenceVariantIds = {
    'pesto',        // sauces_pasta: Pesto
    'sauce_jar',    // sauces_pasta: Fertigsauce im Glas
    'tofu',         // veg_protein: Tofu
    'bbq_sauce',    // condiments: Grillsauce
    'sweet_chili',  // condiments: Sweet-Chili-Sauce
    'tabasco',      // condiments: Tabasco / scharfe Sauce
    'soy_sauce',    // condiments: Sojasauce
    'brie',         // cheese: Brie / Camembert
    'feta',         // cheese: Feta
    'mozzarella',   // cheese: Mozzarella
    'parmesan',     // cheese: Parmesan / Hartkäse am Stück
  };

  /// Ermittelt die Assistenzklasse anhand der Gruppen-ID.
  static AssistType classifyGroup(String groupId) {
    // 1. Needs-based: Trinkwasser / Sicherheitsreserve
    if (groupId == 'water' || groupId.startsWith('water_')) {
      return AssistType.needsBased;
    }

    // 2. Preference-based: reine Vorlieben / Genuss / Snacks / Aufstriche / Spirituosen
    if (preferenceGroupIds.contains(groupId)) {
      return AssistType.preferenceBased;
    }

    // 3. Guided: Standardvorräte, Grundnahrungsmittel und profilgestützte Getränke (Bier/Wein),
    // bei denen Richtwerte sinnvoll unterstützen.
    return AssistType.guided;
  }

  /// Ermittelt die Assistenzklasse für eine konkrete Variante.
  static AssistType classifyVariant({required String variantId, required String groupId}) {
    if (variantId.contains('water') || groupId == 'water' || groupId.startsWith('water_')) {
      return AssistType.needsBased;
    }
    if (preferenceVariantIds.contains(variantId) ||
        variantId.contains('pesto') ||
        variantId.contains('tofu')) {
      return AssistType.preferenceBased;
    }
    return classifyGroup(groupId);
  }
}

