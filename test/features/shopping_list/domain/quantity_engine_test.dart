import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';

void main() {
  late CatalogRepository repository;
  late QuantityEngine engine;

  setUpAll(() {
    final catalogFile = File('data/catalog_v0.6.json');
    final quantitiesFile = File('data/quantities_v0.3.json');

    repository = CatalogRepository();
    repository.loadFromJsonStrings(
      catalogJson: catalogFile.readAsStringSync(),
      quantitiesJson: quantitiesFile.readAsStringSync(),
    );
    engine = repository.createEngine();
  });

  group('S2 Abnahmekriterium: Festes Referenzbeispiel (PRD)', () {
    test('5 Erwachsene (1 veg, 1 kein Alk), 7 Tage, Mittelmeer, 4 Bordabende', () {
      final crew = [
        const CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '2', name: 'Co-Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '3', name: 'Gast 1', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '4', name: 'Veggie', isAdult: true, isVegetarian: true, noAlcohol: false),
        const CrewMemberInput(id: '5', name: 'Sober', isAdult: true, isVegetarian: false, noAlcohol: true),
      ];

      // 7 Tage, 4 Bordabende (Tage 1, 2, 4, 6 an Bord, Tage 3, 5, 7 Restaurant)
      final days = List.generate(7, (i) {
        final dayNum = i + 1;
        final isRestEvening = (dayNum == 3 || dayNum == 5 || dayNum == 7);
        return TripDayInput(
          dayNumber: dayNum,
          isLunchRestaurant: false,
          isEveningRestaurant: isRestEvening,
        );
      });

      final result = engine.calculateTrip(
        daysCount: 7,
        region: 'mediterranean',
        fridgeCapacityLiters: 100.0,
        crewAppetite: 'normal',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: crew,
      );

      expect(result.groupResults, isNotEmpty);

      // 1. Wasser: per_person_day_region im Mittelmeer = 2.5 l pro Person und Tag
      // 5 Personen * 7 Tage * 2.5 l = 87.5 l
      final waterGroup = result.groupResults.firstWhere((g) => g.groupId == 'water');
      expect(waterGroup.rawGroupNeed, closeTo(87.5, 0.01));

      // 2. Brot und Backwaren: per_person_day, 120 g
      // 5 Personen * 7 Tage * 120 g = 4200 g
      final breadGroup = result.groupResults.firstWhere((g) => g.groupId == 'bread');
      expect(breadGroup.rawGroupNeed, closeTo(4200.0, 0.01));

      // 3. Bier: per_adult_evening, 1 Portion (0.5 l), drink-Profil
      // 4 Erwachsene (da 1 Sober mit 0 zählt) * 7 Tage * 1 Portion = 28 Portionen
      final beerGroup = result.groupResults.firstWhere((g) => g.groupId == 'beer');
      expect(beerGroup.rawGroupNeed, closeTo(28.0, 0.01));

      // 4. Olivenöl: per_crew_week, 1.0 l pro Crew und Woche
      // 7 Tage = 1 Woche = 1.0 l
      final oliveOilVariant = result.getVariantResult('olive_oil');
      expect(oliveOilVariant, isNotNull);
      expect(oliveOilVariant!.calculatedNeedAmount, closeTo(1.0, 0.01));
    });
  });

  group('S2: Tests für jede Rechenbasis', () {
    final standardAdult = [
      const CrewMemberInput(id: '1', name: 'Adult', isAdult: true, isVegetarian: false, noAlcohol: false),
    ];

    test('per_person_day rechnet exakt pro Person und Tag', () {
      final days = List.generate(5, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final res = engine.calculateTrip(
        daysCount: 5,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: 'normal',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: standardAdult,
      );
      // Brot: 120 g * 1 * 5 = 600 g
      final bread = res.groupResults.firstWhere((g) => g.groupId == 'bread');
      expect(bread.rawGroupNeed, closeTo(600.0, 0.01));
    });

    test('per_person_day_region berücksichtigt Reviere', () {
      final days = List.generate(2, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      
      final resMittelmeer = engine.calculateTrip(
        daysCount: 2,
        region: 'mediterranean_summer',
        fridgeCapacityLiters: 100,
        crewAppetite: 'normal',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: standardAdult,
      );
      expect(resMittelmeer.groupResults.firstWhere((g) => g.groupId == 'water').rawGroupNeed, closeTo(5.0, 0.01)); // 2 Tage * 2.5 l

      final resTemperate = engine.calculateTrip(
        daysCount: 2,
        region: 'nordsee',
        fridgeCapacityLiters: 100,
        crewAppetite: 'normal',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: standardAdult,
      );
      expect(resTemperate.groupResults.firstWhere((g) => g.groupId == 'water').rawGroupNeed, closeTo(4.0, 0.01)); // 2 Tage * 2.0 l

      final resTropics = engine.calculateTrip(
        daysCount: 2,
        region: 'karibik',
        fridgeCapacityLiters: 100,
        crewAppetite: 'normal',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: standardAdult,
      );
      expect(resTropics.groupResults.firstWhere((g) => g.groupId == 'water').rawGroupNeed, closeTo(7.0, 0.01)); // 2 Tage * 3.5 l
    });

    test('per_person_week rechnet anteilig auf andere Törnlängen', () {
      // Butter: 125 g pro Person und Woche
      // 10 Tage = (10 / 7) * 125 g = 178.57 g
      final days = List.generate(10, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final res = engine.calculateTrip(
        daysCount: 10,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: 'normal',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: standardAdult,
      );
      final butter = res.groupResults.firstWhere((g) => g.groupId == 'butter');
      expect(butter.rawGroupNeed, closeTo(178.57, 0.1));
    });

    test('per_person_board_lunch berücksichtigt nur Tage ohne Restaurant mittags', () {
      // 5 Tage, an 2 Tagen Mittags-Restaurant -> 3 Bord-Mittage
      final days = [
        const TripDayInput(dayNumber: 1, isLunchRestaurant: false, isEveningRestaurant: false),
        const TripDayInput(dayNumber: 2, isLunchRestaurant: true, isEveningRestaurant: false),
        const TripDayInput(dayNumber: 3, isLunchRestaurant: false, isEveningRestaurant: false),
        const TripDayInput(dayNumber: 4, isLunchRestaurant: true, isEveningRestaurant: false),
        const TripDayInput(dayNumber: 5, isLunchRestaurant: false, isEveningRestaurant: false),
      ];
      final res = engine.calculateTrip(
        daysCount: 5,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: 'normal',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: standardAdult,
      );
      // veg_salad: per_person_board_lunch, 150 g
      // 3 Bordtage * 150 g = 450 g
      final salad = res.groupResults.firstWhere((g) => g.groupId == 'veg_salad');
      expect(salad.rawGroupNeed, closeTo(450.0, 0.01));
    });

    test('per_crew_week zählt angefangene Wochen voll', () {
      // 8 Tage -> 2 angefangene Wochen
      final days = List.generate(8, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final res = engine.calculateTrip(
        daysCount: 8,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: 'normal',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: standardAdult,
      );
      // olive_oil: per_crew_week, 1.0 l
      // 2 Wochen * 1.0 l = 2.0 l
      final oliveOil = res.getVariantResult('olive_oil');
      expect(oliveOil, isNotNull);
      expect(oliveOil!.calculatedNeedAmount, closeTo(2.0, 0.01));
    });

    test('check Mode erzeugt Prüflisten ohne Mengenberechnung', () {
      final days = List.generate(7, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final res = engine.calculateTrip(
        daysCount: 7,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: 'normal',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: standardAdult,
      );
      final checkGroup = res.groupResults.firstWhere((g) => g.mode == 'check');
      expect(checkGroup.isCheckMode, isTrue);
      expect(checkGroup.rawGroupNeed, 0.0);
      expect(checkGroup.variantResults.first.calculatedPackages, 0);
    });
  });

  group('S2: Tests für Konsumprofile und Crew-Fragen', () {
    test('Appetit-Frage passt Gruppen mit Profil eat an', () {
      final days = List.generate(1, (i) => const TripDayInput(dayNumber: 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final adult = [const CrewMemberInput(id: '1', name: 'A', isAdult: true, isVegetarian: false, noAlcohol: false)];

      // hungry_sailors (+25%) -> 1.25 * 120 g = 150 g
      final resHungry = engine.calculateTrip(
        daysCount: 1,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: 'hungry_sailors',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: adult,
      );
      expect(resHungry.groupResults.firstWhere((g) => g.groupId == 'bread').rawGroupNeed, closeTo(150.0, 0.01));

      // light (-10%) -> 0.90 * 120 g = 108 g
      final resLight = engine.calculateTrip(
        daysCount: 1,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: 'light',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: adult,
      );
      expect(resLight.groupResults.firstWhere((g) => g.groupId == 'bread').rawGroupNeed, closeTo(108.0, 0.01));
    });

    test('Individuelle Einstufung customEatLevel überschreibt Crew-Frage', () {
      final days = List.generate(1, (i) => const TripDayInput(dayNumber: 1, isLunchRestaurant: false, isEveningRestaurant: false));
      // Crew-Einstellung ist hearty (+15%), aber Person hat explizit small (0.8)
      final member = [
        const CrewMemberInput(
          id: '1',
          name: 'Individual',
          isAdult: true,
          isVegetarian: false,
          noAlcohol: false,
          customEatLevel: 'small', // 0.8
        )
      ];
      final res = engine.calculateTrip(
        daysCount: 1,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: 'hearty',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: member,
      );
      // 0.8 * 120 g = 96 g
      expect(res.groupResults.firstWhere((g) => g.groupId == 'bread').rawGroupNeed, closeTo(96.0, 0.01));
    });

    test('Kinderfaktor 0.6 wird korrekt angewendet', () {
      final days = List.generate(1, (i) => const TripDayInput(dayNumber: 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final child = [const CrewMemberInput(id: '1', name: 'Child', isAdult: false, isVegetarian: false, noAlcohol: true)];

      final res = engine.calculateTrip(
        daysCount: 1,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: 'normal',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: child,
      );
      // Brot: 120 g * 0.6 = 72 g
      expect(res.groupResults.firstWhere((g) => g.groupId == 'bread').rawGroupNeed, closeTo(72.0, 0.01));

      // Alkohol: Kind zählt 0
      expect(res.groupResults.firstWhere((g) => g.groupId == 'beer').rawGroupNeed, 0.0);
    });
  });

  group('S2: Tests für Rundungsregeln und Reserve', () {
    test('Haltbare Artikel (>= 14 Tage) runden immer auf (ceil)', () {
      final days = List.generate(7, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final adult = [const CrewMemberInput(id: '1', name: 'A', isAdult: true, isVegetarian: false, noAlcohol: false)];
      final res = engine.calculateTrip(
        daysCount: 7,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: 'normal',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: adult,
      );
      // Honig: shelf_life 365 Tage, Packung 500 g.
      final honey = res.getVariantResult('honey');
      expect(honey, isNotNull);
      expect(honey!.calculatedPackages, 1);
    });

    test('Reserve-Zuschlag (+10%) wird NUR auf Artikel mit Haltbarkeit >= 14 Tage angewendet', () {
      final days = List.generate(7, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final adult = [const CrewMemberInput(id: '1', name: 'A', isAdult: true, isVegetarian: false, noAlcohol: false)];

      final withoutReserve = engine.calculateTrip(
        daysCount: 7,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: 'normal',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: adult,
      );

      final withReserve = engine.calculateTrip(
        daysCount: 7,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: 'normal',
        crewReserve: true,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: adult,
      );

      // Baguette: shelf_life 1 Tag -> kein Reservezuschlag!
      final baguetteNoRes = withoutReserve.getVariantResult('baguette');
      final baguetteWithRes = withReserve.getVariantResult('baguette');
      expect(baguetteWithRes!.calculatedNeedAmount, closeTo(baguetteNoRes!.calculatedNeedAmount, 0.001));

      // Knäckebrot (crispbread): shelf_life 90 Tage -> +10% Reservezuschlag!
      final knaeckeNoRes = withoutReserve.getVariantResult('crispbread');
      final knaeckeWithRes = withReserve.getVariantResult('crispbread');
      expect(knaeckeWithRes!.calculatedNeedAmount, closeTo(knaeckeNoRes!.calculatedNeedAmount * 1.1, 0.001));
    });
  });

  group('S2: Tests für Überschreibungen (Überleben von Crew- und Tagesänderungen)', () {
    test('Vom Nutzer überschriebene Packungszahl bleibt bei Crew-/Tagesänderung erhalten', () {
      final days7 = List.generate(7, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final crew2 = [
        const CrewMemberInput(id: '1', name: 'A', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '2', name: 'B', isAdult: true, isVegetarian: false, noAlcohol: false),
      ];

      // Nutzer überschreibt Vollkornbrot auf 10 Packungen
      final userStates = {
        'bread_wholegrain': const UserItemState(isSelected: true, overriddenPackages: 10),
      };

      final initialRes = engine.calculateTrip(
        daysCount: 7,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: 'normal',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days7,
        crewMembers: crew2,
        userItemStates: userStates,
      );

      final breadInitial = initialRes.getVariantResult('bread_wholegrain')!;
      expect(breadInitial.effectivePackages, 10);
      expect(breadInitial.overriddenPackages, 10);

      // Nun ändert sich die Crew auf 8 Personen und die Tage auf 14
      final days14 = List.generate(14, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final crew8 = List.generate(
        8,
        (i) => CrewMemberInput(id: '$i', name: 'Person $i', isAdult: true, isVegetarian: false, noAlcohol: false),
      );

      final updatedRes = engine.calculateTrip(
        daysCount: 14,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: 'normal',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days14,
        crewMembers: crew8,
        userItemStates: userStates,
      );

      final breadUpdated = updatedRes.getVariantResult('bread_wholegrain')!;
      // calculatedPackages hat sich an die neue Crewgröße angepasst:
      expect(breadUpdated.calculatedPackages, isNot(breadInitial.calculatedPackages));
      // Aber effectivePackages bleibt exakt die Überschreibung von 10:
      expect(breadUpdated.effectivePackages, 10);
      expect(breadUpdated.overriddenPackages, 10);

      // Beim Zurücksetzen der Überschreibung (overriddenPackages: null) gilt wieder die Berechnung:
      final resetStates = {
        'bread_wholegrain': const UserItemState(isSelected: true, overriddenPackages: null),
      };
      final resetRes = engine.calculateTrip(
        daysCount: 14,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: 'normal',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days14,
        crewMembers: crew8,
        userItemStates: resetStates,
      );
      final breadReset = resetRes.getVariantResult('bread_wholegrain')!;
      expect(breadReset.overriddenPackages, isNull);
      expect(breadReset.effectivePackages, breadReset.calculatedPackages);
    });
  });

  group('S2: Test für Kühlkapazitäts-Warnung', () {
    test('Schlägt Alarm, wenn Frischemengen der ersten 3 Tage Kühlschrank übersteigen', () {
      final days = List.generate(7, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final crew10 = List.generate(
        10,
        (i) => CrewMemberInput(id: '$i', name: 'Person $i', isAdult: true, isVegetarian: false, noAlcohol: false),
      );

      // Sehr kleiner Kühlschrank (1 Liter) vs 10 hungrige Segler
      final smallFridgeRes = engine.calculateTrip(
        daysCount: 7,
        region: 'temperate',
        fridgeCapacityLiters: 1.0,
        crewAppetite: 'hungry_sailors',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: crew10,
      );
      expect(smallFridgeRes.isFridgeOverloaded, isTrue);

      // Riesiger Kühlschrank (500 Liter)
      final largeFridgeRes = engine.calculateTrip(
        daysCount: 7,
        region: 'temperate',
        fridgeCapacityLiters: 500.0,
        crewAppetite: 'hungry_sailors',
        crewReserve: false,
        crewDrinking: 'normal',
        tripDays: days,
        crewMembers: crew10,
      );
      expect(largeFridgeRes.isFridgeOverloaded, isFalse);
    });
  });
}
