import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF2B6CB0);
  static const accent = Color(0xFF4A90D9);
  static const navy = Color(0xFF1A2332);
  static const softBg = Color(0xFFF0F6FB);
  static const textMuted = Color(0xFF5A6A7A);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: accent,
        scaffoldBackgroundColor: softBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: navy,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: navy,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: navy, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleLarge: TextStyle(color: navy, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textMuted, height: 1.5),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: accent,
        scaffoldBackgroundColor: const Color(0xFF0F1419),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      );
}
