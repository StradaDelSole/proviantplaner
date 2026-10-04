import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/catalog_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';

/// Dienst zum Laden und Bereitstellen von übersetzten Katalogen (Slice S9).
class CatalogLocalizationService {
  static final CatalogLocalizationService instance = CatalogLocalizationService._internal();

  CatalogLocalizationService._internal();

  // Map: languageCode -> Map: variantId -> Map { 'name': String, 'note': String }
  final Map<String, Map<String, Map<String, String>>> _translations = {};
  bool _isLoaded = false;

  /// Lädt alle verfügbaren Katalogübersetzungen (EN, FR, ES, PT, HR).
  Future<void> loadAll() async {
    if (_isLoaded) return;

    const languages = ['en', 'fr', 'es', 'pt', 'hr'];
    for (final lang in languages) {
      try {
        String jsonStr;
        try {
          jsonStr = await rootBundle.loadString('data/i18n/catalog_$lang.json');
        } catch (_) {
          final file = File('data/i18n/catalog_$lang.json');
          if (file.existsSync()) {
            jsonStr = file.readAsStringSync();
          } else {
            continue;
          }
        }

        final parsed = json.decode(jsonStr) as Map<String, dynamic>;
        final translations = (parsed['translations'] ?? parsed['items']) as Map<String, dynamic>?;
        if (translations != null) {
          final langMap = <String, Map<String, String>>{};
          for (final entry in translations.entries) {
            if (entry.value is Map<String, dynamic>) {
              final val = entry.value as Map<String, dynamic>;
              langMap[entry.key] = {
                'name': val['name'] as String? ?? '',
                'note': val['note'] as String? ?? '',
              };
            } else if (entry.value is String) {
              langMap[entry.key] = {
                'name': entry.value as String,
                'note': '',
              };
            }
          }
          _translations[lang] = langMap;
        }
      } catch (e) {
        // Bei Ladefehlern still fortfahren, damit Standardwerte greifen
      }
    }

    _isLoaded = true;
  }

  /// Übersetzt den Namen einer Variante für den angegebenen Sprachcode.
  String translateName(String variantId, String languageCode, String defaultName) {
    if (languageCode == 'de') return defaultName;
    final langMap = _translations[languageCode];
    if (langMap != null && langMap.containsKey(variantId)) {
      final name = langMap[variantId]?['name'];
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    return defaultName;
  }

  /// Übersetzt die Notiz einer Variante für den angegebenen Sprachcode.
  String translateNote(String variantId, String languageCode, String defaultNote) {
    if (languageCode == 'de') return defaultNote;
    final langMap = _translations[languageCode];
    if (langMap != null && langMap.containsKey(variantId)) {
      final note = langMap[variantId]?['note'];
      if (note != null && note.isNotEmpty) {
        return note;
      }
    }
    return defaultNote;
  }
}

/// Lokalisierung für CatalogDepartment
extension LocalizedCatalogDepartment on CatalogDepartment {
  String localizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      CatalogDepartment.obstGemuese => l10n.deptObstGemuese,
      CatalogDepartment.backwaren => l10n.deptBackwaren,
      CatalogDepartment.molkerei => l10n.deptMolkerei,
      CatalogDepartment.fleischFisch => l10n.deptFleischFisch,
      CatalogDepartment.trockenware => l10n.deptTrockenware,
      CatalogDepartment.konserven => l10n.deptKonserven,
      CatalogDepartment.suesswaren => l10n.deptSuesswaren,
      CatalogDepartment.getraenke => l10n.deptGetraenke,
      CatalogDepartment.drogerie => l10n.deptDrogerie,
      CatalogDepartment.haushalt => l10n.deptHaushalt,
      CatalogDepartment.apotheke => l10n.deptApotheke,
      CatalogDepartment.technik => l10n.deptTechnik,
    };
  }
}

/// Lokalisierung für CatalogVariant
extension LocalizedCatalogVariant on CatalogVariant {
  String localizedName(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return CatalogLocalizationService.instance.translateName(id, lang, nameDe);
  }

  String localizedNote(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return CatalogLocalizationService.instance.translateNote(id, lang, note ?? '');
  }
}

/// Lokalisierung für CatalogGroup
extension LocalizedCatalogGroup on CatalogGroup {
  String localizedName(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return CatalogLocalizationService.instance.translateName(id, lang, nameDe);
  }
}

/// Lokalisierung für CatalogCategory
extension LocalizedCatalogCategory on CatalogCategory {
  String localizedName(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return CatalogLocalizationService.instance.translateName(id, lang, nameDe);
  }
}

/// Lokalisierung für ShoppingListItemView
extension LocalizedShoppingListItemView on ShoppingListItemView {
  String localizedName(BuildContext context) {
    if (isCustom) return name;
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == 'de') return name;
    if (variant != null) {
      return variant!.localizedName(context);
    }
    final variantId = item.catalogId;
    if (variantId.isNotEmpty) {
      return CatalogLocalizationService.instance.translateName(variantId, lang, name);
    }
    return name;
  }

  String suggestionDisplayLocalized(AppLocalizations l10n) {
    final size = effectivePackSize;
    final sizeFormatted = (size % 1 == 0) ? size.toInt().toString() : size.toStringAsFixed(1);
    final packUnit = variant?.pack.unit ?? unit;
    return l10n.suggestionPack(calculatedPackages, sizeFormatted, packUnit);
  }

  String demandDisplayLocalized(AppLocalizations l10n) {
    if (isCustom) return l10n.customItemBadge;
    final qty = calculatedQuantity;
    final qtyFormatted = (qty % 1 == 0) ? qty.toInt().toString() : qty.toStringAsFixed(1);
    return l10n.demandApprox(qtyFormatted, unit);
  }

  String shortSuggestionDisplayLocalized(AppLocalizations l10n) {
    return l10n.suggestionCount(calculatedPackages);
  }
}

/// Lokalisierung für ShoppingListDepartmentView
extension LocalizedShoppingListDepartmentView on ShoppingListDepartmentView {
  String localizedName(BuildContext context) {
    return department.localizedName(context);
  }
}
