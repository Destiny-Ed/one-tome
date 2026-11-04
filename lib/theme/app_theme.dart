import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF5B4B8A),
        scaffoldBackgroundColor: const Color(0xFFF7F5F2),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF8B7BC8),
        scaffoldBackgroundColor: const Color(0xFF121212),
      );
}
