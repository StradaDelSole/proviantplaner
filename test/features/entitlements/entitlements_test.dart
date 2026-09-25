/// Unit-Tests für Freischaltungslogik und Berechtigungen (Slice S6).
/// Deckt jede Zeile der Funktionstabelle im PRD v0.16 Abschnitt 2 ab.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/features/entitlements/domain/entitlements.dart';

void main() {
  const manager = EntitlementsManager();

  group('Slice S6: Vollständige Prüfung der PRD-Funktionstabelle (16 Zeilen)', () {
    // Zeile 1: Anzahl Törns
    test('Zeile 1: Anzahl Törns – Probetörn 1, Mitglied unbegrenzt, Pro unbegrenzt', () {
      // Probetörn erster Törn erlaubt
      expect(manager.canCreateTrip(level: EntitlementLevel.trial, currentTripCount: 0), isTrue);
      // Probetörn zweiter Törn gesperrt (muss Mitglied werden)
      expect(manager.canCreateTrip(level: EntitlementLevel.trial, currentTripCount: 1), isFalse);

      // Mitglied unbegrenzt viele Törns
      expect(manager.canCreateTrip(level: EntitlementLevel.member, currentTripCount: 0), isTrue);
      expect(manager.canCreateTrip(level: EntitlementLevel.member, currentTripCount: 5), isTrue);

      // Pro unbegrenzt viele Törns
      expect(manager.canCreateTrip(level: EntitlementLevel.pro, currentTripCount: 0), isTrue);
      expect(manager.canCreateTrip(level: EntitlementLevel.pro, currentTripCount: 10), isTrue);
    });

    // Zeile 2: Crewgröße
    test('Zeile 2: Crewgröße – Probetörn unbegrenzt, Mitglied unbegrenzt, Pro unbegrenzt', () {
      for (final lvl in EntitlementLevel.values) {
        expect(manager.canAccessFeature(feature: AppFeature.unlimitedCrew, level: lvl), isTrue);
      }
    });

    // Zeile 3: Vorratsliste aus dem Katalog
    test('Zeile 3: Vorratsliste aus dem Katalog – ja bei allen', () {
      for (final lvl in EntitlementLevel.values) {
        expect(manager.canAccessFeature(feature: AppFeature.provisionsList, level: lvl), isTrue);
      }
    });

    // Zeile 4: Konsumprofile pro Person
    test('Zeile 4: Konsumprofile pro Person (Essen, Trinken) – ja bei allen', () {
      for (final lvl in EntitlementLevel.values) {
        expect(manager.canAccessFeature(feature: AppFeature.consumptionProfiles, level: lvl), isTrue);
      }
    });

    // Zeile 5: Mengen überschreiben, Gesamtzahl eingeben, eigene Positionen
    test('Zeile 5: Mengen überschreiben, Gesamtzahl, eigene Positionen – ja bei allen', () {
      for (final lvl in EntitlementLevel.values) {
        expect(manager.canAccessFeature(feature: AppFeature.overrideQuantities, level: lvl), isTrue);
      }
    });

    // Zeile 6: Einkaufsliste nach Supermarkt-Abteilung
    test('Zeile 6: Einkaufsliste nach Supermarkt-Abteilung – ja bei allen', () {
      for (final lvl in EntitlementLevel.values) {
        expect(manager.canAccessFeature(feature: AppFeature.departmentView, level: lvl), isTrue);
      }
    });

    // Zeile 7: Einlagerungs-Checkliste
    test('Zeile 7: Einlagerungs-Checkliste – ja bei allen', () {
      for (final lvl in EntitlementLevel.values) {
        expect(manager.canAccessFeature(feature: AppFeature.storageChecklist, level: lvl), isTrue);
      }
    });

    // Zeile 8: Essgewohnheiten der Crew (vegetarisch, keine Nuss …)
    test('Zeile 8: Essgewohnheiten der Crew – ja bei allen', () {
      for (final lvl in EntitlementLevel.values) {
        expect(manager.canAccessFeature(feature: AppFeature.dietaryPreferences, level: lvl), isTrue);
      }
    });

    // Zeile 9: Bordkasse: gemeinsame Kasse oder Einzelabrechnung, Kategorien, Skipper frei, Überweisungs-QR
    test('Zeile 9: Bordkasse und Kostenteilung – ja bei allen', () {
      for (final lvl in EntitlementLevel.values) {
        expect(manager.canAccessFeature(feature: AppFeature.kittySettlement, level: lvl), isTrue);
      }
    });

    // Zeile 10: Export Einkaufsliste und Abrechnung (PDF, Teilen)
    test('Zeile 10: Export Einkaufsliste und Abrechnung – ja bei allen', () {
      for (final lvl in EntitlementLevel.values) {
        expect(manager.canAccessFeature(feature: AppFeature.exportPdfShare, level: lvl), isTrue);
      }
    });

    // Zeile 11: Sicherung, Wiederherstellung, mehrere Geräte
    test('Zeile 11: Sicherung, Wiederherstellung, mehrere Geräte – nein (trial), ja (member, pro)', () {
      expect(manager.canAccessFeature(feature: AppFeature.cloudBackupAndSync, level: EntitlementLevel.trial), isFalse);
      expect(manager.canAccessFeature(feature: AppFeature.cloudBackupAndSync, level: EntitlementLevel.member), isTrue);
      expect(manager.canAccessFeature(feature: AppFeature.cloudBackupAndSync, level: EntitlementLevel.pro), isTrue);
    });

    // Zeile 12: Teilen mit der Crew (ab v1.1)
    test('Zeile 12: Teilen mit der Crew – nein (trial), ja (member, pro)', () {
      expect(manager.canAccessFeature(feature: AppFeature.shareWithCrew, level: EntitlementLevel.trial), isFalse);
      expect(manager.canAccessFeature(feature: AppFeature.shareWithCrew, level: EntitlementLevel.member), isTrue);
      expect(manager.canAccessFeature(feature: AppFeature.shareWithCrew, level: EntitlementLevel.pro), isTrue);
    });

    // Zeile 13: Menüplan, optional (ab v1.1)
    test('Zeile 13: Menüplan – ja bei allen', () {
      for (final lvl in EntitlementLevel.values) {
        expect(manager.canAccessFeature(feature: AppFeature.mealPlan, level: lvl), isTrue);
      }
    });

    // Zeile 14: Mehrere Währungen in der Bordkasse
    test('Zeile 14: Mehrere Währungen in der Bordkasse – ja (trial), nein (member), ja (pro)', () {
      expect(manager.canAccessFeature(feature: AppFeature.multipleCurrencies, level: EntitlementLevel.trial), isTrue);
      expect(manager.canAccessFeature(feature: AppFeature.multipleCurrencies, level: EntitlementLevel.member), isFalse);
      expect(manager.canAccessFeature(feature: AppFeature.multipleCurrencies, level: EntitlementLevel.pro), isTrue);
    });

    // Zeile 15: Eigene Rezepte und Mengen speichern
    test('Zeile 15: Eigene Rezepte und Mengen speichern – ja (trial), nein (member), ja (pro)', () {
      expect(manager.canAccessFeature(feature: AppFeature.customRecipes, level: EntitlementLevel.trial), isTrue);
      expect(manager.canAccessFeature(feature: AppFeature.customRecipes, level: EntitlementLevel.member), isFalse);
      expect(manager.canAccessFeature(feature: AppFeature.customRecipes, level: EntitlementLevel.pro), isTrue);
    });

    // Zeile 16: Vorlagen aus früheren Törns
    test('Zeile 16: Vorlagen aus früheren Törns – entfällt (trial), nein (member), ja (pro)', () {
      expect(manager.canAccessFeature(feature: AppFeature.templates, level: EntitlementLevel.trial), isFalse);
      expect(manager.canAccessFeature(feature: AppFeature.templates, level: EntitlementLevel.member), isFalse);
      expect(manager.canAccessFeature(feature: AppFeature.templates, level: EntitlementLevel.pro), isTrue);
    });
  });

  group('Slice S6: Zukunftssicherheit – Törn-Codes und zeitlich begrenzte Pässe (v1.1)', () {
    test('Gültiger Törn-Pass erlaubt Erstellung eines zweiten Törns auch ohne HullQ-Login', () {
      final now = DateTime(2026, 9, 25, 12, 0);
      final pass = TripCodePass(
        code: 'TOERN-2026',
        validUntil: now.add(const Duration(days: 7)),
        grantedLevel: EntitlementLevel.member,
      );

      // Ohne Pass gesperrt
      expect(
        manager.canCreateTrip(level: EntitlementLevel.trial, currentTripCount: 1, now: now),
        isFalse,
      );

      // Mit gültigem Pass freigeschaltet
      expect(
        manager.canCreateTrip(
          level: EntitlementLevel.trial,
          currentTripCount: 1,
          tripPass: pass,
          now: now,
        ),
        isTrue,
      );
    });

    test('Abgelaufener Törn-Pass sperrt Zugriff wie erwartet', () {
      final now = DateTime(2026, 9, 25, 12, 0);
      final expiredPass = TripCodePass(
        code: 'OLD-PASS',
        validUntil: now.subtract(const Duration(hours: 1)),
        grantedLevel: EntitlementLevel.pro,
      );

      expect(
        manager.canCreateTrip(
          level: EntitlementLevel.trial,
          currentTripCount: 1,
          tripPass: expiredPass,
          now: now,
        ),
        isFalse,
      );
    });

    test('Törnbezogener Pass schaltet Pro-Features für Ziel-Törn frei', () {
      final now = DateTime(2026, 9, 25, 12, 0);
      final tripPass = TripCodePass(
        code: 'PRO-TRIP-42',
        tripId: 42,
        validUntil: now.add(const Duration(days: 14)),
        grantedLevel: EntitlementLevel.pro,
      );

      // Für Törn 42: Pro-Features freigeschaltet
      expect(
        manager.canAccessFeature(
          feature: AppFeature.templates,
          level: EntitlementLevel.member,
          targetTripId: 42,
          tripPass: tripPass,
          now: now,
        ),
        isTrue,
      );

      // Für anderen Törn 99: bleibt auf Member-Level
      expect(
        manager.canAccessFeature(
          feature: AppFeature.templates,
          level: EntitlementLevel.member,
          targetTripId: 99,
          tripPass: tripPass,
          now: now,
        ),
        isFalse,
      );
    });
  });
}
