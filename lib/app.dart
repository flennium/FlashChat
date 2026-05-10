import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme_variant.dart';
import 'core/theme/theme_mode_controller.dart';
import 'core/theme/theme_variant_controller.dart';
import 'features/auth/screens/splash_screen.dart';

class FlashChatApp extends ConsumerWidget {
  const FlashChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final variant = ref.watch(themeVariantControllerProvider);
    final entry = ThemeCatalog.of(variant);

    return MaterialApp(
      title: 'FlashChat',
      debugShowCheckedModeBanner: false,
      theme: entry.lightTheme,
      darkTheme: entry.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
