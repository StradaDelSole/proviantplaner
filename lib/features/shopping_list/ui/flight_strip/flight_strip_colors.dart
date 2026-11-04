/// Farb- und Ikonografie-Definitionen für das Flight-Strip-Board (Issue #56).
/// Stabile, funktionale Farbfamilien je Produktkategorie, voll kompatibel
/// mit Hell-, Dunkel- und Nachtwache-Modus (Rot auf Schwarz, Designregel 13).
library;

import 'package:flutter/material.dart';

class FlightStripColors {
  const FlightStripColors._();

  /// Gibt die charakteristische Akzentfarbe der Produktkategorie zurück.
  /// Im Nachtwache-Modus wird strikt Rot (#FFFF3B30) zurückgegeben,
  /// um die Dunkeladaption der Crew auf See nicht zu gefährden.
  static Color getCategoryColor(
    String categoryId, {
    required Brightness brightness,
    bool isNightwatch = false,
  }) {
    if (isNightwatch) {
      return const Color(0xFFFF3B30);
    }

    final isDark = brightness == Brightness.dark;

    switch (categoryId) {
      case 'fruehstueck':
        // Warmes Bernstein / Orange
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFE67E22);
      case 'grundnahrung':
        // Warmes Weizengold / Sand
        return isDark ? const Color(0xFFFFD54F) : const Color(0xFFD4AC0D);
      case 'saucen_wuerzen':
        // Terrakotta / Paprikarot
        return isDark ? const Color(0xFFFF8A65) : const Color(0xFFD35400);
      case 'frisches':
        // Frisches Blattgrün
        return isDark ? const Color(0xFF81C784) : const Color(0xFF27AE60);
      case 'suesses_snacks':
        // Beeren-Violett
        return isDark ? const Color(0xFFBA68C8) : const Color(0xFF8E44AD);
      case 'getraenke':
        // Ozean-Cyan / Aquablau
        return isDark ? const Color(0xFF4FC3F7) : const Color(0xFF2980B9);
      case 'alkohol':
        // Weinrot / Rubinrot
        return isDark ? const Color(0xFFE57373) : const Color(0xFFC0392B);
      case 'haushalt':
        // Schieferblau / Grau
        return isDark ? const Color(0xFF90A4AE) : const Color(0xFF607D8B);
      case 'hygiene':
        // Minztürkis
        return isDark ? const Color(0xFF4DB6AC) : const Color(0xFF16A085);
      case 'technik':
        // Maritimes Indigo / Stahlblau
        return isDark ? const Color(0xFF7986CB) : const Color(0xFF3F51B5);
      default:
        return isDark ? const Color(0xFFB0BEC5) : const Color(0xFF78909C);
    }
  }

  /// Liefert ein passendes Symbol für die Produktkategorie zur Barrierefreiheit
  /// und Unterscheidung bei Farbsehschwächen.
  static IconData getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'fruehstueck':
        return Icons.breakfast_dining_outlined;
      case 'grundnahrung':
        return Icons.grain_outlined;
      case 'saucen_wuerzen':
        return Icons.soup_kitchen_outlined;
      case 'frisches':
        return Icons.eco_outlined;
      case 'suesses_snacks':
        return Icons.cookie_outlined;
      case 'getraenke':
        return Icons.local_drink_outlined;
      case 'alkohol':
        return Icons.wine_bar_outlined;
      case 'haushalt':
        return Icons.cleaning_services_outlined;
      case 'hygiene':
        return Icons.spa_outlined;
      case 'technik':
        return Icons.build_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

