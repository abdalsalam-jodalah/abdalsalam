import 'package:abdalsalam/core/theme/accent_palette.dart';
import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/core/theme/appearance_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Appearance.fromSettings', () {
    test('should use defaults when nothing is stored', () {
      expect(Appearance.fromSettings(<String, dynamic>{}), Appearance.defaults);
    });

    test('should round trip through settings', () {
      const appearance = Appearance(
        accentId: 'rose',
        themeMode: ThemeMode.dark,
        cornerStyle: CornerStyle.extraRound,
        textSize: TextSizeOption.large,
        density: DensityOption.compact,
        surfaceStyle: SurfaceStyle.solid,
      );

      expect(Appearance.fromSettings(appearance.toSettings()), appearance);
    });

    test('should fall back to defaults for unknown or wrongly typed values', () {
      final appearance = Appearance.fromSettings(<String, dynamic>{
        Appearance.accentKey: 'not-a-colour',
        Appearance.themeModeKey: 42,
        Appearance.cornerStyleKey: 'spiky',
        Appearance.surfaceStyleKey: <String>[],
      });

      expect(appearance.accentId, AccentPalette.defaultId);
      expect(appearance.themeMode, ThemeMode.system);
      expect(appearance.cornerStyle, CornerStyle.round);
      expect(appearance.surfaceStyle, SurfaceStyle.glass);
    });

    test('should read the legacy themeMode setting', () {
      expect(Appearance.fromSettings(<String, dynamic>{'themeMode': 'light'}).themeMode, ThemeMode.light);
    });
  });

  group('Appearance derived values', () {
    test('should scale text by size option', () {
      expect(const Appearance(textSize: TextSizeOption.small).textScale, lessThan(1));
      expect(const Appearance(textSize: TextSizeOption.large).textScale, greaterThan(1));
    });
  });
}
