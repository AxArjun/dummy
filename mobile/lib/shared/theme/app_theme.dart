// FuelIQ — Material 3 App Theme
// Premium dark automotive design system

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ─── Brand Colors ───────────────────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF2563EB);       // Electric blue
  static const Color _primaryBlueDark = Color(0xFF1D4ED8);
  static const Color _accentAmber = Color(0xFFF59E0B);       // Fuel amber
  static const Color _accentGreen = Color(0xFF10B981);       // Efficiency green
  static const Color _accentRed = Color(0xFFEF4444);         // Alert red

  // ─── Dark Surface Palette ───────────────────────────────────────────────────
  static const Color _darkBg = Color(0xFF0A0F1E);            // Deep navy
  static const Color _darkSurface = Color(0xFF111827);       // Card surface
  static const Color _darkSurfaceVariant = Color(0xFF1F2937); // Elevated cards
  static const Color _darkBorder = Color(0xFF374151);        // Subtle borders

  static const Color primaryBlue = _primaryBlue;
  static const Color primaryBlueDark = _primaryBlueDark;
  static const Color background = _darkBg;
  static const Color surface = _darkSurface;

  // ─── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryBlue,
          brightness: Brightness.dark,
          primary: _primaryBlue,
          onPrimary: Colors.white,
          secondary: _accentAmber,
          onSecondary: Colors.black,
          tertiary: _accentGreen,
          error: _accentRed,
          surface: _darkSurface,
          onSurface: const Color(0xFFF9FAFB),
          surfaceContainerHighest: _darkSurfaceVariant,
          outline: _darkBorder,
          outlineVariant: const Color(0xFF1F2937),
          background: _darkBg,
          onBackground: const Color(0xFFF9FAFB),
        ),
        scaffoldBackgroundColor: _darkBg,
        fontFamily: 'Inter',

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkBg,
          foregroundColor: Color(0xFFF9FAFB),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF9FAFB),
          ),
        ),

        // Cards
        cardTheme: const CardThemeData(
          color: _darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: _darkBorder, width: 1),
          ),
        ),

        // Elevated Button
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Outlined Button
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryBlue,
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: _primaryBlue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Text Button
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _primaryBlue,
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Input decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _darkSurfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accentRed),
          ),
          labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          hintStyle: const TextStyle(color: Color(0xFF6B7280)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),

        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: _darkSurfaceVariant,
          labelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),

        // Bottom Navigation Bar
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _darkSurface,
          indicatorColor: _primaryBlue.withOpacity(0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _primaryBlue,
              );
            }
            return const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF6B7280),
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: _primaryBlue, size: 24);
            }
            return const IconThemeData(color: Color(0xFF6B7280), size: 24);
          }),
        ),

        // List Tile
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF9CA3AF),
          textColor: Color(0xFFF9FAFB),
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFFF9FAFB),
          ),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: _darkBorder,
          thickness: 1,
          space: 1,
        ),

        // Text Theme
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 57),
          displayMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 45),
          displaySmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 36),
          headlineLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 32),
          headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 28),
          headlineSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 24),
          titleLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 22),
          titleMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
          titleSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14),
          bodyLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 16),
          bodyMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 14),
          bodySmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 12),
          labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
          labelMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12),
          labelSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 11),
        ).apply(
          bodyColor: const Color(0xFFF9FAFB),
          displayColor: const Color(0xFFF9FAFB),
        ),
      );

  // ─── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryBlue,
          primary: _primaryBlue,
          secondary: _accentAmber,
          tertiary: _accentGreen,
          error: _accentRed,
        ),
        fontFamily: 'Inter',
      );

  // ─── Design Tokens ─────────────────────────────────────────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;

  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Gradient overlays for hero cards
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F2937), Color(0xFF111827)],
  );
}
