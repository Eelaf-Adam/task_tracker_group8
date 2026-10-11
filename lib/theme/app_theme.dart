import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Text
  static const ink = Color(0xFF1A1F5E); // dark navy
  static const inkSoft = Color(0xFF6B7194); // secondary text
  static const inkMuted = Color(0xFF9AA0B8); // captions, hints

  // Surfaces
  static const base = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFEBEDF5);

  // Brand purple
  static const primary = Color(0xFF7B6EF6);
  static const primaryDark = Color(0xFF5E51E0);
  static const primaryTint = Color(0xFFF0EEFE);

  // Status / accent colors
  static const amber = Color(0xFFF5B544);
  static const amberTint = Color(0xFFFFF4DD);

  static const coral = Color(0xFFF0746E);
  static const coralTint = Color(0xFFFEECEB);

  static const green = Color(0xFF3DBE8B);
  static const greenTint = Color(0xFFE5F7EF);

  static const slate = Color(0xFF6B7BA0);
  static const slateTint = Color(0xFFEDF0F7);
}

/// Role to accent color mapping, used on team member rows and profile.
class RoleColor {
  final Color color;
  final Color tint;
  const RoleColor(this.color, this.tint);

  static const projectManager = RoleColor(AppColors.primary, AppColors.primaryTint);
  static const designer = RoleColor(AppColors.amber, AppColors.amberTint);
  static const developer = RoleColor(AppColors.slate, AppColors.slateTint);
  static const qa = RoleColor(AppColors.coral, AppColors.coralTint);
  static const docs = RoleColor(AppColors.green, AppColors.greenTint);
}

class AppText {
  static TextStyle get head => GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      );

  static TextStyle get headSemi => GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get body => GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      );

  static TextStyle get bodySoft => GoogleFonts.poppins(
        fontWeight: FontWeight.w400,
        color: AppColors.inkSoft,
      );

  static TextStyle get caption => GoogleFonts.poppins(
        fontWeight: FontWeight.w400,
        fontSize: 11,
        color: AppColors.inkMuted,
      );
}

/// Reusable decorations so every screen shares the same card look.
class AppDecor {
  /// White rounded card with a thin light border.
  static BoxDecoration card({
    Color color = AppColors.surface,
    double radius = 16,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.line),
      );

  /// Soft purple glow for prominent action buttons.
  static List<BoxShadow> get glow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.30),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

class AppTheme {
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF8F89FF);
  static const Color darkText = Color(0xFF1E293B);
  static const Color greyText = Color(0xFF94A3B8);
  static const Color backgroundLight = Color(0xFFF8FAFC);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: primaryColor,
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      surface: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        shadowColor: primaryColor.withValues(alpha: 0.4),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: const TextStyle(color: greyText, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    ),
  );
}