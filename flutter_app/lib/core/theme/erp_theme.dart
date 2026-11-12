import 'package:flutter/material.dart';

enum ErpSection {
  sales,
  purchases,
  godown,
  production,
  hr,
  admin,
}

class ErpSectionPalette {
  const ErpSectionPalette({
    required this.primary,
    required this.dark,
    required this.soft,
    required this.gradientEnd,
  });

  final Color primary;
  final Color dark;
  final Color soft;
  final Color gradientEnd;
}

class ErpTheme {
  const ErpTheme._();

  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);

  // Preserved module colors + React web theme colors
  static const Color salesBlue = Color(0xFF3B82F6);
  static const Color salesBlueDark = Color(0xFF1D4ED8);
  static const Color salesBlueSoft = Color(0xFFEFF6FF);

  static const Color purchasesOrange = Color(0xFFF97316);
  static const Color purchasesOrangeDark = Color(0xFFC2410C);
  static const Color purchasesOrangeSoft = Color(0xFFFFF7ED);

  static const Color godownTeal = Color(0xFF10B981);
  static const Color godownTealDark = Color(0xFF047857);
  static const Color godownTealSoft = Color(0xFFECFDF5);

  static const Color productionAmber = Color(0xFFD97706);
  static const Color productionAmberDark = Color(0xFFB45309);
  static const Color productionAmberSoft = Color(0xFFFEF3C7);

  static const Color hrIndigo = Color(0xFF4F46E5);
  static const Color hrPurple = Color(0xFF8B5CF6);
  static const Color hrPurpleDark = Color(0xFF6D28D9);
  static const Color hrIndigoSoft = Color(0xFFEEF2FF);

  static const Color adminSlate = Color(0xFF475569);
  static const Color adminSlateDark = Color(0xFF334155);
  static const Color adminSlateSoft = Color(0xFFF8FAFC);

  static const Color ordersEmerald = Color(0xFF059669);
  static const Color ordersEmeraldSoft = Color(0xFFD1FAE5);
  static const Color dangerRose = Color(0xFFE11D48);
  static const Color dangerRoseSoft = Color(0xFFFFE4E6);

  static ErpSectionPalette paletteFor(ErpSection section) {
    switch (section) {
      case ErpSection.sales:
        return const ErpSectionPalette(
          primary: salesBlue,
          dark: salesBlueDark,
          soft: salesBlueSoft,
          gradientEnd: hrIndigo,
        );
      case ErpSection.purchases:
        return const ErpSectionPalette(
          primary: purchasesOrange,
          dark: purchasesOrangeDark,
          soft: purchasesOrangeSoft,
          gradientEnd: Color(0xFFEF4444),
        );
      case ErpSection.godown:
        return const ErpSectionPalette(
          primary: godownTeal,
          dark: godownTealDark,
          soft: godownTealSoft,
          gradientEnd: Color(0xFF0D9488),
        );
      case ErpSection.production:
        return const ErpSectionPalette(
          primary: Color(0xFFF59E0B),
          dark: productionAmberDark,
          soft: Color(0xFFFFFBEB),
          gradientEnd: productionAmber,
        );
      case ErpSection.hr:
        return const ErpSectionPalette(
          primary: hrPurple,
          dark: hrPurpleDark,
          soft: Color(0xFFF5F3FF),
          gradientEnd: hrIndigo,
        );
      case ErpSection.admin:
        return const ErpSectionPalette(
          primary: adminSlate,
          dark: adminSlateDark,
          soft: adminSlateSoft,
          gradientEnd: slate800,
        );
    }
  }

  static ThemeData buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: salesBlue,
      brightness: Brightness.light,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: slate50,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: slate900,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: slate900,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: slate200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: salesBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dangerRose),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: slate200),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
