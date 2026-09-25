/// Zentrales Design-System gemäß docs/design/DESIGN_BRIEF_v0.4.md und technical_maritime_m3/DESIGN.md.
/// Drei Farbmodi: Hell, Dunkel und Nachtwache (Rot auf Schwarz gemäß Designregel 13).
/// Lokale Schriftarten: IBM Plex Sans und JetBrains Mono.
library;

import 'package:flutter/material.dart';

/// Benutzerdefinierte Typografie für Zahlen und technische Etiketten mit Tabellenziffern.
class ProviantTypography extends ThemeExtension<ProviantTypography> {
  final TextStyle numberLarge;
  final TextStyle numberMedium;
  final TextStyle numberSmall;

  const ProviantTypography({
    required this.numberLarge,
    required this.numberMedium,
    required this.numberSmall,
  });

  @override
  ProviantTypography copyWith({
    TextStyle? numberLarge,
    TextStyle? numberMedium,
    TextStyle? numberSmall,
  }) {
    return ProviantTypography(
      numberLarge: numberLarge ?? this.numberLarge,
      numberMedium: numberMedium ?? this.numberMedium,
      numberSmall: numberSmall ?? this.numberSmall,
    );
  }

  @override
  ProviantTypography lerp(ThemeExtension<ProviantTypography>? other, double t) {
    if (other is! ProviantTypography) return this;
    return ProviantTypography(
      numberLarge: TextStyle.lerp(numberLarge, other.numberLarge, t)!,
      numberMedium: TextStyle.lerp(numberMedium, other.numberMedium, t)!,
      numberSmall: TextStyle.lerp(numberSmall, other.numberSmall, t)!,
    );
  }
}

/// Spezifische Farben für maritime Kennzeichnungen, Badges und Hinweise.
class MaritimeColors extends ThemeExtension<MaritimeColors> {
  final Color badgeAmberBackground;
  final Color badgeAmberText;
  final Color successTeal;
  final Color cardBackground;
  final Color cardBorder;

  const MaritimeColors({
    required this.badgeAmberBackground,
    required this.badgeAmberText,
    required this.successTeal,
    required this.cardBackground,
    required this.cardBorder,
  });

  @override
  MaritimeColors copyWith({
    Color? badgeAmberBackground,
    Color? badgeAmberText,
    Color? successTeal,
    Color? cardBackground,
    Color? cardBorder,
  }) {
    return MaritimeColors(
      badgeAmberBackground: badgeAmberBackground ?? this.badgeAmberBackground,
      badgeAmberText: badgeAmberText ?? this.badgeAmberText,
      successTeal: successTeal ?? this.successTeal,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
    );
  }

  @override
  MaritimeColors lerp(ThemeExtension<MaritimeColors>? other, double t) {
    if (other is! MaritimeColors) return this;
    return MaritimeColors(
      badgeAmberBackground: Color.lerp(badgeAmberBackground, other.badgeAmberBackground, t)!,
      badgeAmberText: Color.lerp(badgeAmberText, other.badgeAmberText, t)!,
      successTeal: Color.lerp(successTeal, other.successTeal, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
    );
  }
}

extension ProviantThemeExtension on ThemeData {
  ProviantTypography get proviantTypography =>
      extension<ProviantTypography>() ?? AppTheme.defaultLightTypography;
  MaritimeColors get maritimeColors =>
      extension<MaritimeColors>() ?? AppTheme.defaultLightMaritimeColors;
}

extension BuildContextThemeExtension on BuildContext {
  ProviantTypography get numbers => Theme.of(this).proviantTypography;
  MaritimeColors get maritime => Theme.of(this).maritimeColors;
}

/// Zentrales Theme der Proviantplaner-App.
class AppTheme {
  AppTheme._();

  static const String fontSans = 'IBM Plex Sans';
  static const String fontMono = 'JetBrains Mono';

