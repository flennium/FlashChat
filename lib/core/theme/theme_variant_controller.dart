import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme_variant.dart';

const _themeVariantKey = 'theme_variant';

final themeVariantControllerProvider =
    StateNotifierProvider<ThemeVariantController, AppThemeVariant>(
  (ref) => ThemeVariantController()..load(),
);

class ThemeVariantController extends StateNotifier<AppThemeVariant> {
  ThemeVariantController() : super(AppThemeVariant.violet);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeVariantKey);
    if (raw != null) {
      final match = AppThemeVariant.values.where((v) => v.name == raw).firstOrNull;
      if (match != null) state = match;
    }
  }

  Future<void> setVariant(AppThemeVariant variant) async {
    state = variant;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeVariantKey, variant.name);
  }
}
