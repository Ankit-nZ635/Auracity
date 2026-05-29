import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors Redefined from Logo
  static const Color primaryBlue = Color(0xFF0D6EFD); // Royal Blue from 'Aura'
  static const Color accentCyan = Color(0xFF0DCEDC); // Cyan 
  static const Color logoGreen = Color(0xFF20C997); // Minty Green
  static const Color logoYellow = Color(0xFFFFC107); // Amber Yellow
  static const Color logoRed = Color(0xFFDC3545); // Crimson from 'City'
  
  static const Color backgroundLight = Color(0xFFF8F9FA); // Clean White/Grey
  static const Color surfaceColor = Colors.white;
  static const Color textDark = Color(0xFF1E293B); 
  static const Color textLight = Color(0xFF64748B); 

  // Priority Colors
  static const Color priorityRed = logoRed;
  static const Color priorityYellow = logoYellow;
  static const Color priorityGreen = logoGreen;

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundLight,
    primaryColor: primaryBlue,
    colorScheme: ColorScheme.light(
      primary: primaryBlue,
      secondary: accentCyan,
      surface: surfaceColor,
      error: priorityRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textDark,
      surfaceContainerHighest: Color(0xFFE2E8F0),
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: textDark, fontSize: 36, letterSpacing: -0.5),
      displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textDark, fontSize: 28),
      titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textDark, fontSize: 20),
      bodyLarge: const TextStyle(color: textDark, fontSize: 16),
      bodyMedium: const TextStyle(color: textLight, fontSize: 14),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: textDark),
      titleTextStyle: GoogleFonts.outfit(
        color: textDark,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      hintStyle: const TextStyle(color: textLight),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryBlue,
      unselectedItemColor: textLight,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 20,
    ),
  );

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 30,
      offset: const Offset(0, 10),
    )
  ];
}
