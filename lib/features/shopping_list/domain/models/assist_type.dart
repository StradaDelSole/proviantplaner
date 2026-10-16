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
  needsBased('needs_based'),
  guided('guided'),
  preferenceBased('preference_based');

  final String rawValue;
  const AssistType(this.rawValue);

  bool get isNeedsBased => this == AssistType.needsBased;
  bool get isGuided => this == AssistType.guided;
  bool get isPreferenceBased => this == AssistType.preferenceBased;

  /// Parst einen Assist-Typ-String aus den Katalogdaten strikt gemäß Programmierregel 1.
  /// Wirft eine [FormatException] bei unbekannten Werten oder fehlerhaftem Input.
  static AssistType fromString(String val, {required String id, required String field}) {
    for (final a in values) {
      if (a.rawValue == val) return a;
    }
    throw FormatException(
      'catalog_v0.11.json: Unbekannter Assist-Typ "$val" in $field für ID "$id"',
    );
  }

  /// Alias für fromString zur konsistenten Deserialisierung.
  static AssistType fromJson(String val, {String id = 'unknown', String field = 'assist'}) {
    return fromString(val, id: id, field: field);
  }
}


