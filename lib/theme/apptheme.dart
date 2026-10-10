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

  // Status / accent colors (soft, so the page stays calm)
  static const amber = Color(0xFFF5B544);
  static const amberTint = Color(0xFFFFF4DD);

  static const coral = Color(0xFFF0746E);
  static const coralTint = Color(0xFFFEECEB);

  static const green = Color(0xFF3DBE8B);
  static const greenTint = Color(0xFFE5F7EF);

  static const slate = Color(0xFF6B7BA0);
  static const slateTint = Color(0xFFEDF0F7);
}

/// Role -> accent color mapping, used on team member rows and profile.
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
  /// White rounded card with a thin light border (no heavy shadow).
  static BoxDecoration card({
    Color color = AppColors.surface,
    double radius = 16,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.line),
      );

  /// Soft purple glow for the main buttons and the center "+" button.
  static List<BoxShadow> get glow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.30),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

ThemeData buildAppTheme() {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color),
      );

  return ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.base,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.amber,
      surface: AppColors.surface,
    ),
textTheme: ThemeData.light().textTheme.apply(
  bodyColor: AppColors.ink,
  displayColor: AppColors.ink,
),
fontFamily: 'Poppins',
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.ink,
      titleTextStyle: AppText.headSemi.copyWith(fontSize: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: AppText.headSemi.copyWith(fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: AppText.bodySoft.copyWith(color: AppColors.inkMuted),
      labelStyle: AppText.bodySoft.copyWith(fontSize: 12),
      enabledBorder: border(AppColors.line),
      border: border(AppColors.line),
      focusedBorder: border(AppColors.primary),
    ),
  );
}