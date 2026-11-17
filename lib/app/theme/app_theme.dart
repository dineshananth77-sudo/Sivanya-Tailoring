import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import '../../core/navigation/luxury_page_transitions_builder.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
      ),
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.cormorantGaramond(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.cormorantGaramond(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.cormorantGaramond(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.dmSans(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        titleLarge: GoogleFonts.dmSans(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.dmSans(
          color: AppColors.text,
          fontSize: 14,
        ),
        bodyMedium: GoogleFonts.dmSans(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.borderLight, width: 0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: LuxuryPageTransitionsBuilder(),
          TargetPlatform.iOS: LuxuryPageTransitionsBuilder(),
          TargetPlatform.windows: LuxuryPageTransitionsBuilder(),
          TargetPlatform.linux: LuxuryPageTransitionsBuilder(),
          TargetPlatform.macOS: LuxuryPageTransitionsBuilder(),
        },
      ),
    );
  }
}