  // --- Farbtokens Hell (Design-Brief v0.4 & technical_maritime_m3) ---
  static const Color lightPrimary = Color(0xFF03111F);
  static const Color lightPrimaryContainer = Color(0xFF182635);
  static const Color lightOnPrimaryContainer = Color(0xFF7F8DA0);
  static const Color lightSecondary = Color(0xFF006A61);
  static const Color lightSecondaryContainer = Color(0xFF9DF2E5);
  static const Color lightTertiaryFixed = Color(0xFFFFDCC2);
  static const Color lightOnTertiaryContainer = Color(0xFFCC7720);
  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightSurface = Color(0xFFF8F9FF);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFEFF4FF);
  static const Color lightOnSurface = Color(0xFF0B1C30);
  static const Color lightOnSurfaceVariant = Color(0xFF44474C);
  static const Color lightOutline = Color(0xFF74777D);
  static const Color lightOutlineVariant = Color(0xFFC4C6CC);

  // --- Farbtokens Dunkel (Design-Brief v0.4) ---
  static const Color darkSurface = Color(0xFF0B1622);
  static const Color darkSurfaceContainer = Color(0xFF122130);
  static const Color darkSurfaceContainerHigh = Color(0xFF182A3B);
  static const Color darkOnSurface = Color(0xFFE3ECF7);
  static const Color darkOnSurfaceVariant = Color(0xFF9FB0C3);
  static const Color darkPrimary = Color(0xFF2BBFAE); // Petrol hell
  static const Color darkOnPrimary = Color(0xFF00201D);
  static const Color darkSecondary = Color(0xFF4FD6C4);
  static const Color darkAmberBg = Color(0xFF3C1D00);
  static const Color darkAmberText = Color(0xFFFFB77A);
  static const Color darkOutlineVariant = Color(0xFF2A3B4D);

  // --- Farbtokens Nachtwache (Designregel 13: strikt Rot auf Schwarz) ---
  static const Color nightwatchSurface = Color(0xFF000000);
  static const Color nightwatchSurfaceContainer = Color(0xFF120000);
  static const Color nightwatchSurfaceContainerHigh = Color(0xFF1E0303);
  static const Color nightwatchOnSurface = Color(0xFFE0433A);
  static const Color nightwatchOnSurfaceVariant = Color(0xFFA8322B);
  static const Color nightwatchPrimary = Color(0xFF7A1510);
  static const Color nightwatchOnPrimary = Color(0xFFFF6B61);
  static const Color nightwatchHighlight = Color(0xFFFF5449);
  static const Color nightwatchOutlineVariant = Color(0xFF3A0B08);

  static const Color primaryNavy = lightPrimary;

