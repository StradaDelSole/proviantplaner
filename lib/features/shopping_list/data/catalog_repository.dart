/// Repository zum Laden des Katalogs und der Mengenfaktoren (Slice S2).
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:proviantplaner/core/services/catalog_localization_service.dart';
import '../domain/calculation/quantity_engine.dart';
import '../domain/models/catalog_models.dart';
import '../domain/models/provisioning_review_models.dart';
import '../domain/models/quantities_models.dart';

class CatalogRepository {
  CatalogData? _catalog;
  QuantitiesData? _quantities;
  ProvisioningReviewConfig? _reviewConfig;

  CatalogData? get catalog => _catalog;
  QuantitiesData? get quantities => _quantities;
  ProvisioningReviewConfig? get reviewConfig => _reviewConfig;

  CatalogRepository({
    CatalogData? catalog,
    QuantitiesData? quantities,
    ProvisioningReviewConfig? reviewConfig,
  })  : _catalog = catalog,
        _quantities = quantities,
        _reviewConfig = reviewConfig;

  Future<void> loadFromBundle() async {
    String catalogString;
    String quantitiesString;
    String reviewConfigString;
    try {
      catalogString = await rootBundle.loadString('data/catalog_v0.11.json');
      quantitiesString = await rootBundle.loadString('data/quantities_v0.6.json');
      reviewConfigString =
          await rootBundle.loadString('data/provisioning_review_v0.1.json');
    } catch (_) {
      catalogString = File('data/catalog_v0.11.json').readAsStringSync();
      quantitiesString = File('data/quantities_v0.6.json').readAsStringSync();
      reviewConfigString =
          File('data/provisioning_review_v0.1.json').readAsStringSync();
    }
    loadFromJsonStrings(
      catalogJson: catalogString,
      quantitiesJson: quantitiesString,
      reviewConfigJson: reviewConfigString,
    );
    await CatalogLocalizationService.instance.loadAll();
  }

  void loadFromJsonStrings({
    required String catalogJson,
    required String quantitiesJson,
    String? reviewConfigJson,
  }) {
    final catalogMap = json.decode(catalogJson) as Map<String, dynamic>;
    final quantitiesMap = json.decode(quantitiesJson) as Map<String, dynamic>;

    _catalog = CatalogData.fromJson(catalogMap);
    _quantities = QuantitiesData.fromJson(quantitiesMap);

    if (reviewConfigJson != null) {
      final reviewConfigMap = json.decode(reviewConfigJson) as Map<String, dynamic>;
      _reviewConfig = ProvisioningReviewConfig.fromJson(reviewConfigMap);
      _reviewConfig!.validateAgainstCatalog(_catalog!);
    }
  }

  QuantityEngine createEngine() {
    if (_catalog == null || _quantities == null) {
      throw StateError('Catalog and Quantities must be loaded before creating QuantityEngine');
    }
    return QuantityEngine(catalog: _catalog!, quantities: _quantities!);
  }
}
