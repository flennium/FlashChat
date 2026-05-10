// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flashchat/core/theme/app_theme_variant.dart';
import 'package:flashchat/features/home/screens/home_screen.dart';

void main() {
  testWidgets('home preview renders key FlashChat content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeCatalog.of(AppThemeVariant.ocean).lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    expect(find.text('FlashChat'), findsOneWidget);
    expect(find.text('Build Firebase step by step'), findsOneWidget);
    expect(find.text('Create Room'), findsOneWidget);
  });
}
