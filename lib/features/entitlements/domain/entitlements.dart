/// Reine Dart-Freischaltungslogik (Slice S6) gemäß PRD v0.16 Abschnitt 2.
library;

/// Die drei Freischaltungsstufen laut PRD.
enum EntitlementLevel {
  trial, // Probetörn (erster Törn, ohne Konto)
  member, // Mitglied (mit HullQ-Login)
  pro, // Pro (Abo)
}

/// Jede Zeile der Funktionstabelle im PRD v0.16 als typisiertes Feature (Programmierregel 1).
enum AppFeature {
  unlimitedTrips, // Anzahl Törns
  unlimitedCrew, // Crewgröße
  provisionsList, // Vorratsliste aus dem Katalog
  consumptionProfiles, // Konsumprofile pro Person (Essen, Trinken)
  overrideQuantities, // Mengen überschreiben, Gesamtzahl eingeben, eigene Positionen
  departmentView, // Einkaufsliste nach Supermarkt-Abteilung
  storageChecklist, // Einlagerungs-Checkliste
  dietaryPreferences, // Essgewohnheiten der Crew (vegetarisch, keine Nuss …)
  kittySettlement, // Bordkasse: gemeinsame Kasse oder Einzelabrechnung, Kategorien, Skipper frei, Überweisungs-QR und Zahlungslinks
  exportPdfShare, // Export Einkaufsliste und Abrechnung (PDF, Teilen)
  cloudBackupAndSync, // Sicherung, Wiederherstellung, mehrere Geräte
  shareWithCrew, // Teilen mit der Crew (ab v1.1)
  mealPlan, // Menüplan, optional (ab v1.1)
  multipleCurrencies, // Mehrere Währungen in der Bordkasse
  customRecipes, // Eigene Rezepte und Mengen speichern
  templates, // Vorlagen aus früheren Törns
}

/// Zeitlich oder törnbezogen begrenzte Freischaltung (z. B. Törn-Code für v1.1).
class TripCodePass {
  final String code;
  final int? tripId;
  final DateTime? validUntil;
  final EntitlementLevel grantedLevel;

  const TripCodePass({
    required this.code,
    this.tripId,
    this.validUntil,
    this.grantedLevel = EntitlementLevel.member,
  });

  /// Prüft, ob der Pass zum aktuellen Zeitpunkt gültig ist.
  bool isValidAt(DateTime now) {
    if (validUntil != null && now.isAfter(validUntil!)) {
      return false;
    }
    return true;
  }

  /// Prüft, ob der Pass für einen bestimmten Törn gültig ist.
  bool appliesToTrip(int targetTripId) {
    if (tripId != null && tripId != targetTripId) {
      return false;
    }
    return true;
  }
}

/// Verwaltet die Zugriffsrechte und Freischaltungsregeln ohne Flutter-Abhängigkeit.
class EntitlementsManager {
  const EntitlementsManager();

  /// Prüft, ob ein Feature unter den gegebenen Bedingungen freigeschaltet ist.
  bool canAccessFeature({
    required AppFeature feature,
    required EntitlementLevel level,
    int currentTripCount = 0,
    int? targetTripId,
    TripCodePass? tripPass,
    DateTime? now,
  }) {
    final effectiveLevel = _resolveEffectiveLevel(
      level: level,
      targetTripId: targetTripId,
      tripPass: tripPass,
      now: now ?? DateTime.now(),
    );

    return switch (effectiveLevel) {
      EntitlementLevel.pro => true,
      EntitlementLevel.member => _checkMemberFeature(feature),
      EntitlementLevel.trial => _checkTrialFeature(feature, currentTripCount),
    };
  }

  /// Prüft, ob ein weiterer Törn angelegt werden darf.
  bool canCreateTrip({
    required EntitlementLevel level,
    required int currentTripCount,
    TripCodePass? tripPass,
    DateTime? now,
  }) {
    if (tripPass != null && tripPass.isValidAt(now ?? DateTime.now())) {
      return true;
    }
    if (level == EntitlementLevel.pro || level == EntitlementLevel.member) {
      return true;
    }
    // Probetörn: genau 1 Törn erlaubt
    return currentTripCount < 1;
  }

  EntitlementLevel _resolveEffectiveLevel({
    required EntitlementLevel level,
    int? targetTripId,
    TripCodePass? tripPass,
    required DateTime now,
  }) {
    if (tripPass != null && tripPass.isValidAt(now)) {
      if (targetTripId == null || tripPass.appliesToTrip(targetTripId)) {
        if (tripPass.grantedLevel.index > level.index) {
          return tripPass.grantedLevel;
        }
      }
    }
    return level;
  }

  bool _checkMemberFeature(AppFeature feature) {
    return switch (feature) {
      AppFeature.unlimitedTrips => true,
      AppFeature.unlimitedCrew => true,
      AppFeature.provisionsList => true,
      AppFeature.consumptionProfiles => true,
      AppFeature.overrideQuantities => true,
      AppFeature.departmentView => true,
      AppFeature.storageChecklist => true,
      AppFeature.dietaryPreferences => true,
      AppFeature.kittySettlement => true,
      AppFeature.exportPdfShare => true,
      AppFeature.cloudBackupAndSync => true,
      AppFeature.shareWithCrew => true,
      AppFeature.mealPlan => true,
      AppFeature.multipleCurrencies => false, // nein im PRD
      AppFeature.customRecipes => false, // nein im PRD
      AppFeature.templates => false, // nein im PRD
    };
  }

  bool _checkTrialFeature(AppFeature feature, int currentTripCount) {
    return switch (feature) {
      AppFeature.unlimitedTrips => currentTripCount == 0,
      AppFeature.unlimitedCrew => true,
      AppFeature.provisionsList => true,
      AppFeature.consumptionProfiles => true,
      AppFeature.overrideQuantities => true,
      AppFeature.departmentView => true,
      AppFeature.storageChecklist => true,
      AppFeature.dietaryPreferences => true,
      AppFeature.kittySettlement => true,
      AppFeature.exportPdfShare => true,
      AppFeature.cloudBackupAndSync => false, // nein (kein Konto) im PRD
      AppFeature.shareWithCrew => false, // nein im PRD
      AppFeature.mealPlan => true, // ja im PRD
      AppFeature.multipleCurrencies => true, // ja im PRD
      AppFeature.customRecipes => true, // ja im PRD
      AppFeature.templates => false, // entfällt im PRD
    };
  }
}
