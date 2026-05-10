import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';

enum AppThemeVariant {
  violet,
  ocean,
  rose,
  midnight,
  forest,
  amber,
  cherry,
  arctic,
  slate,
  candy,
}

class ThemeEntry {
  const ThemeEntry({
    required this.variant,
    required this.label,
    required this.lightPrimary,
    required this.darkPrimary,
    required this.lightTheme,
    required this.darkTheme,
  });

  final AppThemeVariant variant;
  final String label;
  final Color lightPrimary;
  final Color darkPrimary;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
}

class ThemeCatalog {
  ThemeCatalog._();

  static ThemeEntry of(AppThemeVariant variant) => _map[variant]!;

  static final all = AppThemeVariant.values.map((v) => _map[v]!).toList();

  static final _map = <AppThemeVariant, ThemeEntry>{
    AppThemeVariant.violet: _make(
      variant: AppThemeVariant.violet,
      label: 'Violet',
      lightPrimary: const Color(0xFF7C3AED),
      lightPrimaryDark: const Color(0xFF5B21B6),
      lightBg: const Color(0xFFFFFFFF),
      lightSurface: const Color(0xFFF5F3FF),
      lightSurfaceAlt: const Color(0xFFEDE9FE),
      darkPrimary: const Color(0xFFA78BFA),
      darkPrimaryDark: const Color(0xFF7C3AED),
      darkBg: const Color(0xFF0F0F0F),
      darkSurface: const Color(0xFF1C1C2E),
      darkSurfaceAlt: const Color(0xFF2A2A3E),
      font: GoogleFonts.interTextTheme,
    ),
    AppThemeVariant.ocean: _make(
      variant: AppThemeVariant.ocean,
      label: 'Ocean',
      lightPrimary: const Color(0xFF0369A1),
      lightPrimaryDark: const Color(0xFF075985),
      lightBg: const Color(0xFFFFFFFF),
      lightSurface: const Color(0xFFF0F9FF),
      lightSurfaceAlt: const Color(0xFFE0F2FE),
      darkPrimary: const Color(0xFF38BDF8),
      darkPrimaryDark: const Color(0xFF0EA5E9),
      darkBg: const Color(0xFF0A0F14),
      darkSurface: const Color(0xFF0F1E2E),
      darkSurfaceAlt: const Color(0xFF1A2E40),
      font: GoogleFonts.nunitoTextTheme,
    ),
    AppThemeVariant.rose: _make(
      variant: AppThemeVariant.rose,
      label: 'Rose',
      lightPrimary: const Color(0xFFE11D48),
      lightPrimaryDark: const Color(0xFFBE123C),
      lightBg: const Color(0xFFFFFFFF),
      lightSurface: const Color(0xFFFFF1F2),
      lightSurfaceAlt: const Color(0xFFFFE4E6),
      darkPrimary: const Color(0xFFFB7185),
      darkPrimaryDark: const Color(0xFFF43F5E),
      darkBg: const Color(0xFF110A0D),
      darkSurface: const Color(0xFF1E1015),
      darkSurfaceAlt: const Color(0xFF2E1820),
      font: GoogleFonts.poppinsTextTheme,
    ),
    AppThemeVariant.midnight: _make(
      variant: AppThemeVariant.midnight,
      label: 'Midnight',
      lightPrimary: const Color(0xFF4338CA),
      lightPrimaryDark: const Color(0xFF3730A3),
      lightBg: const Color(0xFFFFFFFF),
      lightSurface: const Color(0xFFEEF2FF),
      lightSurfaceAlt: const Color(0xFFE0E7FF),
      darkPrimary: const Color(0xFF818CF8),
      darkPrimaryDark: const Color(0xFF6366F1),
      darkBg: const Color(0xFF0B0B14),
      darkSurface: const Color(0xFF14142B),
      darkSurfaceAlt: const Color(0xFF1E1E3A),
      font: GoogleFonts.plusJakartaSansTextTheme,
    ),
    AppThemeVariant.forest: _make(
      variant: AppThemeVariant.forest,
      label: 'Forest',
      lightPrimary: const Color(0xFF047857),
      lightPrimaryDark: const Color(0xFF065F46),
      lightBg: const Color(0xFFFFFFFF),
      lightSurface: const Color(0xFFF0FDF4),
      lightSurfaceAlt: const Color(0xFFDCFCE7),
      darkPrimary: const Color(0xFF34D399),
      darkPrimaryDark: const Color(0xFF10B981),
      darkBg: const Color(0xFF09110D),
      darkSurface: const Color(0xFF0F1F18),
      darkSurfaceAlt: const Color(0xFF172D22),
      font: GoogleFonts.dmSansTextTheme,
    ),
    AppThemeVariant.amber: _make(
      variant: AppThemeVariant.amber,
      label: 'Amber',
      lightPrimary: const Color(0xFFB45309),
      lightPrimaryDark: const Color(0xFF92400E),
      lightBg: const Color(0xFFFFFFFF),
      lightSurface: const Color(0xFFFFFBEB),
      lightSurfaceAlt: const Color(0xFFFEF3C7),
      darkPrimary: const Color(0xFFFBBF24),
      darkPrimaryDark: const Color(0xFFF59E0B),
      darkBg: const Color(0xFF120E05),
      darkSurface: const Color(0xFF1E1709),
      darkSurfaceAlt: const Color(0xFF2E2410),
      font: GoogleFonts.ralewayTextTheme,
    ),
    AppThemeVariant.cherry: _make(
      variant: AppThemeVariant.cherry,
      label: 'Cherry',
      lightPrimary: const Color(0xFFBE123C),
      lightPrimaryDark: const Color(0xFF9F1239),
      lightBg: const Color(0xFFFFFFFF),
      lightSurface: const Color(0xFFFFF1F2),
      lightSurfaceAlt: const Color(0xFFFFE4E6),
      darkPrimary: const Color(0xFFFDA4AF),
      darkPrimaryDark: const Color(0xFFFB7185),
      darkBg: const Color(0xFF110A0C),
      darkSurface: const Color(0xFF1F1014),
      darkSurfaceAlt: const Color(0xFF2E181E),
      font: GoogleFonts.montserratTextTheme,
    ),
    AppThemeVariant.arctic: _make(
      variant: AppThemeVariant.arctic,
      label: 'Arctic',
      lightPrimary: const Color(0xFF0E7490),
      lightPrimaryDark: const Color(0xFF155E75),
      lightBg: const Color(0xFFFFFFFF),
      lightSurface: const Color(0xFFECFEFF),
      lightSurfaceAlt: const Color(0xFFCFFAFE),
      darkPrimary: const Color(0xFF67E8F9),
      darkPrimaryDark: const Color(0xFF22D3EE),
      darkBg: const Color(0xFF060F12),
      darkSurface: const Color(0xFF0C1E24),
      darkSurfaceAlt: const Color(0xFF122E36),
      font: GoogleFonts.outfitTextTheme,
    ),
    AppThemeVariant.slate: _make(
      variant: AppThemeVariant.slate,
      label: 'Slate',
      lightPrimary: const Color(0xFF334155),
      lightPrimaryDark: const Color(0xFF1E293B),
      lightBg: const Color(0xFFFFFFFF),
      lightSurface: const Color(0xFFF8FAFC),
      lightSurfaceAlt: const Color(0xFFF1F5F9),
      darkPrimary: const Color(0xFF94A3B8),
      darkPrimaryDark: const Color(0xFF64748B),
      darkBg: const Color(0xFF0F1114),
      darkSurface: const Color(0xFF1A1E24),
      darkSurfaceAlt: const Color(0xFF252A32),
      font: GoogleFonts.ibmPlexSansTextTheme,
    ),
    AppThemeVariant.candy: _make(
      variant: AppThemeVariant.candy,
      label: 'Candy',
      lightPrimary: const Color(0xFFC026D3),
      lightPrimaryDark: const Color(0xFFA21CAF),
      lightBg: const Color(0xFFFFFFFF),
      lightSurface: const Color(0xFFFDF4FF),
      lightSurfaceAlt: const Color(0xFFFAE8FF),
      darkPrimary: const Color(0xFFE879F9),
      darkPrimaryDark: const Color(0xFFD946EF),
      darkBg: const Color(0xFF110812),
      darkSurface: const Color(0xFF1C0F1E),
      darkSurfaceAlt: const Color(0xFF2A162C),
      font: GoogleFonts.quicksandTextTheme,
    ),
  };

