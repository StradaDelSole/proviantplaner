import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/assist_type.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/catalog_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';

void main() {
  late CatalogData catalog;
  late QuantitiesData quantities;

  setUpAll(() {
    final catalogFile = File('data/catalog_v0.11.json');
    final quantitiesFile = File('data/quantities_v0.6.json');

    expect(catalogFile.existsSync(), isTrue, reason: 'data/catalog_v0.11.json existiert');
    expect(quantitiesFile.existsSync(), isTrue, reason: 'data/quantities_v0.6.json existiert');

    final catalogMap = json.decode(catalogFile.readAsStringSync()) as Map<String, dynamic>;
    final quantitiesMap = json.decode(quantitiesFile.readAsStringSync()) as Map<String, dynamic>;

    catalog = CatalogData.fromJson(catalogMap);
    quantities = QuantitiesData.fromJson(quantitiesMap);
  });

  group('DATA1: Katalog-Validierungstest v0.11 und Assistenzklassifikation (Programmierregel 7)', () {
    test('Katalog- und Mengendateien haben korrekte Versionen', () {
      expect(catalog.version, '0.11');
      expect(quantities.version, '0.6');
    });

    test('Eindeutigkeit aller Gruppen- und Varianten-IDs', () {
      final groupIds = <String>{};
      for (final g in catalog.groups) {
        expect(groupIds.contains(g.id), isFalse, reason: 'Gruppen-ID ${g.id} muss eindeutig sein');
        groupIds.add(g.id);
      }

      final variantIds = <String>{};
      for (final v in catalog.variants) {
        expect(variantIds.contains(v.id), isFalse, reason: 'Varianten-ID ${v.id} muss eindeutig sein');
        variantIds.add(v.id);
      }
    });

    test('Alle Varianten verweisen auf eine existierende Gruppe', () {
      final groupIds = catalog.groups.map((g) => g.id).toSet();
      for (final v in catalog.variants) {
        expect(groupIds.contains(v.group), isTrue,
            reason: 'Variante ${v.id} verweist auf unbekannte Gruppe ${v.group}');
      }
    });

    test('Einheiten-Kompatibilität für ALLE Varianten im Katalog (Befund 2 & Regel 4)', () {
      int checkedCount = 0;
      for (final group in catalog.groups) {
        final variants = catalog.getVariantsForGroup(group.id);
        if (group.mode == GroupMode.check) continue;

        for (final v in variants) {
          checkedCount++;
          expect(v.pack.size, greaterThan(0),
              reason: 'Variante ${v.id} muss eine Packungsgröße > 0 haben');

          final needUnit = v.need?.unit ?? group.need?.unit;
          if (needUnit == null) continue;

          if (needUnit == 'Packung') {
            expect(needUnit, 'Packung');
          } else if (needUnit == 'Portion') {
            expect(v.portion, isNotNull,
                reason: 'Variante ${v.id} in Gruppe ${group.id} hat Bedarf in Portionen, aber kein portion-Feld');
            expect(
              UnitConverter.areCompatible(v.portion!.unit, v.pack.unit),
              isTrue,
              reason:
                  'Portionseinheit ${v.portion!.unit} in ${v.id} ist inkompatibel zu Packungseinheit ${v.pack.unit}',
            );
          } else {
            final compatible = UnitConverter.areCompatible(needUnit, v.pack.unit);
            expect(
              compatible,
              isTrue,
              reason:
                  'Bedarfseinheit $needUnit in Gruppe ${group.id} ist inkompatibel zu Packungseinheit ${v.pack.unit} in Variante ${v.id}',
            );
          }
        }
      }
      expect(checkedCount, greaterThan(100), reason: 'Mindestens 100 Varianten geprüft');
    });

    test('applies_to Werte sind ausnahmslos gültig (Befund 1)', () {
      for (final g in catalog.groups) {
        expect(
          [AppliesTo.all, AppliesTo.nonVegetarian, AppliesTo.vegetarian, AppliesTo.adults],
          contains(g.appliesTo),
          reason: 'Gruppe ${g.id} hat ungültiges applies_to',
        );
      }
    });

    test('Urlaubszuschlag-Gruppen existieren vollständig im Katalog (Befund 5)', () {
      final groupIds = catalog.groups.map((g) => g.id).toSet();
      for (final gId in quantities.factors.holidaySnackDrinkUplift.appliesToGroups) {
        expect(groupIds.contains(gId), isTrue,
            reason: 'Urlaubszuschlag-Gruppe "$gId" existiert im Katalog');
      }
    });

    test('Wasser-Klimazonen in quantities_v0.6.json sind vollständig und gültig (Befund 6)', () {
      expect(quantities.waterLiters.containsKey('cool'), isTrue);
      expect(quantities.waterLiters.containsKey('warm'), isTrue);
      expect(quantities.waterLiters.containsKey('hot'), isTrue);

      expect(quantities.waterLiters['cool']!.defaultValue, 2.0);
      expect(quantities.waterLiters['warm']!.defaultValue, 2.5);
      expect(quantities.waterLiters['hot']!.defaultValue, 3.5);

      expect(quantities.waterTankReserveLitersPerPerson, 1.5);
    });

    // --- DATA1 Parser- & Validierungstests (Abschnitt 15) ---

    test('1. gültige Group-Assist-Werte werden strikt geparst', () {
      final g1 = CatalogGroup.fromJson({
        'id': 'g1', 'category': 'c', 'name_de': 'N', 'assist': 'needs_based',
        'profile': 'none', 'applies_to': 'all', 'split': 'equal', 'visibility': 'all', 'mode': 'quantity'
      });
      expect(g1.assist, AssistType.needsBased);

      final g2 = CatalogGroup.fromJson({
        'id': 'g2', 'category': 'c', 'name_de': 'N', 'assist': 'guided',
        'profile': 'none', 'applies_to': 'all', 'split': 'equal', 'visibility': 'all', 'mode': 'quantity'
      });
      expect(g2.assist, AssistType.guided);

      final g3 = CatalogGroup.fromJson({
        'id': 'g3', 'category': 'c', 'name_de': 'N', 'assist': 'preference_based',
        'profile': 'none', 'applies_to': 'all', 'split': 'equal', 'visibility': 'all', 'mode': 'quantity'
      });
      expect(g3.assist, AssistType.preferenceBased);
    });

    test('2. fehlendes Group-assist wirft FormatException', () {
      expect(
        () => CatalogGroup.fromJson({
          'id': 'g_missing', 'category': 'c', 'name_de': 'N',
          'profile': 'none', 'applies_to': 'all', 'split': 'equal', 'visibility': 'all', 'mode': 'quantity'
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('3. unbekanntes Group-assist wirft FormatException', () {
      expect(
        () => CatalogGroup.fromJson({
          'id': 'g_unknown', 'category': 'c', 'name_de': 'N', 'assist': 'invalid_type',
          'profile': 'none', 'applies_to': 'all', 'split': 'equal', 'visibility': 'all', 'mode': 'quantity'
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('4. Variant ohne Override erbt Gruppenwert', () {
      final v = CatalogVariant.fromJson({
        'id': 'v1', 'group': 'bread', 'name_de': 'Brot',
        'pack': {'size': 500, 'unit': 'g'}, 'department': 'backwaren',
      });
      expect(v.assistOverride, isNull);
      final group = catalog.getGroup('bread')!;
      expect(catalog.getEffectiveAssist(v), group.assist);
    });

    test('5. gültiger Variant Override wird geparst', () {
      final v = CatalogVariant.fromJson({
        'id': 'v_pesto', 'group': 'sauces_pasta', 'name_de': 'Pesto',
        'assist': 'preference_based',
        'pack': {'size': 190, 'unit': 'g'}, 'department': 'konserven',
      });
      expect(v.assistOverride, AssistType.preferenceBased);
      expect(catalog.getEffectiveAssist(v), AssistType.preferenceBased);
    });

    test('6. unbekannter Variant Override wirft FormatException', () {
      expect(
        () => CatalogVariant.fromJson({
          'id': 'v_invalid', 'group': 'sauces_pasta', 'name_de': 'Pesto',
          'assist': 'invalid_assist',
          'pack': {'size': 190, 'unit': 'g'}, 'department': 'konserven',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('7. alle 47 Gruppen besitzen gültiges Assist (1 needs_based, 5 preference_based, 41 guided)', () {
      expect(catalog.groups.length, 47);
      final needsBased = catalog.groups.where((g) => g.assist == AssistType.needsBased).toList();
      final prefBased = catalog.groups.where((g) => g.assist == AssistType.preferenceBased).toList();
      final guided = catalog.groups.where((g) => g.assist == AssistType.guided).toList();

      expect(needsBased.length, 1);
      expect(needsBased.first.id, 'water');

      expect(prefBased.length, 5);
      final prefIds = prefBased.map((g) => g.id).toSet();
      expect(prefIds, equals({'spread_sweet', 'spread_savory', 'sweets', 'savory_snacks', 'spirits'}));

      expect(guided.length, 41);
    });

    test('8. alle 232 Varianten besitzen einen auflösbaren effektiven AssistType', () {
      expect(catalog.variants.length, 232);
      for (final v in catalog.variants) {
        final effective = catalog.getEffectiveAssist(v);
        expect([AssistType.needsBased, AssistType.guided, AssistType.preferenceBased], contains(effective));
        expect(catalog.getAssistTypeForVariant(v.id), equals(effective));
      }
    });

    test('9. exakt 11 Varianten besitzen einen preference_based Override', () {
      final overridden = catalog.variants.where((v) => v.assistOverride != null).toList();
      expect(overridden.length, 11);
      final overriddenIds = overridden.map((v) => v.id).toSet();
      expect(overriddenIds, equals({
        'brie', 'feta', 'mozzarella', 'parmesan',
        'sauce_jar', 'pesto', 'soy_sauce', 'bbq_sauce',
        'sweet_chili', 'tabasco', 'tofu'
      }));
      for (final v in overridden) {
        expect(v.assistOverride, AssistType.preferenceBased);
      }
    });

    // --- DATA1 Semantik-Regressionscheck (Abschnitt 18) ---

    test('10. DATA1 Semantik-Regressionscheck: v0.11 ist semantisch identisch zum vor DATA1 akzeptierten Mapping', () {
      const expectedPrefGroups = {'spread_sweet', 'spread_savory', 'sweets', 'savory_snacks', 'spirits'};
      const expectedPrefVariants = {
        'brie', 'feta', 'mozzarella', 'parmesan',
        'sauce_jar', 'pesto', 'soy_sauce', 'bbq_sauce',
        'sweet_chili', 'tabasco', 'tofu'
      };

      for (final g in catalog.groups) {
        if (g.id == 'water') {
          expect(g.assist, AssistType.needsBased, reason: 'water muss needsBased sein');
        } else if (expectedPrefGroups.contains(g.id)) {
          expect(g.assist, AssistType.preferenceBased, reason: '${g.id} muss preferenceBased sein');
        } else {
          expect(g.assist, AssistType.guided, reason: '${g.id} muss guided sein');
        }
      }

      for (final v in catalog.variants) {
        final effective = catalog.getEffectiveAssist(v);
        if (v.group == 'water') {
          expect(effective, AssistType.needsBased);
        } else if (expectedPrefGroups.contains(v.group) || expectedPrefVariants.contains(v.id)) {
          expect(effective, AssistType.preferenceBased, reason: '${v.id} muss preferenceBased sein');
        } else {
          expect(effective, AssistType.guided, reason: '${v.id} muss guided sein');
        }
      }
    });

    test('11. DATA1 Amendment (Finding A & C): Check-Mode VariantCalculationResult übernimmt kataloggetriebenen AssistType ohne stillen guided-Fallback', () {
      // 1. Reale Check-Gruppen aus v0.11
      final engine = QuantityEngine(catalog: catalog, quantities: quantities);
      final input = QuantityCalculationInput(
        daysCount: 7,
        climate: ClimateZone.warm,
        fridgeCapacityLiters: 80.0,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        tripDays: const [
          TripDayInput(dayNumber: 1, isLunchRestaurant: false, isEveningRestaurant: false),
        ],
        crewMembers: const [
          CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );
      final realResult = engine.calculateTrip(input);
      final checkGroups = realResult.groupResults.where((g) => g.mode == GroupMode.check).toList();
      expect(checkGroups, isNotEmpty);
      for (final cg in checkGroups) {
        for (final vr in cg.variantResults) {
          final catalogVariant = catalog.getVariant(vr.variantId)!;
          expect(vr.assistType, equals(catalog.getEffectiveAssist(catalogVariant)));
        }
      }

      // 2. Synthetischer Check-Mode-Test mit needsBased-Gruppe und preferenceBased-Override:
      // Beweist, dass _processCheckGroup() nicht still auf AssistType.guided fällt, sondern catalog.getEffectiveAssist(v) nutzt.
      const syntheticCatalog = CatalogData(
        version: '0.11',
        categories: [CatalogCategory(id: 'cat_check', nameDe: 'Check')],
        groups: [
          CatalogGroup(
            id: 'check_group_needs',
            category: 'cat_check',
            nameDe: 'Check Needs',
            assist: AssistType.needsBased,
            profile: GroupProfile.none,
            appliesTo: AppliesTo.all,
            split: GroupSplit.each,
            visibility: GroupVisibility.all,
            mode: GroupMode.check,
          ),
        ],
        variants: [
          CatalogVariant(
            id: 'check_var_inherited',
            group: 'check_group_needs',
            nameDe: 'Check Inherited',
            pack: PackInfo(size: 1, unit: 'Stück'),
            shelfLifeDays: 365,
            buyFreshUnderway: false,
            department: CatalogDepartment.haushalt,
            defaultSelected: true,
          ),
          CatalogVariant(
            id: 'check_var_override',
            group: 'check_group_needs',
            nameDe: 'Check Override',
            pack: PackInfo(size: 1, unit: 'Stück'),
            shelfLifeDays: 365,
            buyFreshUnderway: false,
            department: CatalogDepartment.haushalt,
            defaultSelected: true,
            assistOverride: AssistType.preferenceBased,
          ),
        ],
        storageHints: {},
      );

      final syntheticEngine = QuantityEngine(catalog: syntheticCatalog, quantities: quantities);
      final syntheticResult = syntheticEngine.calculateTrip(input);
      final inheritedRes = syntheticResult.getVariantResult('check_var_inherited');
      final overrideRes = syntheticResult.getVariantResult('check_var_override');

      expect(inheritedRes, isNotNull);
      expect(inheritedRes!.assistType, equals(AssistType.needsBased),
          reason: 'Check-Variante ohne Override muss Gruppen-Assist (needsBased) übernehmen und darf nicht auf guided fallen');
      expect(overrideRes, isNotNull);
      expect(overrideRes!.assistType, equals(AssistType.preferenceBased),
          reason: 'Check-Variante mit Override muss Override (preferenceBased) übernehmen und darf nicht auf guided fallen');
    });

    test('12. WATER1 Simplification (Punkte 21 & 22): data/quantities_v0.6.json ist unverändert und data/quantities_v0.7.json existiert nicht mehr', () {
      final v06File = File('data/quantities_v0.6.json');
      final v07File = File('data/quantities_v0.7.json');

      expect(v06File.existsSync(), isTrue, reason: 'data/quantities_v0.6.json muss existieren');
      expect(v07File.existsSync(), isFalse, reason: 'data/quantities_v0.7.json darf im Repo nicht mehr existieren');

      final v06Map = json.decode(v06File.readAsStringSync()) as Map<String, dynamic>;
      expect(v06Map['version'], equals('0.6'));
      expect(v06Map.containsKey('watermaker'), isFalse);

      final waterLiters = v06Map['water_liters_per_person_day'] as Map<String, dynamic>;
      expect((waterLiters['cool'] as Map<String, dynamic>)['default'], equals(2.0));
      expect((waterLiters['warm'] as Map<String, dynamic>)['default'], equals(2.5));
      expect((waterLiters['hot'] as Map<String, dynamic>)['default'], equals(3.5));

      final pubspecContent = File('pubspec.yaml').readAsStringSync();
      expect(pubspecContent.contains('data/quantities_v0.6.json'), isTrue);
      expect(pubspecContent.contains('data/quantities_v0.7.json'), isFalse);
    });
  });
}
