import 'package:flutter/material.dart';

import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color primaryDark,
    required Color background,
    required Color surface,
    required Color surfaceAlt,
    required Color textPrimary,
    required Color textSecondary,
    required Color error,
    TextTheme? baseTextTheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final outline =
        isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1);
    final outlineVariant =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0);
    final inputFill = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.03), surfaceAlt)
        : surfaceAlt;
    final inputLabel = isDark
        ? textSecondary.withValues(alpha: 0.92)
        : const Color(0xFF475569);
    final inputHint = isDark
        ? textSecondary.withValues(alpha: 0.78)
        : const Color(0xFF64748B);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: primaryDark,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceAlt,
      outline: outline,
      outlineVariant: outlineVariant,
      onSurfaceVariant: inputLabel,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: AppTextStyles.textTheme(textPrimary, textSecondary,
          base: baseTextTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: surface.withValues(alpha: 0.95),
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.textTheme(textPrimary, textSecondary,
                base: baseTextTheme)
            .titleLarge
            ?.copyWith(color: primary),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          color: textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        color: surface,
        shadowColor: primary.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        labelStyle: TextStyle(
          color: inputLabel,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: primary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(
          color: inputHint,
        ),
        helperStyle: TextStyle(
          color: inputHint,
        ),
        prefixStyle: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        suffixStyle: TextStyle(
          color: textPrimary,
        ),
        iconColor: inputLabel,
        prefixIconColor: inputLabel,
        suffixIconColor: inputLabel,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: error, width: 1.6),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color:
                states.contains(WidgetState.selected) ? primary : textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        selectedColor: primary.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelStyle: TextStyle(color: textPrimary),
      ),
    );
  }
}
