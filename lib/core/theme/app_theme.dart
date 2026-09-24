import 'package:flutter/material.dart';

/// Zentrale Design- und Theme-Definitionen gemäß docs/design/DESIGN_BRIEF_v0.1.md.
/// Schlicht und sachlich, Material 3, abgeleitet aus der HullQ-CI mit maritim-technischer Note.
class AppTheme {
  AppTheme._();

  // Primärfarben (Blueprint Navy)
  static const Color primaryNavy = Color(0xFF1B365D);
  static const Color primaryNavyDark = Color(0xFF0F223D);
  static const Color primaryNavyLight = Color(0xFF90A4AE);

  // Akzentfarben (Petrol / Teal für erledigt / bestätigt)
  static const Color accentPetrol = Color(0xFF00897B);
  static const Color accentPetrolLight = Color(0xFF4DB6AC);

  // Hinweis & Warnung (Warmer Bernstein / Sand – bewusst kein Rot für Warnungen)
  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningAmberLight = Color(0xFFF59E0B);

  // Neutrale Töne
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color outlineLight = Color(0xFFCBD5E1);
  static const Color outlineDark = Color(0xFF334155);

  /// Tabellarische Ziffern für Beträge und Mengenangaben
  static const TextStyle tabularFiguresStyle = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Helles Design (Light Theme)
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryNavy,
      primary: primaryNavy,
      secondary: accentPetrol,
      tertiary: warningAmber,
      surface: surfaceLight,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        foregroundColor: primaryNavy,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: outlineLight),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        indicatorColor: primaryNavy.withOpacity(0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  /// Dunkles Design (Dark Theme, essenziell bei Nachtfahrten an Bord)
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryNavy,
      primary: const Color(0xFF93B5E1),
      secondary: accentPetrolLight,
      tertiary: warningAmberLight,
      surface: surfaceDark,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: outlineDark),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: const Color(0xFF93B5E1).withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
