import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.warmSand,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.deepTeal,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.mutedPlum,
        onSecondary: AppColors.textOnPrimary,
        error: AppColors.error,
        onError: AppColors.textOnPrimary,
        surface: AppColors.white,
        onSurface: AppColors.charcoal,
        surfaceContainerHighest: AppColors.cardBg,
      ),
      textTheme: base.copyWith(
        displayLarge: base.displayLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.charcoal,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: base.displayMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.charcoal,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        headlineLarge: base.headlineLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
          height: 1.3,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
          height: 1.35,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
          height: 1.35,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
          height: 1.4,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
          height: 1.4,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.charcoal,
          height: 1.5,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.charcoal,
          height: 1.5,
        ),
        bodySmall: base.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedPlum,
          height: 1.5,
        ),
        labelLarge: base.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
          letterSpacing: 0.1,
        ),
        labelMedium: base.labelMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedPlum,
        ),
        labelSmall: base.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textLight,
          letterSpacing: 0.1,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.warmSand,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepTeal,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(double.infinity, 54),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepTeal,
          side: const BorderSide(color: AppColors.deepTeal, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(double.infinity, 54),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.deepTeal,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.deepTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textLight,
        ),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedPlum,
        ),
        errorStyle: GoogleFonts.dmSans(
          fontSize: 12,
          color: AppColors.error,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.tealSurface,
        disabledColor: AppColors.warmSandDark,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.charcoal,
        ),
        secondaryLabelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.deepTeal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
        showCheckmark: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.deepTeal,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.charcoal,
        contentTextStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.textOnPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
        ),
      ),
    );
  }
}
