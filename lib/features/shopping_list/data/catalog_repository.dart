/// Repository zum Laden des Katalogs und der Mengenfaktoren (Slice S2).
library;

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:proviantplaner/core/services/catalog_localization_service.dart';
import '../domain/calculation/quantity_engine.dart';
import '../domain/models/catalog_models.dart';
import '../domain/models/quantities_models.dart';

class CatalogRepository {
  CatalogData? _catalog;
  QuantitiesData? _quantities;

  CatalogData? get catalog => _catalog;
  QuantitiesData? get quantities => _quantities;

  CatalogRepository({CatalogData? catalog, QuantitiesData? quantities})
      : _catalog = catalog,
        _quantities = quantities;

  Future<void> loadFromBundle() async {
    final catalogString = await rootBundle.loadString('data/catalog_v0.11.json');
    final quantitiesString = await rootBundle.loadString('data/quantities_v0.6.json');
    loadFromJsonStrings(
      catalogJson: catalogString,
      quantitiesJson: quantitiesString,
    );
    await CatalogLocalizationService.instance.loadAll();
  }

  void loadFromJsonStrings({
    required String catalogJson,
    required String quantitiesJson,
  }) {
    final catalogMap = json.decode(catalogJson) as Map<String, dynamic>;
    final quantitiesMap = json.decode(quantitiesJson) as Map<String, dynamic>;

    _catalog = CatalogData.fromJson(catalogMap);
    _quantities = QuantitiesData.fromJson(quantitiesMap);
  }

  QuantityEngine createEngine() {
    if (_catalog == null || _quantities == null) {
      throw StateError('Catalog and Quantities must be loaded before creating QuantityEngine');
    }
    return QuantityEngine(catalog: _catalog!, quantities: _quantities!);
  }
}
