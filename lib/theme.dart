import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// HopAlong design system — cute, minimalist, Pinterest-inspired.
/// Warm off-white, sage green, pastel peach. No heavy gradients.
class HopColors {
  static const Color bg = Color(0xFFFFF9F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF6EFE6);
  static const Color sage = Color(0xFF7A9B7A);
  static const Color sageLight = Color(0xFF8FAE8B);
  static const Color sageSoft = Color(0xFFE4EDE1);
  static const Color peach = Color(0xFFF6C9A8);
  static const Color peachSoft = Color(0xFFFDEEDF);
  static const Color peachDeep = Color(0xFFE89B6A);
  static const Color ink = Color(0xFF2E2A26);
  static const Color inkSoft = Color(0xFF6B6259);
  static const Color line = Color(0xFFEADFD2);
  static const Color amber = Color(0xFFD9A441);
  static const Color danger = Color(0xFFC96A5A);
}

ThemeData hopTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: HopColors.sage,
      secondary: HopColors.peachDeep,
      surface: HopColors.surface,
      error: HopColors.danger,
    ),
    scaffoldBackgroundColor: HopColors.bg,
  );
  return base.copyWith(
    textTheme: GoogleFonts.quicksandTextTheme(base.textTheme).copyWith(
      bodyMedium: GoogleFonts.nunito(
          textStyle: base.textTheme.bodyMedium, color: HopColors.ink),
      bodyLarge: GoogleFonts.nunito(
          textStyle: base.textTheme.bodyLarge, color: HopColors.ink),
      bodySmall: GoogleFonts.nunito(
          textStyle: base.textTheme.bodySmall, color: HopColors.inkSoft),
      titleLarge: GoogleFonts.quicksand(
          textStyle: base.textTheme.titleLarge,
          color: HopColors.ink,
          fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.quicksand(
          textStyle: base.textTheme.titleMedium,
          color: HopColors.ink,
          fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.quicksand(
          textStyle: base.textTheme.headlineSmall,
          color: HopColors.ink,
          fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.quicksand(
          textStyle: base.textTheme.headlineMedium,
          color: HopColors.ink,
          fontWeight: FontWeight.w700),
      labelLarge: GoogleFonts.quicksand(
          textStyle: base.textTheme.labelLarge,
          color: HopColors.ink,
          fontWeight: FontWeight.w700),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: HopColors.bg,
      foregroundColor: HopColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: HopColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: HopColors.line),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HopColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: HopColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: HopColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: HopColors.sage, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: HopColors.danger),
      ),
      labelStyle: const TextStyle(color: HopColors.inkSoft),
      hintStyle: const TextStyle(color: HopColors.inkSoft),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: HopColors.sage,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HopColors.sage,
        side: const BorderSide(color: HopColors.sage, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: HopColors.sage,
        textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: HopColors.sageSoft,
      labelStyle: GoogleFonts.quicksand(
          fontWeight: FontWeight.w700, color: HopColors.ink),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide.none,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: HopColors.surface,
      selectedItemColor: HopColors.sage,
      unselectedItemColor: HopColors.inkSoft,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: HopColors.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: HopColors.surface,
      headerBackgroundColor: HopColors.sage,
      headerForegroundColor: Colors.white,
    ),
    timePickerTheme: const TimePickerThemeData(
      backgroundColor: HopColors.surface,
      dialHandColor: HopColors.sage,
    ),
  );
}
