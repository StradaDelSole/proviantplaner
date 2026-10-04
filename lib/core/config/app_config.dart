/// Zentrale Konfiguration für die App (S10-T: Technische Store-Bereitschaft).
///
/// Enthält den zentralen App-Namen, Versionsinformationen und zentrale URLs
/// für Rechtliches und Kontoverwaltung gemäß PRD und Store-Anforderungen.
class AppConfig {
  AppConfig._();

  /// Zentraler Name der App (Arbeitstitel "Provy").
  /// Dies ist die einzige Stelle im Dart-Code, an der der App-Name definiert ist.
  static const String appName = 'Provy';

  /// Versionsnummer der App gemäß Semantic Versioning.
  static const String appVersion = '1.0.0';

  /// Build-Nummer der App.
  static const int buildNumber = 1;

  // --- Zentrale URLs (Web / Rechtliches / Kontoverwaltung) ---

  /// Zentrale URL zur Datenschutzerklärung (Platzhalter für v1).
  static const String privacyPolicyUrl = 'https://planer.hullq.com/datenschutz';

  /// Zentrale URL zum Impressum (Platzhalter für v1).
  static const String imprintUrl = 'https://planer.hullq.com/impressum';

  /// Zentrale URL zu den Nutzungsbedingungen / AGB (Platzhalter für v1).
  static const String termsOfServiceUrl =
      'https://planer.hullq.com/nutzungsbedingungen';

  /// Zentrale URL zur Kontolöschung im Web (Platzhalter für v1).
  static const String deleteAccountUrl =
      'https://planer.hullq.com/konto-loeschen';
}
