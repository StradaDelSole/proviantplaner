/// Zentrale Feature-Flags für v1 vs. spätere Versionen (GEMINI.md Regel 10).
library;

/// Verwaltet Feature-Schalter für Funktionen künftiger Versionen.
///
/// Nach GEMINI.md Regel 10 dürfen Funktionen aus späteren Versionen
/// nicht sichtbar in v1 gebaut werden, außer hinter einem Feature-Schalter,
/// der in v1 standardmäßig AUS (`false`) ist.
class FeatureFlags {
  FeatureFlags._();

  /// Schalter für die Törn-Code-Einlösung in der Benutzeroberfläche (geplant für v1.1).
  /// In Version 1.0 standardmäßig deaktiviert (`false`).
  static bool enableTripCodePasses = false;
}
