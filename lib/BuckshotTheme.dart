import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BuckshotTheme {
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    textTheme: GoogleFonts.juraTextTheme(ThemeData.dark().textTheme),

    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF9D4EDD),
      onPrimary: Colors.white,
      secondary: Color(0xFFFF007F),
      onSecondary: Colors.white,
      error: Color(0xFFFF3366),
      onError: Colors.white,
      surface: Color(0xFF0B0914),
      onSurface: Colors.white,
      onSurfaceVariant: Color(0xFFE0AAFF),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9D4EDD),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.jura(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
  );

  static const Color successColor = Color(0xFF39FF14);
  static const Color navigationBarItemColorActive = Color(0xFF8A2BE2);
  static const Color navigationBarItemColorInactive = Color(0xFFffffff);
}