import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/calculation_result.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/assist_type.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/catalog_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';

void main() {
  late CatalogData catalog;
  late QuantitiesData quantities;
  late QuantityEngine engine;

  setUpAll(() {
    final catalogFile = File('data/catalog_v0.11.json');
    final quantitiesFile = File('data/quantities_v0.6.json');

    final catalogMap = json.decode(catalogFile.readAsStringSync()) as Map<String, dynamic>;
    final quantitiesMap = json.decode(quantitiesFile.readAsStringSync()) as Map<String, dynamic>;

    catalog = CatalogData.fromJson(catalogMap);
    quantities = QuantitiesData.fromJson(quantitiesMap);
    engine = QuantityEngine(catalog: catalog, quantities: quantities);
  });

  List<CrewMemberInput> createCrew(int count) {
    return List.generate(
      count,
      (i) => CrewMemberInput(
        id: 'crew_$i',
        name: 'Person $i',
        isAdult: true,
        isVegetarian: false,
        noAlcohol: false,
      ),
    );
  }

  List<TripDayInput> createDays(int count) {
    return List.generate(
      count,
      (i) => TripDayInput(
        dayNumber: i + 1,
        isLunchRestaurant: false,
        isEveningRestaurant: false,
      ),
    );
  }

  group('Slice FB2-A: Abnahmetests Rechenlogik Haltbarkeit, Tiefkühlfach, Bordtank', () {
    // 1. Kriterium: 21 Tage, 5 Personen, kein Stopp ->
    // Baguette deckt höchstens 1 Tag, Champignons höchstens 4 Tage, Rest-Hinweis vorhanden, haltbare Brotsorte trägt den Rest.
    test('21 Tage, 5 Personen, kein Stopp: Haltbarkeitsbegrenzung und Tragen durch haltbare Sorten', () {
      // Rechnung:
      // Brotbedarf: 120 g / Person / Tag. Bei 5 Personen und 21 Tagen:
      // Gesamtbedarf Brot = 120 * 5 * 21 = 12.600 g (600 g / Tag).
      // Baguette: shelf_life_days = 1.
      // Knäckebrot: shelf_life_days = 180.
      // Wenn nur Baguette und Knäckebrot gewählt:
      // Tag 1 (600 g): Baguette und Knäckebrot aktiv -> je 300 g.
      // Tage 2-21 (20 Tage * 600 g = 12.000 g): Nur Knäckebrot aktiv -> 12.000 g.
      // Baguette-Bedarf = 300 g (deckt 0.5 Tage <= 1 Tag).
      // Knäckebrot-Bedarf = 300 g + 12.000 g = 12.300 g (trägt den Rest des 21-Tage-Bedarfs!).

      final input = QuantityCalculationInput(
        daysCount: 21,
        climate: ClimateZone.warm,
        fridgeCapacityLiters: 80.0,
        hasFreezer: false,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: createDays(21),
        crewMembers: createCrew(5),
        userItemStates: {
          'baguette': const UserItemState(isSelected: true, share: 1.0),
          'crispbread': const UserItemState(isSelected: true, share: 1.0),
          'bread_wholegrain': const UserItemState(isSelected: false),
          'bread_white': const UserItemState(isSelected: false),
          'rolls': const UserItemState(isSelected: false),
          'rolls_wholegrain': const UserItemState(isSelected: false),
          'toast': const UserItemState(isSelected: false),
          'bake_rolls': const UserItemState(isSelected: false),
          'pumpernickel': const UserItemState(isSelected: false),
          'wraps': const UserItemState(isSelected: false),
          'bread_longlife': const UserItemState(isSelected: false),
        },
      );

      final result = engine.calculateTrip(input);

      // Prüfung Baguette & Knäckebrot
      final baguette = result.getVariantResult('baguette');
      expect(baguette, isNotNull);
      expect(baguette!.isSelected, isTrue);
      // Baguette deckt höchstens 1 Tag (1 Tag = 600 g)
      expect(baguette.calculatedNeedAmount, lessThanOrEqualTo(600.0 + epsilon));
      expect(baguette.calculatedNeedAmount, closeTo(300.0, 1e-3));

      final knaecke = result.getVariantResult('crispbread');
      expect(knaecke, isNotNull);
      expect(knaecke!.isSelected, isTrue);
      // Knäckebrot trägt den Rest des 21-Tage-Bedarfs
      expect(knaecke.calculatedNeedAmount, closeTo(12300.0, 1e-3));
      expect(baguette.calculatedNeedAmount + knaecke.calculatedNeedAmount, closeTo(12600.0, 1e-3));

      // Prüfung Champignons in veg_evening:
      // 175 g / Person / Abendessen an Bord = 175 * 5 = 875 g / Tag.
      // Champignons: shelf_life_days = 4.
      // Champignons-Vorschlag darf höchstens 4 Tage decken (4 * 875 g = 3.500 g).
      final mushrooms = result.getVariantResult('mushrooms');
      expect(mushrooms, isNotNull);
      expect(mushrooms!.isSelected, isTrue);
      expect(mushrooms.shelfLifeDays, 4);
      expect(mushrooms.calculatedNeedAmount, lessThanOrEqualTo(4 * 875.0 + epsilon));

      // Da nach Tag 7 keine frischen Standardgemüse mehr aktiv sind, gibt es einen Resthinweis mit Alternativen
      expect(mushrooms.remainderNotice, isNotNull);
      expect(mushrooms.remainderNotice, contains('Rest ca.'));
      expect(mushrooms.remainderNotice, contains('bei einem späteren Einkauf einplanen'));
      expect(mushrooms.remainderNotice, contains('ohne Einkauf eignen sich'));
    });

    // 2. Kriterium: mit Stopp an Tag 8 -> Vorschlag je Stopp
    test('mit Stopp an Tag 8: Vorschlag für Stopp 1 (7 Tage) und Stopp 2 (14 Tage)', () {
      // 5 Personen, 21 Tage Törn.
      // Stopp 1: Einkaufen an Tag 1 für 7 Tage bis Stopp an Tag 8 (T = 7).
      // Brotbedarf für 7 Tage: 120 * 5 * 7 = 4.200 g.
      final inputStop1 = QuantityCalculationInput(
        daysCount: 21,
        daysUntilNextStop: 7,
        currentStopDayNumber: 1,
        climate: ClimateZone.warm,
        fridgeCapacityLiters: 80.0,
        hasFreezer: false,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: createDays(21),
        crewMembers: createCrew(5),
      );

      final resultStop1 = engine.calculateTrip(inputStop1);
      final breadGroup1 = resultStop1.groupResults.firstWhere((g) => g.groupId == 'bread');
      expect(breadGroup1.rawGroupNeed, closeTo(4200.0, 1e-3));

      // Stopp 2: Einkaufen an Tag 8 für restliche 14 Tage bis Tag 21 (T = 14).
      // Brotbedarf für 14 Tage: 120 * 5 * 14 = 8.400 g.
      final inputStop2 = QuantityCalculationInput(
        daysCount: 21,
        daysUntilNextStop: 14,
        currentStopDayNumber: 8,
        climate: ClimateZone.warm,
        fridgeCapacityLiters: 80.0,
        hasFreezer: false,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: createDays(21),
        crewMembers: createCrew(5),
      );

      final resultStop2 = engine.calculateTrip(inputStop2);
      final breadGroup2 = resultStop2.groupResults.firstWhere((g) => g.groupId == 'bread');
      expect(breadGroup2.rawGroupNeed, closeTo(8400.0, 1e-3));
    });

    // 3. Kriterium: ohne Tiefkühlfach keine TK-Variante im Vorschlag, mit Tiefkühlfach Hähnchen bis 90 Tage
    test('ohne Tiefkühlfach: keine TK-Variante im Vorschlag; Hähnchen auf 3 Tage begrenzt', () {
      final inputNoFreezer = QuantityCalculationInput(
        daysCount: 21,
        climate: ClimateZone.warm,
        fridgeCapacityLiters: 80.0,
        hasFreezer: false,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: createDays(21),
        crewMembers: createCrew(5),
        userItemStates: {
          'frozen_chicken': const UserItemState(isSelected: true),
        },
      );

      final result = engine.calculateTrip(inputNoFreezer);

      // TK-Variante (chill == freezer) darf ohne Tiefkühlfach nicht vorgeschlagen werden
      final frozenChicken = result.getVariantResult('frozen_chicken');
      expect(frozenChicken, isNotNull);
      expect(frozenChicken!.effectivePackages, 0);
      expect(frozenChicken.calculatedNeedAmount, 0.0);

      // Hähnchen frisch hat shelf_life_days = 3; ohne TK gilt nur Kühlschrank
      final chicken = result.getVariantResult('chicken');
      expect(chicken, isNotNull);
      expect(chicken!.effectiveShelfLifeDays, 3);
    });

    test('mit Tiefkühlfach: Hähnchen mit shelf_life_frozen_days bis 90 Tage haltbar und Hinweis', () {
      final inputWithFreezer = QuantityCalculationInput(
        daysCount: 21,
        climate: ClimateZone.warm,
        fridgeCapacityLiters: 80.0,
        hasFreezer: true,
        freezerCapacityLiters: 30.0,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: createDays(21),
        crewMembers: createCrew(5),
        userItemStates: {
          'frozen_chicken': const UserItemState(isSelected: true),
        },
      );

      final result = engine.calculateTrip(inputWithFreezer);

      // TK-Variante wird mit Tiefkühlfach vorgeschlagen
      final frozenChicken = result.getVariantResult('frozen_chicken');
      expect(frozenChicken, isNotNull);
      expect(frozenChicken!.chill, ChillRequirement.freezer);

      // Hähnchen nutzt shelf_life_frozen_days = 90
      final chicken = result.getVariantResult('chicken');
      expect(chicken, isNotNull);
      expect(chicken!.effectiveShelfLifeDays, 90);
      expect(chicken.storageNotice, contains('einfrieren'));

      // Tiefkühlvolumen wird berechnet
      expect(result.freezerLitersNeeded, greaterThan(0.0));
      expect(result.isFreezerOverloaded, isFalse);
    });

    // 4. Kriterium: Mindest-Trinkwasserbedarf unabhängig von Bordtank (WATER1 Simplification)
    test('Bordtank 200 l: Mindest-Trinkwasserbedarf bleibt 262.5 l unabhängig von Tankgröße und Trinkbarkeit', () {
      // 5 Personen, 21 Tage, Klimazone warm: 2.5 l / Person / Tag.
      // Mindest-Trinkwasserbedarf = 5 * 21 * 2.5 = 262.5 l.

      // Fall A: Tank 200 l, NICHT trinkbar -> 262.5 l
      final inputNotDrinkable = QuantityCalculationInput(
        daysCount: 21,
        climate: ClimateZone.warm,
        fridgeCapacityLiters: 80.0,
        waterTankLiters: 200.0,
        isWaterTankDrinkable: false,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: createDays(21),
        crewMembers: createCrew(5),
      );

      final resultNotDrinkable = engine.calculateTrip(inputNotDrinkable);
      final waterGroupA = resultNotDrinkable.groupResults.firstWhere((g) => g.groupId == 'water');
      expect(waterGroupA.rawGroupNeed, closeTo(262.5, 1e-3));

      // Fall B: Tank 200 l, TRINKBAR -> 262.5 l (WATER1 Simplification: Tank reduziert Mindest-Trinkwasserschätzung nicht)
      final inputDrinkable = QuantityCalculationInput(
        daysCount: 21,
        climate: ClimateZone.warm,
        fridgeCapacityLiters: 80.0,
        waterTankLiters: 200.0,
        isWaterTankDrinkable: true,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: createDays(21),
        crewMembers: createCrew(5),
      );

      final resultDrinkable = engine.calculateTrip(inputDrinkable);
      final waterGroupB = resultDrinkable.groupResults.firstWhere((g) => g.groupId == 'water');
      expect(waterGroupB.rawGroupNeed, closeTo(262.5, 1e-3));

      // Fall C: Tank 300 l, TRINKBAR -> 262.5 l
      final inputTankSurplus = QuantityCalculationInput(
        daysCount: 21,
        climate: ClimateZone.warm,
        fridgeCapacityLiters: 80.0,
        waterTankLiters: 300.0,
        isWaterTankDrinkable: true,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: createDays(21),
        crewMembers: createCrew(5),
      );

      final resultSurplus = engine.calculateTrip(inputTankSurplus);
      final waterGroupC = resultSurplus.groupResults.firstWhere((g) => g.groupId == 'water');
      expect(waterGroupC.rawGroupNeed, closeTo(262.5, 1e-3));
    });

    // 5. Kriterium: Gewicht/Volumen einer Beispielliste
    test('Gesamtgewicht und -volumen einer Beispielliste', () {
      final sampleVariants = [
        const VariantCalculationResult(
          variantId: 'water_1_5',
          groupId: 'water',
          nameDe: 'Wasser still 1.5L',
          department: CatalogDepartment.getraenke,
          isSelected: true,
          share: 1.0,
          calculatedNeedAmount: 15.0,
          unit: 'l',
          packSize: 1.5,
          packUnit: 'l',
          calculatedPackages: 10,
          effectivePackages: 10, // 10 * 1.5 l = 15.0 kg, 15.0 l
          shelfLifeDays: 365,
          effectiveShelfLifeDays: 365,
          buyFreshUnderway: false,
          storage: [],
          tags: [],
          assistType: AssistType.guided,
        ),
        const VariantCalculationResult(
          variantId: 'pasta_spaghetti',
          groupId: 'pasta',
          nameDe: 'Spaghetti 500g',
          department: CatalogDepartment.trockenware,
          isSelected: true,
          share: 1.0,
          calculatedNeedAmount: 2000.0,
          unit: 'g',
          packSize: 500.0,
          packUnit: 'g',
          calculatedPackages: 4,
          effectivePackages: 4, // 4 * 500 g = 2.0 kg, 2.0 l
          shelfLifeDays: 365,
          effectiveShelfLifeDays: 365,
          buyFreshUnderway: false,
          storage: [],
          tags: [],
          assistType: AssistType.guided,
        ),
        const VariantCalculationResult(
          variantId: 'flour_1kg',
          groupId: 'flour',
          nameDe: 'Weizenmehl 1kg',
          department: CatalogDepartment.trockenware,
          isSelected: true,
          share: 1.0,
          calculatedNeedAmount: 2.0,
          unit: 'kg',
          packSize: 1.0,
          packUnit: 'kg',
          calculatedPackages: 2,
          effectivePackages: 2, // 2 * 1 kg = 2.0 kg, 2.0 l
          shelfLifeDays: 365,
          effectiveShelfLifeDays: 365,
          buyFreshUnderway: false,
          storage: [],
          tags: [],
          assistType: AssistType.guided,
        ),
        const VariantCalculationResult(
          variantId: 'cream_250ml',
          groupId: 'cream',
          nameDe: 'H-Sahne 250ml',
          department: CatalogDepartment.molkerei,
          isSelected: true,
          share: 1.0,
          calculatedNeedAmount: 500.0,
          unit: 'ml',
          packSize: 250.0,
          packUnit: 'ml',
          calculatedPackages: 2,
          effectivePackages: 2, // 2 * 250 ml = 0.5 kg, 0.5 l
          shelfLifeDays: 90,
          effectiveShelfLifeDays: 90,
          buyFreshUnderway: false,
          storage: [],
          tags: [],
          assistType: AssistType.guided,
        ),
        const VariantCalculationResult(
          variantId: 'eggs_10',
          groupId: 'eggs',
          nameDe: 'Eier (10er)',
          department: CatalogDepartment.molkerei,
          isSelected: true,
          share: 1.0,
          calculatedNeedAmount: 10.0,
          unit: 'Stück',
          packSize: 10.0,
          packUnit: 'Stück',
          calculatedPackages: 1,
          effectivePackages: 1, // Stückware ohne Gewichtsangabe
          shelfLifeDays: 21,
          effectiveShelfLifeDays: 21,
          buyFreshUnderway: false,
          storage: [],
          tags: [],
          assistType: AssistType.guided,
        ),
      ];

      // Erwartung:
      // Gewicht = 15.0 + 2.0 + 2.0 + 0.5 = 19.5 kg
      // Volumen = 15.0 + 2.0 + 2.0 + 0.5 = 19.5 l
      // hasItemsWithoutWeight = true (wegen Eier 10er Stück)
      final wv = QuantityEngine.calculateWeightAndVolume(sampleVariants);
      expect(wv.totalWeightKg, closeTo(19.5, 1e-3));
      expect(wv.totalVolumeLiters, closeTo(19.5, 1e-3));
      expect(wv.hasItemsWithoutWeight, isTrue);
    });

    // 6. Kriterium: Revier-Migration isoliert in ClimateZone
    test('Revier-Migration isoliert im ClimateZone Enum', () {
      expect(ClimateZone.fromString('temperate'), ClimateZone.cool);
      expect(ClimateZone.fromString('mediterranean'), ClimateZone.warm);
      expect(ClimateZone.fromString('mediterranean_summer'), ClimateZone.warm);
      expect(ClimateZone.fromString('hot_or_remote'), ClimateZone.hot);
      expect(ClimateZone.fromString('cool'), ClimateZone.cool);
      expect(ClimateZone.fromString('warm'), ClimateZone.warm);
      expect(ClimateZone.fromString('hot'), ClimateZone.hot);

      expect(() => ClimateZone.fromString('unknown_region'), throwsFormatException);
    });
  });
}
