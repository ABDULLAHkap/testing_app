import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(
    0xFF2E7D6B,
  ); // teal-green, MDCAT/biology feel
  static const Color primaryDark = Color(0xFF1E5A4C);
  static const Color background = Color(0xFFF7F9F8);

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      brightness: Brightness.light,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerColor: scheme.outlineVariant,
    );
  }

  static ThemeData get standardTheme => _buildDarkTheme(
    background: const Color(0xFF061320),
    surface: const Color(0xFF101F32),
  );

  static ThemeData get darkTheme => _buildDarkTheme(
    background: Colors.black,
    surface: const Color(0xFF121212),
  );

  static ThemeData _buildDarkTheme({
    required Color background,
    required Color surface,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      brightness: Brightness.dark,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: surface,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerColor: scheme.outlineVariant,
    );
  }
}

extension AppThemeColors on BuildContext {
  Color get pageBackground => Theme.of(this).scaffoldBackgroundColor;
  Color get panelColor => Theme.of(this).colorScheme.surface;
  Color get primaryTextColor => Theme.of(this).colorScheme.onSurface;
  Color get secondaryTextColor => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get subtleBorderColor => Theme.of(this).colorScheme.outlineVariant;
  Color get inactiveColor =>
      Theme.of(this).colorScheme.onSurfaceVariant.withOpacity(.62);
}
