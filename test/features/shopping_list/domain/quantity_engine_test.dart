import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';

void main() {
  late CatalogRepository repository;
  late QuantityEngine engine;

  setUpAll(() {
    final catalogFile = File('data/catalog_v0.7.json');
    final quantitiesFile = File('data/quantities_v0.4.json');

    repository = CatalogRepository();
    repository.loadFromJsonStrings(
      catalogJson: catalogFile.readAsStringSync(),
      quantitiesJson: quantitiesFile.readAsStringSync(),
    );
    engine = repository.createEngine();
  });

  group('Slice S2a: Festes Referenzbeispiel (PRD v0.16)', () {
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
        QuantityCalculationInput(
          daysCount: 7,
          region: 'mediterranean_summer',
          fridgeCapacityLiters: 100.0,
          crewAppetite: CrewAppetite.normal,
          crewReserve: false,
          crewDrinking: CrewDrinking.normal,
          tripDays: days,
          crewMembers: crew,
        ),
      );

      // 1. Wasser: per_person_day_region im Mittelmeer = 2.5 l pro Person und Tag
      // Rechnung: 5 Personen * 7 Tage * 2.5 l = 87.5 l
      final waterGroup = result.groupResults.firstWhere((g) => g.groupId == 'water');
      expect(waterGroup.rawGroupNeed, closeTo(87.5, 0.01));

      // 2. Brot und Backwaren: per_person_day, 120 g
      // Rechnung: 5 Personen * 7 Tage * 120 g = 4200 g (4.2 kg)
      final breadGroup = result.groupResults.firstWhere((g) => g.groupId == 'bread');
      expect(breadGroup.rawGroupNeed, closeTo(4200.0, 0.01));

      // 3. Bier: per_adult_evening, 0.5 l, drink-Profil, applies_to: adults
      // Rechnung: 4 Erwachsene (1 Sober zählt 0) * 7 Tage * 0.5 l = 14.0 l
      // Urlaubszuschlag (holiday_snack_drink_uplift = 1.2): 14.0 * 1.2 = 16.8 l
      final beerGroup = result.groupResults.firstWhere((g) => g.groupId == 'beer');
      expect(beerGroup.rawGroupNeed, closeTo(16.8, 0.01));
      // Packungszahl Bier: 16.8 l / 0.5 l = 33.6 Dosen à 0.5 l -> ceil(33.6) = 34 Dosen
      final beerVariant = result.getVariantResult('beer_can');
      expect(beerVariant, isNotNull);
      expect(beerVariant!.calculatedPackages, 34);

      // 4. Olivenöl: per_crew_week, 1.0 l pro Crew und Woche
      // Rechnung: 7 Tage = 1 Woche = 1.0 l -> 1 Flasche (1.0 l)
      final oliveOilVariant = result.getVariantResult('olive_oil');
      expect(oliveOilVariant, isNotNull);
      expect(oliveOilVariant!.calculatedNeedAmount, closeTo(1.0, 0.01));
      expect(oliveOilVariant.calculatedPackages, 1);
    });
  });

  group('Slice S2a: Befund 1 – applies_to & Vegetarier', () {
    test('Fleischgruppe schließt Vegetarier aus, vegetarische Gruppe schließt Fleischesser aus', () {
      final crew = [
        const CrewMemberInput(id: '1', name: 'MeatEater1', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '2', name: 'MeatEater2', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '3', name: 'Veggie', isAdult: true, isVegetarian: true, noAlcohol: false),
      ];

      // 1 Bordabend (Tag 1), keine Restaurantabende
      final days = [
        const TripDayInput(dayNumber: 1, isLunchRestaurant: false, isEveningRestaurant: false),
      ];

      final result = engine.calculateTrip(
        QuantityCalculationInput(
          daysCount: 1,
          region: 'mediterranean_summer',
          fridgeCapacityLiters: 100.0,
          crewAppetite: CrewAppetite.normal,
          crewReserve: false,
          crewDrinking: CrewDrinking.normal,
          tripDays: days,
          crewMembers: crew,
        ),
      );

      // Fleisch-Hauptkomponente: applies_to: non_vegetarian, 175 g pro Person und Bordabend
      // Rechnung: 2 Nicht-Vegetarier * 1 Abend * 175 g = 350 g (Veggie zählt 0)
      final meatGroup = result.groupResults.firstWhere((g) => g.groupId == 'meat_fish');
      expect(meatGroup.rawGroupNeed, closeTo(350.0, 0.01));

      // Vegetarische Hauptkomponente: applies_to: vegetarian, 150 g pro Person und Bordabend
      // Rechnung: 1 Vegetarier * 1 Abend * 150 g = 150 g (Fleischesser zählen 0)
      final vegGroup = result.groupResults.firstWhere((g) => g.groupId == 'veg_protein');
      expect(vegGroup.rawGroupNeed, closeTo(150.0, 0.01));
    });

    test('applies_to: adults schließt Kinder aus', () {
      final crew = [
        const CrewMemberInput(id: '1', name: 'Adult', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '2', name: 'Child', isAdult: false, isVegetarian: false, noAlcohol: false),
      ];

      final days = List.generate(7, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));

      final result = engine.calculateTrip(
        QuantityCalculationInput(
          daysCount: 7,
          region: 'mediterranean_summer',
          fridgeCapacityLiters: 100.0,
          crewAppetite: CrewAppetite.normal,
          crewReserve: false,
          crewDrinking: CrewDrinking.normal,
          tripDays: days,
          crewMembers: crew,
        ),
      );

      // Bier: applies_to: adults, 0.5 l pro Erwachsener und Abend (7 Tage)
      // Rechnung: 1 Erwachsener * 7 Tage * 0.5 l = 3.5 l (Kind zählt 0)
      // Urlaubszuschlag (1.2): 3.5 * 1.2 = 4.2 l
      final beerGroup = result.groupResults.firstWhere((g) => g.groupId == 'beer');
      expect(beerGroup.rawGroupNeed, closeTo(4.2, 0.01));
    });
  });

  group('Slice S2a: Befund 2 – Packungszahlen für konkrete Produktgruppen', () {
    test('Spülmittel: Bedarf 1 Packung pro Crew/Woche ergibt 1 Flasche', () {
      final days = List.generate(7, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final res = engine.calculateTrip(
        QuantityCalculationInput(
          daysCount: 7,
          region: 'mediterranean_summer',
          fridgeCapacityLiters: 100,
          crewAppetite: CrewAppetite.normal,
          crewReserve: false,
          crewDrinking: CrewDrinking.normal,
          tripDays: days,
          crewMembers: [
            const CrewMemberInput(id: '1', name: 'A', isAdult: true, isVegetarian: false, noAlcohol: false),
          ],
        ),
      );

      // Spülmittel: per_crew_week, 1 Packung (pack: 500 ml)
      // Rechnung: 7 Tage = 1 Woche = 1 Packung -> 1 Flasche
      final soap = res.getVariantResult('dish_soap');
      expect(soap, isNotNull);
      expect(soap!.calculatedPackages, 1);
    });

    test('Duschgel: per_person_week, 0.25 Packungen pro Person/Woche ergibt 2 Flaschen bei 5 Personen', () {
      final days = List.generate(7, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final res = engine.calculateTrip(
        QuantityCalculationInput(
          daysCount: 7,
          region: 'mediterranean_summer',
          fridgeCapacityLiters: 100,
          crewAppetite: CrewAppetite.normal,
          crewReserve: false,
          crewDrinking: CrewDrinking.normal,
          tripDays: days,
          crewMembers: List.generate(5, (i) => CrewMemberInput(id: '$i', name: 'A$i', isAdult: true, isVegetarian: false, noAlcohol: false)),
        ),
      );

      // Duschgel: split=each, per_person_week, need: 0.25 Packung (pack: 250 ml)
      // Rechnung: 5 Personen * 1 Woche * 0.25 Packung = 1.25 Packungen
      // Haltbar (3650 Tage) -> ceil(1.25) = 2 Flaschen (500 ml)
      // (Im alten Code vor S2a ergab 1.25 Packung / 0.25 l fälschlicherweise 5 Flaschen!)
      final bodyWash = res.getVariantResult('shower_gel');
      expect(bodyWash, isNotNull);
      expect(bodyWash!.calculatedPackages, 2);
    });

    test('Spaghetti über Portionen: 130 g je Portion in 500 g Packungen', () {
      // 5 Erwachsene, 1 Bordabend mit Pasta
      final days = [
        const TripDayInput(dayNumber: 1, isLunchRestaurant: false, isEveningRestaurant: false),
      ];
      final crew = List.generate(5, (i) => CrewMemberInput(id: '$i', name: 'P$i', isAdult: true, isVegetarian: false, noAlcohol: false));

      final res = engine.calculateTrip(
        QuantityCalculationInput(
          daysCount: 1,
          region: 'mediterranean_summer',
          fridgeCapacityLiters: 100,
          crewAppetite: CrewAppetite.normal,
          crewReserve: false,
          crewDrinking: CrewDrinking.normal,
          tripDays: days,
          crewMembers: crew,
          userItemStates: {
            'spaghetti': const UserItemState(isSelected: true),
            'penne': const UserItemState(isSelected: false),
            'rice': const UserItemState(isSelected: false),
            'potatoes': const UserItemState(isSelected: false),
          },
        ),
      );

      // Gruppe carbs: need = 1 Portion pro Person und Bordabend
      // 5 Personen * 1 Portion = 5 Portionen
      // Spaghetti portion = 130 g -> 5 * 130 g = 650 g
      // Packung 500 g: 650 g / 500 g = 1.3 Packungen
      // Haltbar (>= 14d) -> ceil(1.3) = 2 Packungen (1000 g)
      final spaghetti = res.getVariantResult('spaghetti');
      expect(spaghetti, isNotNull);
      expect(spaghetti!.calculatedPackages, 2);
    });
  });

  group('Slice S2a: Befund 3 – Gruppenausgleich (group_balancing)', () {
    test('Brot-Gruppe deckt Gesamtbedarf und baut Überschuss > 1 volle Packung ab', () {
      // 5 Personen, 7 Tage: Gruppenbedarf Brot = 5 * 7 * 120 g = 4200 g
      final days = List.generate(7, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final crew = List.generate(5, (i) => CrewMemberInput(id: '$i', name: 'P$i', isAdult: true, isVegetarian: false, noAlcohol: false));

      final res = engine.calculateTrip(
        QuantityCalculationInput(
          daysCount: 7,
          region: 'mediterranean_summer',
          fridgeCapacityLiters: 100,
          crewAppetite: CrewAppetite.normal,
          crewReserve: false,
          crewDrinking: CrewDrinking.normal,
          tripDays: days,
          crewMembers: crew,
          userItemStates: {
            'bread_wholegrain': const UserItemState(isSelected: true, share: 0.4),  // 40 % = 1680 g
            'baguette': const UserItemState(isSelected: true, share: 0.3),          // 30 % = 1260 g
            'rolls': const UserItemState(isSelected: true, share: 0.3),             // 30 % = 1260 g
            'bread_white': const UserItemState(isSelected: false),
            'rolls_wholegrain': const UserItemState(isSelected: false),
            'bake_rolls': const UserItemState(isSelected: false),
            'toast': const UserItemState(isSelected: false),
            'crispbread': const UserItemState(isSelected: false),
            'pumpernickel': const UserItemState(isSelected: false),
          },
        ),
      );

      final breadWhole = res.getVariantResult('bread_wholegrain')!;
      final baguette = res.getVariantResult('baguette')!;
      final breadRolls = res.getVariantResult('rolls')!;

      // Gesamtmenge bereitgestellt:
      final totalProvided = (breadWhole.calculatedPackages * breadWhole.packSize) +
          (baguette.calculatedPackages * baguette.packSize) +
          (breadRolls.calculatedPackages * breadRolls.packSize);

      // Kriterium 1: Summe deckt Bedarf (4200 g)
      expect(totalProvided, greaterThanOrEqualTo(4200.0));

      // Kriterium 2: Kein Überschuss über eine volle Packung (größte Packung ist Brot 750 g)
      // Das bedeutet: totalProvided - 4200 < 750 g
      expect(totalProvided - 4200.0, lessThan(750.0));
    });
  });

  group('Slice S2a: Befund 5 – Urlaubszuschlag (holiday_snack_drink_uplift)', () {
    test('Wird nur auf vorgesehene Gruppen angewendet', () {
      final days = List.generate(7, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final crew = [
        const CrewMemberInput(id: '1', name: 'Adult', isAdult: true, isVegetarian: false, noAlcohol: false),
      ];

      final res = engine.calculateTrip(
        QuantityCalculationInput(
          daysCount: 7,
          region: 'mediterranean_summer',
          fridgeCapacityLiters: 100,
          crewAppetite: CrewAppetite.normal,
          crewReserve: false,
          crewDrinking: CrewDrinking.normal,
          tripDays: days,
          crewMembers: crew,
        ),
      );

      // 1. Süßes (sweets): per_person_week, 300 g * 1 Person * 1 Woche * 1.2 = 360 g
      final sweets = res.groupResults.firstWhere((g) => g.groupId == 'sweets');
      expect(sweets.rawGroupNeed, closeTo(360.0, 0.01));

      // 2. Süße Aufstriche: per_person_week, 150 g * 1 Person * 1 Woche, KEIN Urlaubszuschlag = 150 g
      final spreadGroup = res.groupResults.firstWhere((g) => g.groupId == 'spread_sweet');
      expect(spreadGroup.rawGroupNeed, closeTo(150.0, 0.01));

      // 3. Wasser: 2.5 l * 7 Tage = 17.5 l, KEIN Urlaubszuschlag = 17.5 l
      final water = res.groupResults.firstWhere((g) => g.groupId == 'water');
      expect(water.rawGroupNeed, closeTo(17.5, 0.01));
    });
  });

  group('Slice S2a: Befund 6 – Generische Wasserberechnung nach Revier', () {
    test('Berechnet exakte Wassermengen je nach Region', () {
      final crew = [const CrewMemberInput(id: '1', name: 'A', isAdult: true, isVegetarian: false, noAlcohol: false)];
      final days = List.generate(10, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));

      // Gemäßigt (Nord/Ostsee): 2.0 l/Tag * 10 = 20 l
      final resTemperate = engine.calculateTrip(QuantityCalculationInput(
        daysCount: 10,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: days,
        crewMembers: crew,
      ));
      expect(resTemperate.groupResults.firstWhere((g) => g.groupId == 'water').rawGroupNeed, closeTo(20.0, 0.01));

      // Mittelmeer: 2.5 l/Tag * 10 = 25 l
      final resMed = engine.calculateTrip(QuantityCalculationInput(
        daysCount: 10,
        region: 'mediterranean_summer',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: days,
        crewMembers: crew,
      ));
      expect(resMed.groupResults.firstWhere((g) => g.groupId == 'water').rawGroupNeed, closeTo(25.0, 0.01));

      // Tropen/Heiß: 3.5 l/Tag * 10 = 35 l
      final resTropics = engine.calculateTrip(QuantityCalculationInput(
        daysCount: 10,
        region: 'hot_or_remote',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: days,
        crewMembers: crew,
      ));
      expect(resTropics.groupResults.firstWhere((g) => g.groupId == 'water').rawGroupNeed, closeTo(35.0, 0.01));
    });
  });

  group('Slice S2a: Randfälle gemäß Programmierregel 7', () {
    test('1 Person, 14 Tage Törn', () {
      final days = List.generate(14, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final res = engine.calculateTrip(QuantityCalculationInput(
        daysCount: 14,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: days,
        crewMembers: [const CrewMemberInput(id: '1', name: 'Solo', isAdult: true, isVegetarian: false, noAlcohol: false)],
      ));
      // Wasser: 2.0 l * 14 = 28 l
      expect(res.groupResults.firstWhere((g) => g.groupId == 'water').rawGroupNeed, closeTo(28.0, 0.01));
    });

    test('0 Bordabende (alle 7 Tage im Restaurant)', () {
      final days = List.generate(7, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: true));
      final res = engine.calculateTrip(QuantityCalculationInput(
        daysCount: 7,
        region: 'mediterranean_summer',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: days,
        crewMembers: [const CrewMemberInput(id: '1', name: 'Sailor', isAdult: true, isVegetarian: false, noAlcohol: false)],
      ));
      // Abendgemüse: per_person_board_evening -> 0 Bordabende = 0 g
      final vegEvening = res.groupResults.firstWhere((g) => g.groupId == 'veg_evening');
      expect(vegEvening.rawGroupNeed, closeTo(0.0, 0.01));
    });

    test('Nur Kinder (Kinderfaktor 0.6 auf eat)', () {
      final days = List.generate(7, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final res = engine.calculateTrip(QuantityCalculationInput(
        daysCount: 7,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: days,
        crewMembers: [const CrewMemberInput(id: '1', name: 'Child', isAdult: false, isVegetarian: false, noAlcohol: false)],
      ));
      // Brot: 120 g * 7 * 0.6 = 504 g
      final bread = res.groupResults.firstWhere((g) => g.groupId == 'bread');
      expect(bread.rawGroupNeed, closeTo(504.0, 0.01));
    });

    test('Alle Vegetarier', () {
      final days = [const TripDayInput(dayNumber: 1, isLunchRestaurant: false, isEveningRestaurant: false)];
      final res = engine.calculateTrip(QuantityCalculationInput(
        daysCount: 1,
        region: 'temperate',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: days,
        crewMembers: [
          const CrewMemberInput(id: '1', name: 'Veg1', isAdult: true, isVegetarian: true, noAlcohol: false),
          const CrewMemberInput(id: '2', name: 'Veg2', isAdult: true, isVegetarian: true, noAlcohol: false),
        ],
      ));
      final meat = res.groupResults.firstWhere((g) => g.groupId == 'meat_fish');
      expect(meat.rawGroupNeed, closeTo(0.0, 0.01));
    });

    test('Keine Trinker (noAlcohol: true auf Alkohol = 0)', () {
      final days = List.generate(7, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final res = engine.calculateTrip(QuantityCalculationInput(
        daysCount: 7,
        region: 'mediterranean_summer',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.festive,
        tripDays: days,
        crewMembers: [
          const CrewMemberInput(id: '1', name: 'Dry1', isAdult: true, isVegetarian: false, noAlcohol: true),
          const CrewMemberInput(id: '2', name: 'Dry2', isAdult: true, isVegetarian: false, noAlcohol: true),
        ],
      ));
      final beer = res.groupResults.firstWhere((g) => g.groupId == 'beer');
      expect(beer.rawGroupNeed, closeTo(0.0, 0.01));
      final wine = res.groupResults.firstWhere((g) => g.groupId == 'wine');
      expect(wine.rawGroupNeed, closeTo(0.0, 0.01));
    });

    test('Überschriebene Packungszahl überlebt Crew- und Tagesänderung', () {
      final days7 = List.generate(7, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final crew2 = [
        const CrewMemberInput(id: '1', name: 'A', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '2', name: 'B', isAdult: true, isVegetarian: false, noAlcohol: false),
      ];

      // Nutzer überschreibt Bier auf genau 99 Dosen
      final res1 = engine.calculateTrip(QuantityCalculationInput(
        daysCount: 7,
        region: 'mediterranean_summer',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: days7,
        crewMembers: crew2,
        userItemStates: {
          'beer_can': const UserItemState(isSelected: true, overriddenPackages: 99),
        },
      ));

      expect(res1.getVariantResult('beer_can')!.effectivePackages, 99);

      // Jetzt ändern wir die Crew von 2 auf 6 Personen und 14 Tage
      final days14 = List.generate(14, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));
      final crew6 = List.generate(6, (i) => CrewMemberInput(id: '$i', name: 'P$i', isAdult: true, isVegetarian: false, noAlcohol: false));

      final res2 = engine.calculateTrip(QuantityCalculationInput(
        daysCount: 14,
        region: 'mediterranean_summer',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.hearty,
        crewReserve: true,
        crewDrinking: CrewDrinking.festive,
        tripDays: days14,
        crewMembers: crew6,
        userItemStates: {
          'beer_can': const UserItemState(isSelected: true, overriddenPackages: 99),
        },
      ));

      // Berechnete Menge hat sich drastisch erhöht, aber die überschriebene Packungszahl bleibt 99!
      expect(res2.getVariantResult('beer_can')!.effectivePackages, 99);
      expect(res2.getVariantResult('beer_can')!.overriddenPackages, 99);
    });
  });
}
