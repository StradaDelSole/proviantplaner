import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/catalog_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';

void main() {
  late CatalogData catalog;
  late QuantitiesData quantities;

  setUpAll(() {
    final catalogFile = File('data/catalog_v0.7.json');
    final quantitiesFile = File('data/quantities_v0.4.json');

    expect(catalogFile.existsSync(), isTrue, reason: 'data/catalog_v0.7.json existiert');
    expect(quantitiesFile.existsSync(), isTrue, reason: 'data/quantities_v0.4.json existiert');

    final catalogMap = json.decode(catalogFile.readAsStringSync()) as Map<String, dynamic>;
    final quantitiesMap = json.decode(quantitiesFile.readAsStringSync()) as Map<String, dynamic>;

    catalog = CatalogData.fromJson(catalogMap);
    quantities = QuantitiesData.fromJson(quantitiesMap);
  });

  group('Slice S2a: Katalog-Validierungstest über alle Einträge (Programmierregel 7)', () {
    test('Katalog- und Mengendateien haben korrekte Versionen', () {
      expect(catalog.version, '0.7');
      expect(quantities.version, '0.4');
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
            // Packung ist direkt als Stückzahl zulässig
            expect(needUnit, 'Packung');
          } else if (needUnit == 'Portion') {
            // Bei Bedarf in Portionen MUSS variant.portion vorhanden sein
            expect(v.portion, isNotNull,
                reason: 'Variante ${v.id} in Gruppe ${group.id} hat Bedarf in Portionen, aber kein portion-Feld');
            expect(
              UnitConverter.areCompatible(v.portion!.unit, v.pack.unit),
              isTrue,
              reason:
                  'Portionseinheit ${v.portion!.unit} in ${v.id} ist inkompatibel zu Packungseinheit ${v.pack.unit}',
            );
          } else {
            // Bedarfseinheit und Packungseinheit müssen kompatibel sein (g<->kg, ml<->l oder identisch)
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

    test('Wasser-Reviere in quantities_v0.4.json sind vollständig und gültig (Befund 6)', () {
      expect(quantities.waterLiters.containsKey('temperate'), isTrue);
      expect(quantities.waterLiters.containsKey('mediterranean_summer'), isTrue);
      expect(quantities.waterLiters.containsKey('hot_or_remote'), isTrue);

      expect(quantities.waterLiters['temperate']!.defaultValue, 2.0);
      expect(quantities.waterLiters['mediterranean_summer']!.defaultValue, 2.5);
      expect(quantities.waterLiters['hot_or_remote']!.defaultValue, 3.5);
    });
  });
}