  static const ProviantTypography defaultLightTypography = ProviantTypography(
    numberLarge: TextStyle(
      fontFamily: fontMono,
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight.w600,
      color: lightOnSurface,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    numberMedium: TextStyle(
      fontFamily: fontMono,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: lightOnSurfaceVariant,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    numberSmall: TextStyle(
      fontFamily: fontMono,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
      color: lightOnSurfaceVariant,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
  );

  static const MaritimeColors defaultLightMaritimeColors = MaritimeColors(
    badgeAmberBackground: lightTertiaryFixed,
    badgeAmberText: lightOnTertiaryContainer,
    successTeal: lightSecondary,
    cardBackground: lightSurfaceContainerLowest,
    cardBorder: lightOutlineVariant,
  );

  static const ProviantTypography defaultDarkTypography = ProviantTypography(
    numberLarge: TextStyle(
      fontFamily: fontMono,
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight.w600,
      color: darkOnSurface,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    numberMedium: TextStyle(
      fontFamily: fontMono,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: darkOnSurfaceVariant,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    numberSmall: TextStyle(
      fontFamily: fontMono,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
      color: darkOnSurfaceVariant,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
  );

  static const MaritimeColors defaultDarkMaritimeColors = MaritimeColors(
    badgeAmberBackground: darkAmberBg,
    badgeAmberText: darkAmberText,
    successTeal: darkSecondary,
    cardBackground: darkSurfaceContainer,
    cardBorder: darkOutlineVariant,
  );

  static const ProviantTypography defaultNightwatchTypography = ProviantTypography(
    numberLarge: TextStyle(
      fontFamily: fontMono,
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight.w600,
      color: nightwatchOnSurface,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    numberMedium: TextStyle(
      fontFamily: fontMono,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: nightwatchOnSurfaceVariant,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    numberSmall: TextStyle(
      fontFamily: fontMono,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
      color: nightwatchOnSurfaceVariant,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
  );

  static const MaritimeColors defaultNightwatchMaritimeColors = MaritimeColors(
    badgeAmberBackground: nightwatchSurfaceContainerHigh,
    badgeAmberText: nightwatchHighlight,
    successTeal: nightwatchHighlight,
    cardBackground: nightwatchSurfaceContainer,
    cardBorder: nightwatchOutlineVariant,
  );

  /// Helles Design (Light Theme)
  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(lightOnSurface, lightOnSurfaceVariant);

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontSans,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightSurface,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: lightPrimary,
        onPrimary: Colors.white,
        primaryContainer: lightPrimaryContainer,
        onPrimaryContainer: lightOnPrimaryContainer,
        secondary: lightSecondary,
        onSecondary: Colors.white,
        secondaryContainer: lightSecondaryContainer,
        onSecondaryContainer: Color(0xFF077167),
        tertiary: lightOnTertiaryContainer,
        onTertiary: Colors.white,
        error: lightError,
        onError: Colors.white,
        surface: lightSurface,
        onSurface: lightOnSurface,
        onSurfaceVariant: lightOnSurfaceVariant,
        outline: lightOutline,
        outlineVariant: lightOutlineVariant,
      ),
      textTheme: textTheme,
      extensions: const [
        defaultLightTypography,
        defaultLightMaritimeColors,
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightOnSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontSans,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: lightOnSurface,
        ),
      ),
      cardTheme: CardTheme(
        color: lightSurfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: lightOutlineVariant, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: fontSans,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: lightOutlineVariant, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: fontSans,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontFamily: fontSans,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightOutlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightOutlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: lightSurface,
        indicatorColor: lightSurfaceContainerLow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: fontSans,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: lightPrimary,
            );
          }
          return const TextStyle(
            fontFamily: fontSans,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: lightOnSurfaceVariant,
          );
        }),
      ),
    );
  }

  /// Dunkles Design (Dark Theme)
  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(darkOnSurface, darkOnSurfaceVariant);

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontSans,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkSurface,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: darkOnPrimary,
        secondary: darkSecondary,
        onSecondary: Color(0xFF00201D),
        surface: darkSurface,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkOnSurfaceVariant,
        outline: Color(0xFF64748B),
        outlineVariant: darkOutlineVariant,
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
      ),
      textTheme: textTheme,
      extensions: const [
        defaultDarkTypography,
        defaultDarkMaritimeColors,
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkOnSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontSans,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
      ),
      cardTheme: CardTheme(
        color: darkSurfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: darkOutlineVariant, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          backgroundColor: darkPrimary,
          foregroundColor: darkOnPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: fontSans,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: darkOutlineVariant, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: fontSans,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontFamily: fontSans,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkOutlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkOutlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: darkSurface,
        indicatorColor: darkSurfaceContainerHigh,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: fontSans,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: darkPrimary,
            );
          }
          return const TextStyle(
            fontFamily: fontSans,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkOnSurfaceVariant,
          );
        }),
      ),
    );
  }

  /// Nachtwache-Design (Rot auf Schwarz gemäß Designregel 13).
  /// Erhält die Dunkeladaption der Augen bei Nachtfahrten an Deck.
  /// Keine Farben außerhalb des Rot/Schwarz-Spektrums!
  static ThemeData get nightwatchTheme {
    final textTheme = _buildTextTheme(nightwatchOnSurface, nightwatchOnSurfaceVariant);

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontSans,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: nightwatchSurface,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: nightwatchPrimary,
        onPrimary: nightwatchOnPrimary,
        primaryContainer: nightwatchSurfaceContainerHigh,
        onPrimaryContainer: nightwatchOnPrimary,
        secondary: nightwatchPrimary,
        onSecondary: nightwatchOnPrimary,
        secondaryContainer: nightwatchSurfaceContainerHigh,
        onSecondaryContainer: nightwatchOnPrimary,
        tertiary: nightwatchHighlight,
        onTertiary: nightwatchSurface,
        tertiaryContainer: nightwatchSurfaceContainerHigh,
        onTertiaryContainer: nightwatchHighlight,
        error: nightwatchHighlight,
        onError: nightwatchSurface,
        surface: nightwatchSurface,
        surfaceContainerLowest: nightwatchSurface,
        surfaceContainerLow: nightwatchSurfaceContainer,
        surfaceContainer: nightwatchSurfaceContainer,
        surfaceContainerHigh: nightwatchSurfaceContainerHigh,
        surfaceContainerHighest: nightwatchSurfaceContainerHigh,
        onSurface: nightwatchOnSurface,
        onSurfaceVariant: nightwatchOnSurfaceVariant,
        outline: nightwatchOnSurfaceVariant,
        outlineVariant: nightwatchOutlineVariant,
        shadow: Colors.transparent,
        scrim: nightwatchSurface,
      ),
      textTheme: textTheme,
      extensions: const [
        defaultNightwatchTypography,
        defaultNightwatchMaritimeColors,
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: nightwatchSurface,
        foregroundColor: nightwatchOnSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontSans,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: nightwatchOnSurface,
        ),
      ),
      cardTheme: CardTheme(
        color: nightwatchSurfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: nightwatchOutlineVariant, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: const DialogTheme(
        backgroundColor: nightwatchSurfaceContainer,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: nightwatchSurfaceContainer,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: nightwatchSurfaceContainer,
        selectedColor: nightwatchPrimary,
        disabledColor: nightwatchSurfaceContainer,
        labelStyle: const TextStyle(
          fontFamily: fontSans,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: nightwatchOnSurface,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: fontSans,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: nightwatchOnPrimary,
        ),
        side: const BorderSide(color: nightwatchOutlineVariant, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return nightwatchHighlight;
          }
          return nightwatchOnSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return nightwatchPrimary;
          }
          return nightwatchSurfaceContainerHigh;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: nightwatchHighlight,
        inactiveTrackColor: nightwatchSurfaceContainerHigh,
        thumbColor: nightwatchHighlight,
        overlayColor: nightwatchHighlight.withOpacity(0.12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: nightwatchHighlight,
        linearTrackColor: nightwatchSurfaceContainerHigh,
        circularTrackColor: nightwatchSurfaceContainerHigh,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: nightwatchSurfaceContainer,
          selectedBackgroundColor: nightwatchPrimary,
          foregroundColor: nightwatchOnSurface,
          selectedForegroundColor: nightwatchOnPrimary,
          side: const BorderSide(color: nightwatchOutlineVariant, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: nightwatchOutlineVariant,
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          backgroundColor: nightwatchPrimary,
          foregroundColor: nightwatchOnPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: fontSans,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: nightwatchOutlineVariant, width: 1),
          foregroundColor: nightwatchOnSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: fontSans,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: nightwatchOnSurface,
          textStyle: const TextStyle(
            fontFamily: fontSans,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: nightwatchSurfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: nightwatchOutlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: nightwatchOutlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: nightwatchHighlight, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: nightwatchSurface,
        indicatorColor: nightwatchSurfaceContainerHigh,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: fontSans,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: nightwatchHighlight,
            );
          }
          return const TextStyle(
            fontFamily: fontSans,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: nightwatchOnSurfaceVariant,
          );
        }),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      displaySmall: TextStyle(
        fontFamily: fontSans,
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontSans,
        fontSize: 26,
        height: 32 / 26,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontSans,
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleMedium: TextStyle(
        fontFamily: fontSans,
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleSmall: TextStyle(
        fontFamily: fontSans,
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontSans,
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: primaryColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontSans,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
      ),
      labelLarge: TextStyle(
        fontFamily: fontSans,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      labelMedium: TextStyle(
        fontFamily: fontSans,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
      ),
    );
  }
}
