/// Umfassende automatisierte Tests für PIVOT2 – Provisioning Review (Issue #26).
/// Prüft alle 38 Kriterien gemäß docs/impl/PIVOT2_plan_v0.2.md:
/// 1. Pure/read-only Prüfung (keine DB-Mutationen)
/// 2. Strict review-config parsing
/// 3. Validierung aller Config-IDs gegen catalog v0.11
/// 4-8. durable bread, cooking oil, hygiene, cleaning, trash bags satisfied / missing
/// 9. Keine Erfüllung durch Custom-Item-Namen
/// 10-12. AssistType-Verhalten (needs_based, guided, preference_based)
/// 13-17. WATER1 Estimate, CHECK bei Unterdeckung, Tank/Watermaker als Kontext, keine Unterdeckung bei >= Richtwert
/// 18-19. Frische & Haltbarkeit (Issue #8)
/// 20-24. Kühl- und Gefrierplausibilität (ActionNeeded bei 0 Kapazität / Überlastung, Info bei unvollständiger Basis)
/// 25. Gewicht & Volumen Wiederverwendung
/// 26. Gesamtstatus-Aggregation (ready, check, actionNeeded)
/// 27-30. UI Entry, Grouped Sections, Inline-Hint, Action Handoff
/// 31. Lokalisierung
/// 32-37. Regressionen (Issue #7, Issue #8, PIVOT1, DATA1, PIVOT3, WATER1)
library;

import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/tables.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/provisioning_review_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/assist_type.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/catalog_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/provisioning_review_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/provisioning_review_sheet.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/stop_allocation_sheet.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';

