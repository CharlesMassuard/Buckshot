import 'package:flutter/material.dart';

class BuckshotTheme {
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF9D4EDD),
      onPrimary: Colors.white,
      secondary: Color(0xFFFF007F),
      onSecondary: Colors.white,
      error: Color(0xFFFF3366),
      onError: Colors.white,
      surface: Color(0xFF161224),
      onSurface: Colors.white,
      surfaceVariant: Color(0xFF241E36),
      onSurfaceVariant: Color(0xFFE0AAFF),
      background: Color(0xFF0B0914),
      onBackground: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9D4EDD),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );

  static const Color successColor = Color(0xFF39FF14);
}