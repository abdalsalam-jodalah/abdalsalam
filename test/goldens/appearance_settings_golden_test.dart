import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/core/theme/appearance_options.dart';
import 'package:abdalsalam/features/settings/screens/appearance_settings_screen.dart';
import 'package:abdalsalam/providers/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_harness.dart';

void main() {
  setUpAll(loadGoldenFonts);

  const variants = <String, (Appearance, Brightness)>{
    'light_glass': (Appearance.defaults, Brightness.light),
    'dark_glass': (Appearance(themeMode: ThemeMode.dark), Brightness.dark),
    'light_solid_soft': (Appearance(surfaceStyle: SurfaceStyle.solid, cornerStyle: CornerStyle.soft, accentId: 'emerald'), Brightness.light),
  };

  for (final entry in variants.entries) {
    testWidgets('appearance settings ${entry.key}', (tester) async {
      await setGoldenSurface(tester, const Size(430, 1100));
      final (appearance, brightness) = entry.value;
      await tester.pumpWidget(ProviderScope(
        overrides: [initialAppearanceProvider.overrideWithValue(appearance)],
        child: goldenHost(appearance: appearance, brightness: brightness, child: const AppearanceSettingsScreen()),
      ));
      await tester.pumpAndSettle();

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/appearance_settings_${entry.key}.png'));
    });
  }
}
