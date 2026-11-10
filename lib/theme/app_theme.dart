import 'package:flutter/material.dart';

/// Centralized Material 3 theme configuration.
///
/// Font note: register Space Grotesk and Plus Jakarta Sans in pubspec.yaml
/// (or replace these font-family names with GoogleFonts configuration) for
/// the requested typefaces to render. Otherwise Flutter uses a fallback font.
class AppTheme {
  AppTheme._();

  // Light palette
  static const Color lightText = Color(0xFF0A0816);
  static const Color lightBackground = Color(0xFFF9F8FC);
  static const Color lightPrimary = Color(0xFF5845D3);
  static const Color lightSecondary = Color(0xFF988AEF);
  static const Color lightAccent = Color(0xFF6751F5);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // Dark palette
  static const Color darkText = Color(0xFFEBE9F7);
  static const Color darkBackground = Color(0xFF040307);
  static const Color darkPrimary = Color(0xFF3F2CBA);
  static const Color darkSecondary = Color(0xFF1D1075);
  static const Color darkAccent = Color(0xFF200AAE);
  static const Color darkSurface = Color(0xFF0D0B18);

  // Typography
  static const String fontTitle = 'Space Grotesk';
  static const String fontBody = 'Plus Jakarta Sans';

  static final RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );

  static TextTheme _textTheme(Color textColor, {required bool dark}) {
    final baseTheme = dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

    return baseTheme
        .apply(
          fontFamily: fontBody,
          bodyColor: textColor,
          displayColor: textColor,
        )
        .copyWith(
          displayLarge: TextStyle(
            fontFamily: fontTitle,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
          displayMedium: TextStyle(
            fontFamily: fontTitle,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
          headlineLarge: TextStyle(
            fontFamily: fontTitle,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
          headlineMedium: TextStyle(
            fontFamily: fontTitle,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          titleLarge: TextStyle(
            fontFamily: fontTitle,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          titleMedium: TextStyle(
            fontFamily: fontTitle,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          bodyLarge: TextStyle(
            fontFamily: fontBody,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textColor,
          ),
          bodyMedium: TextStyle(
            fontFamily: fontBody,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textColor,
          ),
          labelLarge: TextStyle(
            fontFamily: fontBody,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontBody,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: lightPrimary,
        onPrimary: Colors.white,
        secondary: lightSecondary,
        onSecondary: lightText,
        tertiary: lightAccent,
        onTertiary: Colors.white,
        error: Color(0xFFDC2626),
        onError: Colors.white,
        surface: lightSurface,
        onSurface: lightText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontTitle,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: lightText,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 1,
        shadowColor: lightPrimary.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: lightSecondary.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: lightPrimary.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white70,
          shape: buttonShape,
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightPrimary,
          side: const BorderSide(color: lightPrimary, width: 1.25),
          shape: buttonShape,
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: fontTitle,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: lightText,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: lightText.withValues(alpha: 0.10),
        thickness: 1,
        space: 1,
      ),
      textTheme: _textTheme(lightText, dark: false),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontBody,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: Colors.white,
        secondary: darkSecondary,
        onSecondary: darkText,
        tertiary: darkAccent,
        onTertiary: Colors.white,
        error: Color(0xFFEF4444),
        onError: Colors.white,
        surface: darkSurface,
        onSurface: darkText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontTitle,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkText,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: darkSecondary.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // A lighter purple is easier to distinguish against the near-black
          // background than darkPrimary or darkAccent.
          backgroundColor: lightAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: lightAccent.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white70,
          shape: buttonShape,
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkText,
          side: const BorderSide(color: lightAccent, width: 1.25),
          shape: buttonShape,
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: fontTitle,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: darkText,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: darkText.withValues(alpha: 0.12),
        thickness: 1,
        space: 1,
      ),
      textTheme: _textTheme(darkText, dark: true),
    );
  }
}
