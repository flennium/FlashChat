import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextTheme textTheme(
    Color primary,
    Color secondary, {
    TextTheme? base,
  }) {
    final b = (base ?? GoogleFonts.interTextTheme()).apply(
      bodyColor: primary,
      displayColor: primary,
      decorationColor: primary,
    );

    return b.copyWith(
      displayLarge: b.displayLarge?.copyWith(
        color: primary,
      ),
      displayMedium: b.displayMedium?.copyWith(
        color: primary,
      ),
      displaySmall: b.displaySmall?.copyWith(
        color: primary,
      ),
      headlineLarge: b.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: primary,
      ),
      headlineMedium: b.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleLarge: b.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: b.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: b.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: b.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: b.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodySmall: b.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelMedium: b.labelMedium?.copyWith(
        color: secondary,
      ),
      labelSmall: b.labelSmall?.copyWith(
        color: secondary,
      ),
      labelLarge: b.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
    );
  }
}