  static ThemeEntry _make({
    required AppThemeVariant variant,
    required String label,
    required Color lightPrimary,
    required Color lightPrimaryDark,
    required Color lightBg,
    required Color lightSurface,
    required Color lightSurfaceAlt,
    required Color darkPrimary,
    required Color darkPrimaryDark,
    required Color darkBg,
    required Color darkSurface,
    required Color darkSurfaceAlt,
    required TextTheme Function([TextTheme?]) font,
  }) {
    const lightText = Color.fromARGB(255, 255, 255, 255);
    const lightTextSec = Color(0xFF6B7280);
    const darkText = Color(0xFFF1F0FF);
    const darkTextSec = Color(0xFF9CA3AF);
    const lightError = Color(0xFFEF4444);
    const darkError = Color(0xFFF87171);

    return ThemeEntry(
      variant: variant,
      label: label,
      lightPrimary: lightPrimary,
      darkPrimary: darkPrimary,
      lightTheme: AppTheme.buildTheme(
        brightness: Brightness.light,
        primary: lightPrimary,
        primaryDark: lightPrimaryDark,
        background: lightBg,
        surface: lightSurface,
        surfaceAlt: lightSurfaceAlt,
        textPrimary: lightText,
        textSecondary: lightTextSec,
        error: lightError,
        baseTextTheme: font(),
      ),
      darkTheme: AppTheme.buildTheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        primaryDark: darkPrimaryDark,
        background: darkBg,
        surface: darkSurface,
        surfaceAlt: darkSurfaceAlt,
        textPrimary: darkText,
        textSecondary: darkTextSec,
        error: darkError,
        baseTextTheme: font(),
      ),
    );
  }
}
