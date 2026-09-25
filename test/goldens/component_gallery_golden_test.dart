import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/core/theme/appearance_options.dart';
import 'package:abdalsalam/shared/widgets/ui/component_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_harness.dart';

void main() {
  setUpAll(loadGoldenFonts);

  const variants = <String, (Appearance, Brightness)>{
    'light_glass': (Appearance.defaults, Brightness.light),
    'dark_glass': (Appearance(themeMode: ThemeMode.dark, accentId: 'violet'), Brightness.dark),
    'light_solid_soft': (
      Appearance(surfaceStyle: SurfaceStyle.solid, cornerStyle: CornerStyle.soft, accentId: 'emerald'),
      Brightness.light,
    ),
    'dark_solid_compact': (
      Appearance(surfaceStyle: SurfaceStyle.solid, density: DensityOption.compact, accentId: 'coral'),
      Brightness.dark,
    ),
  };

  for (final entry in variants.entries) {
    testWidgets('component gallery ${entry.key}', (tester) async {
      await setGoldenSurface(tester, const Size(430, 2600));
      final (appearance, brightness) = entry.value;
      await tester.pumpWidget(ProviderScope(
        child: goldenHost(appearance: appearance, brightness: brightness, child: const ComponentGalleryScreen()),
      ));
      await tester.pump(const Duration(seconds: 1));

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/component_gallery_${entry.key}.png'));
    });
  }
}