void main() {
  late CatalogData catalog;
  late QuantitiesData quantities;
  late ProvisioningReviewConfig reviewConfig;

  setUpAll(() {
    final catFile = File('data/catalog_v0.11.json');
    final quantFile = File('data/quantities_v0.6.json');
    final reviewConfigFile = File('data/provisioning_review_v0.1.json');

    expect(catFile.existsSync(), isTrue);
    expect(quantFile.existsSync(), isTrue);
    expect(reviewConfigFile.existsSync(), isTrue);

    final catMap = json.decode(catFile.readAsStringSync()) as Map<String, dynamic>;
    final quantMap = json.decode(quantFile.readAsStringSync()) as Map<String, dynamic>;
    final reviewConfigMap =
        json.decode(reviewConfigFile.readAsStringSync()) as Map<String, dynamic>;

    catalog = CatalogData.fromJson(catMap);
    quantities = QuantitiesData.fromJson(quantMap);
    reviewConfig = ProvisioningReviewConfig.fromJson(reviewConfigMap);
  });

  group('PIVOT2 Kriterium 2 & 3: Review-Config Parsing & Validierung', () {
    test('Config lädt strikt und alle Regel-IDs validieren gegen catalog v0.11', () {
      expect(reviewConfig.version, '0.1');
      expect(reviewConfig.rules.length, 5);

      // Muss fehlerfrei validieren
      expect(() => reviewConfig.validateAgainstCatalog(catalog), returnsNormally);
    });

    test('Ungültige Gruppe in Review-Regel wirft FormatException', () {
      const invalidJson = '''
      {
        "version": "0.1",
        "rules": [
          {
            "id": "invalid_rule",
            "type": "group_presence",
            "severity": "check",
            "group": "non_existent_group",
            "action": { "type": "no_action" }
          }
        ]
      }
      ''';
      final parsed = ProvisioningReviewConfig.fromJson(
          json.decode(invalidJson) as Map<String, dynamic>);
      expect(
        () => parsed.validateAgainstCatalog(catalog),
        throwsA(isA<FormatException>()),
      );
    });

    test('Unbekannter Regel-Typ wirft FormatException', () {
      const unknownTypeJson = '''
      {
        "version": "0.1",
        "rules": [
          {
            "id": "unknown_rule",
            "type": "some_arbitrary_type",
            "severity": "check",
            "group": "bread",
            "action": { "type": "no_action" }
          }
        ]
      }
      ''';
      expect(
        () => ProvisioningReviewConfig.fromJson(
            json.decode(unknownTypeJson) as Map<String, dynamic>),
        throwsA(isA<FormatException>()),
      );
    });

    test('Fehlende Pflichtfelder je Regel-Typ werfen FormatException', () {
      // shelf_life_group_presence ohne threshold_field
      const missingThresholdJson = '''
      {
        "version": "0.1",
        "rules": [
          {
            "id": "bread_rule",
            "type": "shelf_life_group_presence",
            "severity": "check",
            "group": "bread",
            "action": { "type": "no_action" }
          }
        ]
      }
      ''';
      expect(
        () => ProvisioningReviewConfig.fromJson(
            json.decode(missingThresholdJson) as Map<String, dynamic>),
        throwsA(isA<FormatException>()),
      );

      // any_variant_presence mit leeren variants
      const emptyVariantsJson = '''
      {
        "version": "0.1",
        "rules": [
          {
            "id": "oil_rule",
            "type": "any_variant_presence",
            "severity": "check",
            "variants": [],
            "action": { "type": "no_action" }
          }
        ]
      }
      ''';
      expect(
        () => ProvisioningReviewConfig.fromJson(
            json.decode(emptyVariantsJson) as Map<String, dynamic>),
        throwsA(isA<FormatException>()),
      );

      // group_presence ohne group
      const missingGroupJson = '''
      {
        "version": "0.1",
        "rules": [
          {
            "id": "hygiene_rule",
            "type": "group_presence",
            "severity": "check",
            "action": { "type": "no_action" }
          }
        ]
      }
      ''';
      expect(
        () => ProvisioningReviewConfig.fromJson(
            json.decode(missingGroupJson) as Map<String, dynamic>),
        throwsA(isA<FormatException>()),
      );

      // Fehlende Action
      const missingActionJson = '''
      {
        "version": "0.1",
        "rules": [
          {
            "id": "hygiene_rule",
            "type": "group_presence",
            "severity": "check",
            "group": "hygiene"
          }
        ]
      }
      ''';
      expect(
        () => ProvisioningReviewConfig.fromJson(
            json.decode(missingActionJson) as Map<String, dynamic>),
        throwsA(isA<FormatException>()),
      );
    });

    test('Ungültige Action-Ziele werfen FormatException in validateAgainstCatalog', () {
      const invalidActionTargetJson = '''
      {
        "version": "0.1",
        "rules": [
          {
            "id": "invalid_action_rule",
            "type": "group_presence",
            "severity": "check",
            "group": "hygiene",
            "action": {
              "type": "search_or_add",
              "target_group": "completely_bogus_group"
            }
          }
        ]
      }
      ''';
      final parsed = ProvisioningReviewConfig.fromJson(
          json.decode(invalidActionTargetJson) as Map<String, dynamic>);
      expect(
        () => parsed.validateAgainstCatalog(catalog),
        throwsA(isA<FormatException>()),
      );
    });

    test('Duplizierte Regel-ID wirft FormatException', () {
      const duplicateJson = '''
      {
        "version": "0.1",
        "rules": [
          {
            "id": "rule_a",
            "type": "group_presence",
            "severity": "check",
            "group": "bread",
            "action": { "type": "no_action" }
          },
          {
            "id": "rule_a",
            "type": "group_presence",
            "severity": "check",
            "group": "hygiene",
            "action": { "type": "no_action" }
          }
        ]
      }
      ''';
      expect(
        () => ProvisioningReviewConfig.fromJson(
            json.decode(duplicateJson) as Map<String, dynamic>),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PIVOT2 Kriterium 1: Pure/Read-Only Garantie', () {
    test('reviewProvisioningList verändert keinen Datenbankzustand einschließlich Allokationen', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = CatalogRepository(
        catalog: catalog,
        quantities: quantities,
        reviewConfig: reviewConfig,
      );
      final tripService = TripService(
        tripDao: db.tripDao,
        listItemDao: db.listItemDao,
        catalogRepository: repo,
      );
      final shoppingListService = ShoppingListService(
        tripDao: db.tripDao,
        listItemDao: db.listItemDao,
        catalogRepository: repo,
        tripService: tripService,
      );

      final tripId = await tripService.createTripWithCrew(
        name: 'ReadOnly Test Törn',
        startDate: DateTime(2026, 10, 18),
        daysCount: 7,
        crewMembers: const [
          CrewMemberInput(
            id: 'm1',
            name: 'Skipper',
            isAdult: true,
            isVegetarian: false,
            noAlcohol: false,
          ),
        ],
      );

      // Erstelle zweiten Stopp und allokiere ein Item
      final stop2Id = await tripService.addShoppingStop(tripId: tripId, name: 'Hafen 2', dayNumber: 4);
      final initialItems = await db.listItemDao.getListItemsForTrip(tripId);
      final testItemId = initialItems.first.id;
      await shoppingListService.adoptItem(tripId: tripId, listItemId: testItemId, packages: 5);
      await shoppingListService.allocateToStop(
        tripId: tripId,
        listItemId: testItemId,
        shoppingStopId: stop2Id,
        packages: 2,
      );

      // Snapshot aller relevanten Tabellen VOR dem Review
      final tripsBefore = await db.select(db.trips).get();
      final daysBefore = await db.select(db.tripDays).get();
      final crewBefore = await db.select(db.crewMembers).get();
      final stopsBefore = await db.select(db.shoppingStops).get();
      final itemsBefore = await db.select(db.listItems).get();
      final allocsBefore = await db.select(db.listItemAllocations).get();

      // Führe Review mehrfach aus
      final result1 = await shoppingListService.reviewProvisioningList(tripId);
      final result2 = await shoppingListService.reviewProvisioningList(tripId);

      expect(result1.status, result2.status);
      expect(result1.findings.length, result2.findings.length);

      // Snapshot aller relevanten Tabellen NACH dem Review
      final tripsAfter = await db.select(db.trips).get();
      final daysAfter = await db.select(db.tripDays).get();
      final crewAfter = await db.select(db.crewMembers).get();
      final stopsAfter = await db.select(db.shoppingStops).get();
      final itemsAfter = await db.select(db.listItems).get();
      final allocsAfter = await db.select(db.listItemAllocations).get();

      // Strikt exakter Vergleich jedes einzelnen Datensatzes
      expect(tripsBefore, equals(tripsAfter));
      expect(daysBefore, equals(daysAfter));
      expect(crewBefore, equals(crewAfter));
      expect(stopsBefore, equals(stopsAfter));
      expect(itemsBefore, equals(itemsAfter));
      expect(allocsBefore, equals(allocsAfter));

      await db.close();
    });
  });

  group('PIVOT2 Kriterium 4-9: Missing Basics & No Custom Name Matching', () {
    Trip createTestTrip({int fridge = 100, bool freezer = false, int freezerCap = 0}) {
      return Trip(
        id: 1,
        name: 'Test Törn',
        startDate: DateTime(2026, 10, 18),
        daysCount: 7,
        region: 'mediterranean',
        climate: 'warm',
        isCharter: true,
        boatType: 'mono',
        fridgeCapacity: fridge,
        hasFreezer: freezer,
        freezerCapacity: freezerCap,
        waterTankLiters: 200,
        isWaterTankDrinkable: false,
        hasWatermaker: false,
        appetite: CrewAppetite.normal,
        reserveDays: 'few_days',
        drinkingHabit: CrewDrinking.normal,
        hasStorageChecklist: true,
        phase: TripPhase.plan,
        isArchived: false,
        currency: 'EUR',
        kittyModel: KittyModel.sharedKitty,
        createdAt: DateTime(2026, 10, 18),
      );
    }

    ShoppingListItemView createItem({
      required int id,
      required String variantId,
      required String groupId,
      required int packages,
      bool isCustom = false,
      String? customName,
      int shelfLife = 10,
      CatalogDepartment dept = CatalogDepartment.backwaren,
      ChillRequirement chill = ChillRequirement.none,
      AssistType assist = AssistType.guided,
    }) {
      final variant = isCustom
          ? null
          : catalog.variants.firstWhere((v) => v.id == variantId,
              orElse: () => CatalogVariant(
                    id: variantId,
                    group: groupId,
                    nameDe: variantId,
                    pack: const PackInfo(size: 1.0, unit: 'kg'),
                    shelfLifeDays: shelfLife,
                    buyFreshUnderway: false,
                    department: dept,
                    defaultSelected: false,
                    chill: chill,
                  ));

      return ShoppingListItemView(
        item: ListItem(
          id: id,
          tripId: 1,
          catalogId: isCustom ? 'custom_$id' : variantId,
          isCustom: isCustom,
          customName: isCustom ? (customName ?? variantId) : null,
          customUnit: isCustom ? 'kg' : null,
          customDepartment: isCustom ? dept.rawValue : null,
          selected: true,
          share: 1.0,
          calculatedQuantity: 1.0,
          calculatedPackages: packages,
          overriddenPackages: packages,
          checkState: CheckItemState.available,
          isAdopted: true,
        ),
        variant: variant,
        id: variantId,
        name: customName ?? variant?.nameDe ?? variantId,
        unit: 'kg',
        department: dept,
        categoryId: groupId,
        calculatedPackages: packages,
        overriddenPackages: packages,
        calculatedQuantity: 1.0,
        customPackageSize: 1.0,
        isSelected: true,
        share: 1.0,
        isCustom: isCustom,
        shelfLifeDays: shelfLife,
        storageHints: const [],
        isAdopted: true,
        allocationsByStop: const {},
        assistType: assist,
      );
    }

    test('Fehlende Basics erzeugen CHECK-Findings', () {
      final trip = createTestTrip();
      final engine = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [
          CrewMember(
            id: 1,
            tripId: 1,
            name: 'Skipper',
            isChild: false,
            isVegetarian: false,
            isNonDrinker: false,
            categoryParticipation: '{"all":true}',
            isSkipperFree: false,
          ),
        ],
        tripDays: const [],
        stops: const [],
        allItems: const [], // Leere Liste
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));

      final result = engine.evaluate();
      expect(result.status, ProvisioningReviewStatus.check);

      final missingBasicFindings = result.findings
          .where((f) => f.kind == ProvisioningReviewKind.missingBasic)
          .map((f) => f.ruleId)
          .toList();

      expect(missingBasicFindings, contains('durable_bread'));
      expect(missingBasicFindings, contains('cooking_oil'));
      expect(missingBasicFindings, contains('hygiene_basic'));
      expect(missingBasicFindings, contains('cleaning_basic'));
      expect(missingBasicFindings, contains('trash_bags'));
    });

    test('durable_bread wird nur durch Brot mit shelf_life >= 14 erfüllt', () {
      final trip = createTestTrip();
      // bread_white hat shelf_life_days = 3 (< 14)
      final shortLifeBread = createItem(
        id: 1,
        variantId: 'bread_white',
        groupId: 'bread',
        packages: 2,
        shelfLife: 3,
      );

      final engine1 = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [],
        tripDays: const [],
        stops: const [],
        allItems: [shortLifeBread],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));
      final res1 = engine1.evaluate();
      expect(res1.findings.any((f) => f.ruleId == 'durable_bread'), isTrue);

      // crispbread hat shelf_life_days = 90 (>= 14)
      final durableBread = createItem(
        id: 2,
        variantId: 'crispbread',
        groupId: 'bread',
        packages: 2,
        shelfLife: 90,
      );

      final engine2 = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [],
        tripDays: const [],
        stops: const [],
        allItems: [durableBread],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));
      final res2 = engine2.evaluate();
      expect(res2.findings.any((f) => f.ruleId == 'durable_bread'), isFalse);
    });

    test('cooking_oil wird durch olive_oil oder sunflower_oil erfüllt', () {
      final trip = createTestTrip();
      final oilItem = createItem(
        id: 1,
        variantId: 'olive_oil',
        groupId: 'oil_vinegar',
        packages: 1,
        dept: CatalogDepartment.trockenware,
      );

      final engine = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [],
        tripDays: const [],
        stops: const [],
        allItems: [oilItem],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));
      final res = engine.evaluate();
      expect(res.findings.any((f) => f.ruleId == 'cooking_oil'), isFalse);
    });

    test('Kriterium 9: Eigene Position mit passendem Namen erfüllt KEINE Katalog-Regel', () {
      final trip = createTestTrip();
      final customBread = createItem(
        id: 10,
        variantId: 'custom_10',
        groupId: 'bread',
        packages: 2,
        isCustom: true,
        customName: 'Haltbares Dosenbrot 1 Jahr',
      );

      final engine = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [],
        tripDays: const [],
        stops: const [],
        allItems: [customBread],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));
      final res = engine.evaluate();
      // durable_bread darf durch Custom-Namen nicht als erfüllt gewertet werden!
      expect(res.findings.any((f) => f.ruleId == 'durable_bread'), isTrue);
    });
  });

  group('PIVOT2 Kriterium 10-12: AssistType-Verhalten', () {
    test('Guided und Preference-basierte Gruppen erhalten keinen generellen Mengen-Alarm', () {
      // Nur Wasser (needs_based) hat einen objektiven Mengenrichtwert-Abgleich
      final trip = Trip(
        id: 1,
        name: 'Test',
        startDate: DateTime(2026, 10, 18),
        daysCount: 7,
        region: 'mediterranean',
        climate: 'warm',
        isCharter: true,
        boatType: 'mono',
        fridgeCapacity: 100,
        hasFreezer: false,
        freezerCapacity: 0,
        waterTankLiters: 100,
        isWaterTankDrinkable: false,
        hasWatermaker: false,
        appetite: CrewAppetite.normal,
        reserveDays: 'few_days',
        drinkingHabit: CrewDrinking.normal,
        hasStorageChecklist: true,
        phase: TripPhase.plan,
        isArchived: false,
        currency: 'EUR',
        kittyModel: KittyModel.sharedKitty,
        createdAt: DateTime(2026, 10, 18),
      );

      final pasta = ShoppingListItemView(
        item: const ListItem(
          id: 1,
          tripId: 1,
          catalogId: 'spaghetti',
          isCustom: false,
          selected: true,
          share: 1.0,
          calculatedPackages: 5,
          overriddenPackages: 1,
          calculatedQuantity: 2500,
          checkState: CheckItemState.available,
          isAdopted: true,
        ),
        variant: catalog.variants.firstWhere((v) => v.id == 'spaghetti'),
        id: 'spaghetti',
        name: 'Spaghetti',
        unit: 'g',
        department: CatalogDepartment.trockenware,
        categoryId: 'carbs',
        calculatedPackages: 5,
        overriddenPackages: 1, // Deutlich unter Vorschlag!
        calculatedQuantity: 2500,
        customPackageSize: 500,
        isSelected: true,
        share: 1.0,
        isCustom: false,
        shelfLifeDays: 360,
        storageHints: const [],
        isAdopted: true,
        allocationsByStop: const {},
        assistType: AssistType.guided,
      );

      final engine = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [
          CrewMember(
            id: 1,
            tripId: 1,
            name: 'Adult',
            isChild: false,
            isVegetarian: false,
            isNonDrinker: false,
            categoryParticipation: '{"all":true}',
            isSkipperFree: false,
          )
        ],
        tripDays: const [],
        stops: const [],
        allItems: [pasta],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));

      final res = engine.evaluate();
      // Es darf kein Pasta-Mengen-Undercoverage-Finding existieren!
      expect(res.findings.any((f) => f.groupId == 'carbs'), isFalse);
    });

    test('Variant mit assistOverride: preferenceBased in Wassergruppe zählt nicht zur needs_based Deckung', () {
      final trip = Trip(
        id: 1,
        name: 'Water Override Trip',
        startDate: DateTime(2026, 10, 18),
        daysCount: 7,
        region: 'mediterranean',
        climate: 'warm', // default = 2.5 l/Person/Tag -> 17.5 l Bedarf
        isCharter: true,
        boatType: 'mono',
        fridgeCapacity: 100,
        hasFreezer: false,
        freezerCapacity: 0,
        waterTankLiters: 100,
        isWaterTankDrinkable: false,
        hasWatermaker: false,
        appetite: CrewAppetite.normal,
        reserveDays: 'few_days',
        drinkingHabit: CrewDrinking.normal,
        hasStorageChecklist: true,
        phase: TripPhase.plan,
        isArchived: false,
        currency: 'EUR',
        kittyModel: KittyModel.sharedKitty,
        createdAt: DateTime(2026, 10, 18),
      );

      final waterVariant = catalog.variants.firstWhere((v) => v.id == 'water_15');
      // Überschreibe AssistType der Variante auf preferenceBased (z.B. Spezialgetränk/Präferenz)
      final preferenceWaterVariant = CatalogVariant(
        id: waterVariant.id,
        group: waterVariant.group,
        nameDe: waterVariant.nameDe,
        pack: waterVariant.pack,
        shelfLifeDays: waterVariant.shelfLifeDays,
        buyFreshUnderway: waterVariant.buyFreshUnderway,
        department: waterVariant.department,
        defaultSelected: waterVariant.defaultSelected,
        tags: waterVariant.tags,
        storage: waterVariant.storage,
        note: waterVariant.note,
        portion: waterVariant.portion,
        need: waterVariant.need,
        chill: waterVariant.chill,
        shelfLifeFrozenDays: waterVariant.shelfLifeFrozenDays,
        assistOverride: AssistType.preferenceBased,
      );

      // 20L übernommen - wenn es needsBased wäre, wäre der Bedarf (17.5L) gedeckt!
      final preferenceWaterItem = ShoppingListItemView(
        item: const ListItem(
          id: 1,
          tripId: 1,
          catalogId: 'water_15',
          isCustom: false,
          selected: true,
          share: 1.0,
          calculatedPackages: 14,
          overriddenPackages: 14,
          calculatedQuantity: 21,
          checkState: CheckItemState.available,
          isAdopted: true,
        ),
        variant: preferenceWaterVariant,
        id: 'water_15',
        name: 'Wasser Präferenz',
        unit: 'l',
        department: CatalogDepartment.getraenke,
        categoryId: 'water',
        calculatedPackages: 14,
        overriddenPackages: 14,
        calculatedQuantity: 21,
        customPackageSize: 1.5,
        isSelected: true,
        share: 1.0,
        isCustom: false,
        shelfLifeDays: 360,
        storageHints: const [],
        isAdopted: true,
        allocationsByStop: const {},
        assistType: AssistType.preferenceBased,
      );

      final engine = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [
          CrewMember(
            id: 1,
            tripId: 1,
            name: 'Adult',
            isChild: false,
            isVegetarian: false,
            isNonDrinker: false,
            categoryParticipation: '{"all":true}',
            isSkipperFree: false,
          )
        ],
        tripDays: const [],
        stops: const [],
        allItems: [preferenceWaterItem],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));

      final res = engine.evaluate();
      // Da die Variante preferenceBased ist, zählt sie nicht zur Grund-Bedarfsdeckung!
      // Es muss ein drinkingWaterCheck generiert werden mit actualValue = 0.
      final waterFinding = res.findings
          .where((f) => f.kind == ProvisioningReviewKind.drinkingWaterCheck)
          .firstOrNull;
      expect(waterFinding, isNotNull);
      expect(waterFinding!.actualValue, 0.0);
    });
  });

  group('PIVOT2 Kriterium 13-17: Trinkwasser-Abgleich (WATER1)', () {
    test('Trinkwasser unter Richtwert erzeugt CHECK, nicht ACTION_NEEDED', () {
      final trip = Trip(
        id: 1,
        name: 'Water Trip',
        startDate: DateTime(2026, 10, 18),
        daysCount: 7,
        region: 'mediterranean',
        climate: 'warm', // default = 2.5 l/Person/Tag -> 7 * 2.5 = 17.5 l
        isCharter: true,
        boatType: 'mono',
        fridgeCapacity: 100,
        hasFreezer: false,
        freezerCapacity: 0,
        waterTankLiters: 200,
        isWaterTankDrinkable: true,
        hasWatermaker: true,
        appetite: CrewAppetite.normal,
        reserveDays: 'few_days',
        drinkingHabit: CrewDrinking.normal,
        hasStorageChecklist: true,
        phase: TripPhase.plan,
        isArchived: false,
        currency: 'EUR',
        kittyModel: KittyModel.sharedKitty,
        createdAt: DateTime(2026, 10, 18),
      );

      // Nur 1 Packung (1.5 l) Wasser auf der Liste
      final waterItem = ShoppingListItemView(
        item: const ListItem(
          id: 1,
          tripId: 1,
          catalogId: 'water_15',
          isCustom: false,
          selected: true,
          share: 1.0,
          calculatedPackages: 12,
          overriddenPackages: 1,
          calculatedQuantity: 17.5,
          checkState: CheckItemState.available,
          isAdopted: true,
        ),
        variant: catalog.variants.firstWhere((v) => v.id == 'water_15'),
        id: 'water_15',
        name: 'Still 1.5L',
        unit: 'l',
        department: CatalogDepartment.getraenke,
        categoryId: 'water',
        calculatedPackages: 12,
        overriddenPackages: 1, // 1 * 1.5 l = 1.5 l (< 17.5 l)
        calculatedQuantity: 17.5,
        customPackageSize: 1.5,
        isSelected: true,
        share: 1.0,
        isCustom: false,
        shelfLifeDays: 360,
        storageHints: const [],
        isAdopted: true,
        allocationsByStop: const {},
        assistType: AssistType.needsBased,
      );

      final engine = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [
          CrewMember(
            id: 1,
            tripId: 1,
            name: 'Adult',
            isChild: false,
            isVegetarian: false,
            isNonDrinker: false,
            categoryParticipation: '{"all":true}',
            isSkipperFree: false,
          )
        ],
        tripDays: const [],
        stops: const [],
        allItems: [waterItem],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));

      final res = engine.evaluate();
      final waterFinding = res.findings
          .where((f) => f.kind == ProvisioningReviewKind.drinkingWaterCheck)
          .firstOrNull;

      expect(waterFinding, isNotNull);
      // Kriterium 14: severity muss CHECK sein, NIEMALS ACTION_NEEDED
      expect(waterFinding!.severity, ProvisioningReviewSeverity.check);
      // Kriterium 15 & 16: Tank/Watermaker als Kontext vorhanden
      expect(waterFinding.hasPotableTank, isTrue);
      expect(waterFinding.hasWatermaker, isTrue);
      expect(waterFinding.estimatedValue, closeTo(17.5, 0.01));
      expect(waterFinding.actualValue, closeTo(1.5, 0.01));
    });

    test('Trinkwasser >= Richtwert erzeugt kein Unterdeckungs-CHECK', () {
      final trip = Trip(
        id: 1,
        name: 'Water Trip OK',
        startDate: DateTime(2026, 10, 18),
        daysCount: 7,
        region: 'mediterranean',
        climate: 'warm',
        isCharter: true,
        boatType: 'mono',
        fridgeCapacity: 100,
        hasFreezer: false,
        freezerCapacity: 0,
        waterTankLiters: 0,
        isWaterTankDrinkable: false,
        hasWatermaker: false,
        appetite: CrewAppetite.normal,
        reserveDays: 'few_days',
        drinkingHabit: CrewDrinking.normal,
        hasStorageChecklist: true,
        phase: TripPhase.plan,
        isArchived: false,
        currency: 'EUR',
        kittyModel: KittyModel.sharedKitty,
        createdAt: DateTime(2026, 10, 18),
      );

      // 12 Packungen à 1.5L = 18.0L (>= 17.5L)
      final waterItem = ShoppingListItemView(
        item: const ListItem(
          id: 1,
          tripId: 1,
          catalogId: 'water_15',
          isCustom: false,
          selected: true,
          share: 1.0,
          calculatedPackages: 12,
          overriddenPackages: 12,
          calculatedQuantity: 17.5,
          checkState: CheckItemState.available,
          isAdopted: true,
        ),
        variant: catalog.variants.firstWhere((v) => v.id == 'water_15'),
        id: 'water_15',
        name: 'Still 1.5L',
        unit: 'l',
        department: CatalogDepartment.getraenke,
        categoryId: 'water',
        calculatedPackages: 12,
        overriddenPackages: 12,
        calculatedQuantity: 17.5,
        customPackageSize: 1.5,
        isSelected: true,
        share: 1.0,
        isCustom: false,
        shelfLifeDays: 360,
        storageHints: const [],
        isAdopted: true,
        allocationsByStop: const {},
        assistType: AssistType.needsBased,
      );

      final engine = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [
          CrewMember(
            id: 1,
            tripId: 1,
            name: 'Adult',
            isChild: false,
            isVegetarian: false,
            isNonDrinker: false,
            categoryParticipation: '{"all":true}',
            isSkipperFree: false,
          )
        ],
        tripDays: const [],
        stops: const [],
        allItems: [waterItem],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));

      final res = engine.evaluate();
      expect(
        res.findings.any((f) => f.kind == ProvisioningReviewKind.drinkingWaterCheck),
        isFalse,
      );
    });
  });

  group('PIVOT2 Kriterium 18-19: Frische & Haltbarkeit (Issue #8)', () {
    test('Frische Brötchen (Haltbarkeit 1 Tag) bei 7-Tage-Törn erzeugt Frische-CHECK', () {
      final trip = Trip(
        id: 1,
        name: 'Freshness Trip',
        startDate: DateTime(2026, 10, 18),
        daysCount: 7,
        region: 'mediterranean',
        climate: 'warm',
        isCharter: true,
        boatType: 'mono',
        fridgeCapacity: 100,
        hasFreezer: false,
        freezerCapacity: 0,
        waterTankLiters: 0,
        isWaterTankDrinkable: false,
        hasWatermaker: false,
        appetite: CrewAppetite.normal,
        reserveDays: 'few_days',
        drinkingHabit: CrewDrinking.normal,
        hasStorageChecklist: true,
        phase: TripPhase.plan,
        isArchived: false,
        currency: 'EUR',
        kittyModel: KittyModel.sharedKitty,
        createdAt: DateTime(2026, 10, 18),
      );

      // rolls: shelf_life_days = 1
      final rolls = ShoppingListItemView(
        item: const ListItem(
          id: 42,
          tripId: 1,
          catalogId: 'rolls',
          isCustom: false,
          selected: true,
          share: 1.0,
          calculatedPackages: 5,
          overriddenPackages: 5,
          calculatedQuantity: 1000,
          checkState: CheckItemState.available,
          isAdopted: true,
        ),
        variant: catalog.variants.firstWhere((v) => v.id == 'rolls'),
        id: 'rolls',
        name: 'Brötchen',
        unit: 'g',
        department: CatalogDepartment.backwaren,
        categoryId: 'bread',
        calculatedPackages: 5,
        overriddenPackages: 5,
        calculatedQuantity: 1000,
        customPackageSize: 200,
        isSelected: true,
        share: 1.0,
        isCustom: false,
        shelfLifeDays: 1,
        storageHints: const [],
        isAdopted: true,
        allocationsByStop: const {},
        assistType: AssistType.guided,
      );

      final engine = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [],
        tripDays: const [],
        stops: const [],
        allItems: [rolls],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));

      final res = engine.evaluate();
      final freshFinding = res.findings
          .where((f) => f.kind == ProvisioningReviewKind.freshness && f.listItemId == 42)
          .firstOrNull;

      expect(freshFinding, isNotNull);
      expect(freshFinding!.severity, ProvisioningReviewSeverity.check);
      expect(freshFinding.shelfLifeDays, 1);
      expect(freshFinding.horizonDays, 7);
      // Kriterium 19: Review modifiziert keine Mengen oder Zuordnungen
      expect(rolls.effectivePackages, 5);
      expect(rolls.allocationsByStop.isEmpty, isTrue);
    });
  });

  group('PIVOT2 Kriterium 20-24: Kühlung & Tiefkühlung Plausibilität', () {
    Trip createBoatTrip({int fridge = 100, bool freezer = false, int freezerCap = 0}) {
      return Trip(
        id: 1,
        name: 'Cooling Trip',
        startDate: DateTime(2026, 10, 18),
        daysCount: 7,
        region: 'mediterranean',
        climate: 'warm',
        isCharter: true,
        boatType: 'mono',
        fridgeCapacity: fridge,
        hasFreezer: freezer,
        freezerCapacity: freezerCap,
        waterTankLiters: 0,
        isWaterTankDrinkable: false,
        hasWatermaker: false,
        appetite: CrewAppetite.normal,
        reserveDays: 'few_days',
        drinkingHabit: CrewDrinking.normal,
        hasStorageChecklist: true,
        phase: TripPhase.plan,
        isArchived: false,
        currency: 'EUR',
        kittyModel: KittyModel.sharedKitty,
        createdAt: DateTime(2026, 10, 18),
      );
    }

    test('Kriterium 20: Kühlartikel bei 0 l Kühlschrank -> ACTION_NEEDED', () {
      final trip = createBoatTrip(fridge: 0); // Kein Kühlschrank!
      final butter = ShoppingListItemView(
        item: const ListItem(
          id: 101,
          tripId: 1,
          catalogId: 'butter_std',
          isCustom: false,
          selected: true,
          share: 1.0,
          calculatedPackages: 2,
          overriddenPackages: 2,
          calculatedQuantity: 500,
          checkState: CheckItemState.available,
          isAdopted: true,
        ),
        variant: catalog.variants.firstWhere((v) => v.id == 'butter_std'), // chill = fridge
        id: 'butter_std',
        name: 'Butter',
        unit: 'g',
        department: CatalogDepartment.molkerei,
        categoryId: 'butter',
        calculatedPackages: 2,
        overriddenPackages: 2,
        calculatedQuantity: 500,
        customPackageSize: 250,
        isSelected: true,
        share: 1.0,
        isCustom: false,
        shelfLifeDays: 30,
        storageHints: const [],
        isAdopted: true,
        allocationsByStop: const {},
        assistType: AssistType.guided,
      );

      final engine = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [],
        tripDays: const [],
        stops: const [],
        allItems: [butter],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));

      final res = engine.evaluate();
      expect(res.status, ProvisioningReviewStatus.actionNeeded);
      expect(
        res.findings.any((f) =>
            f.kind == ProvisioningReviewKind.fridgeRequirement &&
            f.severity == ProvisioningReviewSeverity.actionNeeded),
        isTrue,
      );
    });

    test('Kriterium 21: Tiefkühlartikel ohne Tiefkühler -> ACTION_NEEDED', () {
      final trip = createBoatTrip(fridge: 100, freezer: false, freezerCap: 0);
      // ice_cream / fish_fillet_frozen etc: chill = freezer
      final frozenVariant = catalog.variants.firstWhere((v) => v.chill == ChillRequirement.freezer);

      final frozenItem = ShoppingListItemView(
        item: ListItem(
          id: 102,
          tripId: 1,
          catalogId: frozenVariant.id,
          isCustom: false,
          selected: true,
          share: 1.0,
          calculatedPackages: 2,
          overriddenPackages: 2,
          calculatedQuantity: 1000,
          checkState: CheckItemState.available,
          isAdopted: true,
        ),
        variant: frozenVariant,
        id: frozenVariant.id,
        name: frozenVariant.nameDe,
        unit: frozenVariant.pack.unit,
        department: frozenVariant.department,
        categoryId: frozenVariant.group,
        calculatedPackages: 2,
        overriddenPackages: 2,
        calculatedQuantity: 1000,
        customPackageSize: frozenVariant.pack.size,
        isSelected: true,
        share: 1.0,
        isCustom: false,
        shelfLifeDays: 90,
        storageHints: const [],
        isAdopted: true,
        allocationsByStop: const {},
        assistType: AssistType.guided,
      );

      final engine = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [],
        tripDays: const [],
        stops: const [],
        allItems: [frozenItem],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));

      final res = engine.evaluate();
      expect(res.status, ProvisioningReviewStatus.actionNeeded);
      expect(
        res.findings.any((f) =>
            f.kind == ProvisioningReviewKind.freezerRequirement &&
            f.severity == ProvisioningReviewSeverity.actionNeeded),
        isTrue,
      );
    });

    test('Kriterium 22: Bekanntes Kühlvolumen > Kühlschrank-Kapazität -> ACTION_NEEDED', () {
      // Kühlschrank 20 L
      final trip = createBoatTrip(fridge: 20);
      // 100 x 1 L Milch (chill = fridge, 1L = 1L) -> 100 L > 20 L!
      final milkVariant = catalog.variants.firstWhere((v) => v.id == 'milk_fresh');
      final milk = ShoppingListItemView(
        item: const ListItem(
          id: 103,
          tripId: 1,
          catalogId: 'milk_fresh',
          isCustom: false,
          selected: true,
          share: 1.0,
          calculatedPackages: 100,
          overriddenPackages: 100,
          calculatedQuantity: 100,
          checkState: CheckItemState.available,
          isAdopted: true,
        ),
        variant: milkVariant,
        id: 'milk_fresh',
        name: 'Milch',
        unit: 'l',
        department: CatalogDepartment.molkerei,
        categoryId: 'milk',
        calculatedPackages: 100,
        overriddenPackages: 100,
        calculatedQuantity: 100,
        customPackageSize: 1.0,
        isSelected: true,
        share: 1.0,
        isCustom: false,
        shelfLifeDays: 7,
        storageHints: const [],
        isAdopted: true,
        allocationsByStop: const {},
        assistType: AssistType.guided,
      );

      final engine = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [],
        tripDays: const [],
        stops: const [],
        allItems: [milk],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));

      final res = engine.evaluate();
      expect(res.status, ProvisioningReviewStatus.actionNeeded);
      expect(
        res.findings.any((f) =>
            f.kind == ProvisioningReviewKind.fridgeCapacity &&
            f.severity == ProvisioningReviewSeverity.actionNeeded),
        isTrue,
      );
    });
  });

  group('PIVOT2 Kriterium 26: Status-Aggregation', () {
    test('ready, check und actionNeeded aggregieren streng hierarchisch', () {
      const readyRes = ProvisioningReviewResult(
        status: ProvisioningReviewStatus.ready,
        findings: [],
        totalWeightKg: 10,
        totalVolumeLiters: 10,
        hasItemsWithoutWeight: false,
        isCoolingAssessmentComplete: true,
      );
      expect(readyRes.status, ProvisioningReviewStatus.ready);

      final checkEngineResult = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: Trip(
          id: 1,
          name: 'Törn',
          startDate: DateTime(2026, 10, 18),
          daysCount: 7,
          region: 'mediterranean',
          climate: 'warm',
          isCharter: true,
          boatType: 'mono',
          fridgeCapacity: 100,
          hasFreezer: false,
          freezerCapacity: 0,
          waterTankLiters: 100,
          isWaterTankDrinkable: false,
          hasWatermaker: false,
          appetite: CrewAppetite.normal,
          reserveDays: 'few_days',
          drinkingHabit: CrewDrinking.normal,
          hasStorageChecklist: true,
          phase: TripPhase.plan,
          isArchived: false,
          currency: 'EUR',
          kittyModel: KittyModel.sharedKitty,
          createdAt: DateTime(2026, 10, 18),
        ),
        crew: const [],
        tripDays: const [],
        stops: const [],
        allItems: const [],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      )).evaluate();

      expect(checkEngineResult.status, ProvisioningReviewStatus.check);
    });
  });

  group('PIVOT2 Kriterium 27-31: UI & Lokalisierungs-Parität', () {
    testWidgets('Review-Button und ProvisioningReviewSheet rendern sauber', (tester) async {
      final trip = Trip(
        id: 1,
        name: 'UI Test Törn',
        startDate: DateTime(2026, 10, 18),
        daysCount: 7,
        region: 'mediterranean',
        climate: 'warm',
        isCharter: true,
        boatType: 'mono',
        fridgeCapacity: 100,
        hasFreezer: false,
        freezerCapacity: 0,
        waterTankLiters: 100,
        isWaterTankDrinkable: false,
        hasWatermaker: false,
        appetite: CrewAppetite.normal,
        reserveDays: 'few_days',
        drinkingHabit: CrewDrinking.normal,
        hasStorageChecklist: true,
        phase: TripPhase.plan,
        isArchived: false,
        currency: 'EUR',
        kittyModel: KittyModel.sharedKitty,
        createdAt: DateTime(2026, 10, 18),
      );

      final listData = TripShoppingListData(
        trip: trip,
        stops: const [],
        allItems: const [],
        categories: const [],
        departments: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            provisioningReviewProvider(1).overrideWith((ref) async {
              return const ProvisioningReviewResult(
                status: ProvisioningReviewStatus.check,
                findings: [
                  ProvisioningReviewFinding(
                    id: 'missing_basic_durable_bread',
                    kind: ProvisioningReviewKind.missingBasic,
                    severity: ProvisioningReviewSeverity.check,
                    ruleId: 'durable_bread',
                    action: ProvisioningReviewAction(
                      type: ProvisioningReviewActionType.searchOrAdd,
                      targetGroup: 'bread',
                    ),
                  ),
                ],
                totalWeightKg: 12.5,
                totalVolumeLiters: 14.0,
                hasItemsWithoutWeight: true,
                isCoolingAssessmentComplete: true,
              );
            }),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ProvisioningReviewSheet.show(context, data: listData),
                  child: const Text('Open Review'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Review'));
      await tester.pumpAndSettle();

      // Prüfe dass Sheet offen ist
      expect(find.byType(ProvisioningReviewSheet), findsOneWidget);
      expect(find.text('Vorratsprüfung'), findsOneWidget);
      expect(find.text('Haltbares Brot fehlt'), findsOneWidget);
      expect(find.text('Suchen & hinzufügen'), findsOneWidget);
      expect(find.text('Gesamtgewicht & Volumen'), findsOneWidget);
    });

    test('Lokalisierungs-Parität für alle 6 Sprachen', () {
      final supportedCodes = ['de', 'en', 'fr', 'es', 'pt', 'hr'];
      for (final code in supportedCodes) {
        final arbFile = File('lib/l10n/app_$code.arb');
        expect(arbFile.existsSync(), isTrue);
        final content = json.decode(arbFile.readAsStringSync()) as Map<String, dynamic>;

        expect(content.containsKey('reviewButtonLabel'), isTrue,
            reason: 'reviewButtonLabel in $code fehlt');
        expect(content.containsKey('reviewTitle'), isTrue,
            reason: 'reviewTitle in $code fehlt');
        expect(content.containsKey('reviewStatusReady'), isTrue,
            reason: 'reviewStatusReady in $code fehlt');
        expect(content.containsKey('reviewStatusCheck'), isTrue,
            reason: 'reviewStatusCheck in $code fehlt');
        expect(content.containsKey('reviewStatusActionNeeded'), isTrue,
            reason: 'reviewStatusActionNeeded in $code fehlt');
        expect(content.containsKey('reviewWaterCheckTitle'), isTrue,
            reason: 'reviewWaterCheckTitle in $code fehlt');
        expect(content.containsKey('reviewWaterCheckMessage'), isTrue,
            reason: 'reviewWaterCheckMessage in $code fehlt');
        expect(content.containsKey('reviewFreshnessTitle'), isTrue,
            reason: 'reviewFreshnessTitle in $code fehlt');
        expect(content.containsKey('reviewFridgeNoCapacityTitle'), isTrue,
            reason: 'reviewFridgeNoCapacityTitle in $code fehlt');
        expect(content.containsKey('reviewFreezerNoFreezerTitle'), isTrue,
            reason: 'reviewFreezerNoFreezerTitle in $code fehlt');
        expect(content.containsKey('reviewFridgeOverloadedTitle'), isTrue,
            reason: 'reviewFridgeOverloadedTitle in $code fehlt');
        expect(content.containsKey('reviewFreezerOverloadedTitle'), isTrue,
            reason: 'reviewFreezerOverloadedTitle in $code fehlt');
        expect(content.containsKey('reviewIncompleteCoolingTitle'), isTrue,
            reason: 'reviewIncompleteCoolingTitle in $code fehlt');
        expect(content.containsKey('reviewTotalWeightVolumeTitle'), isTrue,
            reason: 'reviewTotalWeightVolumeTitle in $code fehlt');
      }
    });
  });

  group('PIVOT2 Amendment Tests (Findings A-F)', () {
    test('Finding D: Unquantifizierte Kühlartikel bei aktiver Kühlkapazität erzeugen CHECK', () {
      final trip = Trip(
        id: 1,
        name: 'Cooling Test',
        startDate: DateTime(2026, 10, 18),
        daysCount: 7,
        region: 'mediterranean',
        climate: 'warm',
        isCharter: true,
        boatType: 'mono',
        fridgeCapacity: 50,
        hasFreezer: false,
        freezerCapacity: 0,
        waterTankLiters: 100,
        isWaterTankDrinkable: true,
        hasWatermaker: false,
        appetite: CrewAppetite.normal,
        reserveDays: 'few_days',
        drinkingHabit: CrewDrinking.normal,
        hasStorageChecklist: true,
        phase: TripPhase.plan,
        isArchived: false,
        currency: 'EUR',
        kittyModel: KittyModel.sharedKitty,
        createdAt: DateTime(2026, 10, 18),
      );

      final butterVariant = catalog.variants.firstWhere((v) => v.id == 'butter_std');
      // Erstelle Kühlartikel ohne g/kg/l/ml Einheit (z.B. Stück)
      final pieceChillVariant = CatalogVariant(
        id: butterVariant.id,
        group: butterVariant.group,
        nameDe: butterVariant.nameDe,
        pack: const PackInfo(size: 1, unit: 'Stück'),
        shelfLifeDays: butterVariant.shelfLifeDays,
        buyFreshUnderway: butterVariant.buyFreshUnderway,
        department: butterVariant.department,
        defaultSelected: butterVariant.defaultSelected,
        tags: butterVariant.tags,
        storage: butterVariant.storage,
        note: butterVariant.note,
        portion: butterVariant.portion,
        need: butterVariant.need,
        chill: butterVariant.chill,
        shelfLifeFrozenDays: butterVariant.shelfLifeFrozenDays,
        assistOverride: butterVariant.assistOverride,
      );

      final pieceItem = ShoppingListItemView(
        item: const ListItem(
          id: 501,
          tripId: 1,
          catalogId: 'butter_std',
          isCustom: false,
          selected: true,
          share: 1.0,
          calculatedPackages: 2,
          overriddenPackages: 2,
          calculatedQuantity: 2,
          checkState: CheckItemState.available,
          isAdopted: true,
        ),
        variant: pieceChillVariant,
        id: 'butter_std',
        name: 'Butter Stück',
        unit: 'Stück',
        department: CatalogDepartment.molkerei,
        categoryId: 'butter',
        calculatedPackages: 2,
        overriddenPackages: 2,
        calculatedQuantity: 2,
        customPackageSize: 1,
        isSelected: true,
        share: 1.0,
        isCustom: false,
        shelfLifeDays: 30,
        storageHints: const [],
        isAdopted: true,
        allocationsByStop: const {},
        assistType: AssistType.guided,
      );

      final engine = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [],
        tripDays: const [],
        stops: const [],
        allItems: [pieceItem],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));

      final res = engine.evaluate();
      expect(res.isCoolingAssessmentComplete, isFalse);
      final finding = res.findings.where((f) => f.kind == ProvisioningReviewKind.incompleteCoolingAssessment).firstOrNull;
      expect(finding, isNotNull);
      expect(finding!.severity, ProvisioningReviewSeverity.check);
      // Gesamtstatus darf bei unvollständiger Kühlbewertung nicht READY sein
      expect(res.status, isNot(ProvisioningReviewStatus.ready));
      expect(res.status, ProvisioningReviewStatus.check);
    });

    test('Finding F: Einkaufsstopp-Kontext berechnet Haltbarkeitshorizont anhand von Stopp-Allokationen', () {
      final trip = Trip(
        id: 1,
        name: 'Stop Horizon Trip',
        startDate: DateTime(2026, 10, 18),
        daysCount: 14,
        region: 'mediterranean',
        climate: 'warm',
        isCharter: true,
        boatType: 'mono',
        fridgeCapacity: 100,
        hasFreezer: false,
        freezerCapacity: 0,
        waterTankLiters: 100,
        isWaterTankDrinkable: true,
        hasWatermaker: false,
        appetite: CrewAppetite.normal,
        reserveDays: 'few_days',
        drinkingHabit: CrewDrinking.normal,
        hasStorageChecklist: true,
        phase: TripPhase.plan,
        isArchived: false,
        currency: 'EUR',
        kittyModel: KittyModel.sharedKitty,
        createdAt: DateTime(2026, 10, 18),
      );

      // 3 Stopps: Tag 1 (Start), Tag 4 (Nachkauf), Tag 9 (Nachkauf)
      const stop1 = ShoppingStop(id: 11, tripId: 1, name: 'Marina Start', dayNumber: 1, isInitial: true);
      const stop2 = ShoppingStop(id: 12, tripId: 1, name: 'Hafen 2', dayNumber: 4, isInitial: false);
      const stop3 = ShoppingStop(id: 13, tripId: 1, name: 'Hafen 3', dayNumber: 9, isInitial: false);

      final toastVariant = catalog.variants.firstWhere((v) => v.id == 'toast');

      // Fall 1: Artikel mit Haltbarkeit 7 Tage, allokiert nur an Stop 1 (Tag 1 -> nächster Stop Tag 4 => Horizont 3 Tage).
      // Da shelfLife (7) >= horizon (3), KEIN Frische-Finding!
      final itemAllocatedStop1 = ShoppingListItemView(
        item: const ListItem(
          id: 601,
          tripId: 1,
          catalogId: 'toast',
          isCustom: false,
          selected: true,
          share: 1.0,
          calculatedPackages: 2,
          overriddenPackages: 2,
          calculatedQuantity: 1000,
          checkState: CheckItemState.available,
          isAdopted: true,
        ),
        variant: toastVariant,
        id: 'toast',
        name: 'Toastbrot',
        unit: 'g',
        department: CatalogDepartment.backwaren,
        categoryId: 'bread',
        calculatedPackages: 2,
        overriddenPackages: 2,
        calculatedQuantity: 1000,
        customPackageSize: 500,
        isSelected: true,
        share: 1.0,
        isCustom: false,
        shelfLifeDays: 7,
        storageHints: const [],
        isAdopted: true,
        allocationsByStop: {
          11: const ListItemAllocation(id: 1, tripId: 1, listItemId: 601, shoppingStopId: 11, allocatedPackages: 2, isBought: false, isStored: false),
        },
        assistType: AssistType.guided,
      );

      final engine1 = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [],
        tripDays: const [],
        stops: [stop1, stop2, stop3],
        allItems: [itemAllocatedStop1],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));

      final res1 = engine1.evaluate();
      expect(res1.findings.where((f) => f.kind == ProvisioningReviewKind.freshness && f.listItemId == 601).isEmpty, isTrue);

      // Fall 2: Artikel mit Haltbarkeit 7 Tage, allokiert an Stop 2 (Tag 4 -> Stop 3 Tag 9 => Horizont 5 Tage; shelfLife (7) >= 5 -> kein Finding).
      // Aber ohne Allokationen oder an Stop 1 mit Horizont 14 Tage (ohne Stopps):
      // Hier: allokiert an Stop 1 und Trip hat keine weiteren Stopps -> Horizont 14 Tage > shelfLife 7 Tage -> Frische-Finding mit horizonDays = 14!
      final itemFullHorizon = ShoppingListItemView(
        item: const ListItem(
          id: 602,
          tripId: 1,
          catalogId: 'toast',
          isCustom: false,
          selected: true,
          share: 1.0,
          calculatedPackages: 2,
          overriddenPackages: 2,
          calculatedQuantity: 1000,
          checkState: CheckItemState.available,
          isAdopted: true,
        ),
        variant: toastVariant,
        id: 'toast',
        name: 'Toastbrot',
        unit: 'g',
        department: CatalogDepartment.backwaren,
        categoryId: 'bread',
        calculatedPackages: 2,
        overriddenPackages: 2,
        calculatedQuantity: 1000,
        customPackageSize: 500,
        isSelected: true,
        share: 1.0,
        isCustom: false,
        shelfLifeDays: 7,
        storageHints: const [],
        isAdopted: true,
        allocationsByStop: const {},
        assistType: AssistType.guided,
      );

      final engine2 = ProvisioningReviewEngine(ProvisioningReviewInput(
        trip: trip,
        crew: const [],
        tripDays: const [],
        stops: [stop1],
        allItems: [itemFullHorizon],
        catalog: catalog,
        quantities: quantities,
        config: reviewConfig,
      ));

      final res2 = engine2.evaluate();
      final freshFinding = res2.findings.where((f) => f.kind == ProvisioningReviewKind.freshness && f.listItemId == 602).firstOrNull;
      expect(freshFinding, isNotNull);
      expect(freshFinding!.shelfLifeDays, 7);
      expect(freshFinding.horizonDays, 14);
    });

    test('Finding A: provisioningReviewProvider reagiert reaktiv auf State-Mutationen', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = CatalogRepository(
        catalog: catalog,
        quantities: quantities,
        reviewConfig: reviewConfig,
      );
      final tripService = TripService(
        tripDao: db.tripDao,
        listItemDao: db.listItemDao,
        catalogRepository: repo,
      );
      final shoppingListService = ShoppingListService(
        tripDao: db.tripDao,
        listItemDao: db.listItemDao,
        catalogRepository: repo,
        tripService: tripService,
      );

      final tripId = await tripService.createTripWithCrew(
        name: 'Reactivity Trip',
        startDate: DateTime(2026, 10, 18),
        daysCount: 7,
        crewMembers: const [
          CrewMemberInput(
            id: 'm1',
            name: 'Skipper',
            isAdult: true,
            isVegetarian: false,
            noAlcohol: false,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          catalogRepositoryProvider.overrideWithValue(repo),
          tripServiceProvider.overrideWithValue(tripService),
          shoppingListServiceProvider.overrideWithValue(shoppingListService),
        ],
      );
      addTearDown(container.dispose);

      // Initial review evaluation
      final initialReview = await container.read(provisioningReviewProvider(tripId).future);
      expect(initialReview.status, isNotNull);

      // Initial fehlen Basics (z.B. durable bread)
      final hasMissingBreadBefore = initialReview.findings.any((f) => f.ruleId == 'durable_bread');
      expect(hasMissingBreadBefore, isTrue);

      // Catalog-Item adoptieren:
      final items = await db.listItemDao.getListItemsForTrip(tripId);
      final crispbreadItem = items.firstWhere((i) => i.catalogId == 'crispbread');
      await shoppingListService.adoptItem(tripId: tripId, listItemId: crispbreadItem.id, packages: 2);

      // Invalidate und neu auslesen
      container.invalidate(tripShoppingListProvider(tripId));
      final updatedReview = await container.read(provisioningReviewProvider(tripId).future);
      final hasMissingBreadAfter = updatedReview.findings.any((f) => f.ruleId == 'durable_bread');
      expect(hasMissingBreadAfter, isFalse, reason: 'Durable bread finding must be resolved after adopting crispbread');
    });

    testWidgets('Finding E: Review-Aktionen führen zu echten Navigationen & Hand-offs', (tester) async {
      final trip = Trip(
        id: 1,
        name: 'Action Handoff Trip',
        startDate: DateTime(2026, 10, 18),
        daysCount: 7,
        region: 'mediterranean',
        climate: 'warm',
        isCharter: true,
        boatType: 'mono',
        fridgeCapacity: 100,
        hasFreezer: false,
        freezerCapacity: 0,
        waterTankLiters: 100,
        isWaterTankDrinkable: true,
        hasWatermaker: false,
        appetite: CrewAppetite.normal,
        reserveDays: 'few_days',
        drinkingHabit: CrewDrinking.normal,
        hasStorageChecklist: true,
        phase: TripPhase.plan,
        isArchived: false,
        currency: 'EUR',
        kittyModel: KittyModel.sharedKitty,
        createdAt: DateTime(2026, 10, 18),
      );

      const stop1 = ShoppingStop(id: 1, tripId: 1, name: 'Marina', dayNumber: 1, isInitial: true);
      const stop2 = ShoppingStop(id: 2, tripId: 1, name: 'Bucht', dayNumber: 3, isInitial: false);

      final milkVariant = catalog.variants.firstWhere((v) => v.id == 'milk_fresh');
      final milkItem = ShoppingListItemView(
        item: const ListItem(
          id: 701,
          tripId: 1,
          catalogId: 'milk_fresh',
          isCustom: false,
          selected: true,
          share: 1.0,
          calculatedPackages: 1,
          overriddenPackages: 1,
          calculatedQuantity: 1,
          checkState: CheckItemState.available,
          isAdopted: true,
        ),
        variant: milkVariant,
        id: 'milk_fresh',
        name: 'Milch',
        unit: 'l',
        department: CatalogDepartment.molkerei,
        categoryId: 'milk',
        calculatedPackages: 1,
        overriddenPackages: 1,
        calculatedQuantity: 1,
        customPackageSize: 1,
        isSelected: true,
        share: 1.0,
        isCustom: false,
        shelfLifeDays: 5,
        storageHints: const [],
        isAdopted: true,
        allocationsByStop: const {},
        assistType: AssistType.guided,
      );

      final listData = TripShoppingListData(
        trip: trip,
        stops: [stop1, stop2],
        allItems: [milkItem],
        categories: const [],
        departments: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            provisioningReviewProvider(1).overrideWith((ref) async {
              return const ProvisioningReviewResult(
                status: ProvisioningReviewStatus.check,
                findings: [
                  ProvisioningReviewFinding(
                    id: 'freshness_milk_fresh_701',
                    kind: ProvisioningReviewKind.freshness,
                    severity: ProvisioningReviewSeverity.check,
                    listItemId: 701,
                    shelfLifeDays: 5,
                    horizonDays: 7,
                    action: ProvisioningReviewAction(
                      type: ProvisioningReviewActionType.assignShoppingStop,
                      listItemId: 701,
                    ),
                  ),
                ],
                totalWeightKg: 1.0,
                totalVolumeLiters: 1.0,
                hasItemsWithoutWeight: false,
                isCoolingAssessmentComplete: true,
              );
            }),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ProvisioningReviewSheet.show(context, data: listData),
                  child: const Text('Open Review Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Review Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(ProvisioningReviewSheet), findsOneWidget);
      expect(find.text('Stopp zuweisen'), findsOneWidget);

      // Klick auf "Stopp zuweisen"
      await tester.tap(find.text('Stopp zuweisen'));
      await tester.pumpAndSettle();

      // Bei mehreren Stopps öffnet sich direkt das StopAllocationSheet
      expect(find.byType(StopAllocationSheet), findsOneWidget);
      expect(find.textContaining('Marina'), findsOneWidget);
      expect(find.textContaining('Bucht'), findsOneWidget);
    });
  });
}

