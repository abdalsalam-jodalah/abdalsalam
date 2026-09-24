import 'package:abdalsalam/core/theme/app_theme_builder.dart';
import 'package:abdalsalam/core/theme/app_theme_tokens.dart';
import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/core/theme/appearance_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance() ? foreground : background;
  final darker = identical(lighter, foreground) ? background : foreground;
  return (lighter.computeLuminance() + 0.05) / (darker.computeLuminance() + 0.05);
}

void main() {
  const minimumTextContrast = 4.5;

  AppThemeTokens tokensOf(ThemeData theme) => theme.extension<AppThemeTokens>()!;

  double cardRadius(ThemeData theme) {
    final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
    return (shape.borderRadius as BorderRadius).topLeft.x;
  }

  group('buildAppTheme', () {
    test('should generate the colour scheme from the chosen accent', () {
      final lagoon = buildAppTheme(const Appearance(accentId: 'lagoon'), Brightness.light);
      final rose = buildAppTheme(const Appearance(accentId: 'rose'), Brightness.light);

      expect(lagoon.colorScheme.primary, isNot(rose.colorScheme.primary));
    });

    test('should make corners rounder for rounder corner styles', () {
      final soft = buildAppTheme(const Appearance(cornerStyle: CornerStyle.soft), Brightness.light);
      final extra = buildAppTheme(const Appearance(cornerStyle: CornerStyle.extraRound), Brightness.light);

      expect(cardRadius(extra), greaterThan(cardRadius(soft)));
    });

    test('should tighten spacing and density in compact mode', () {
      final comfortable = buildAppTheme(const Appearance(), Brightness.light);
      final compact = buildAppTheme(const Appearance(density: DensityOption.compact), Brightness.light);

      expect(tokensOf(compact).spacing.lg, lessThan(tokensOf(comfortable).spacing.lg));
      expect(compact.visualDensity, VisualDensity.compact);
    });

    test('should turn glass off in solid surface style', () {
      final glass = buildAppTheme(const Appearance(), Brightness.dark);
      final solid = buildAppTheme(const Appearance(surfaceStyle: SurfaceStyle.solid), Brightness.dark);

      expect(tokensOf(glass).glass.isGlass, isTrue);
      expect(tokensOf(solid).glass.isGlass, isFalse);
      expect(tokensOf(solid).glass.blurSigma, 0);
      expect(solid.cardTheme.color!.a, 1);
    });

    test('should use the bundled font with an Arabic fallback', () {
      final theme = buildAppTheme(Appearance.defaults, Brightness.light);

      expect(theme.textTheme.bodyMedium?.fontFamily, appFontFamily);
      expect(theme.textTheme.bodyMedium?.fontFamilyFallback, contains('IBMPlexSansArabic'));
    });

    test('should theme page transitions for every platform', () {
      final theme = buildAppTheme(Appearance.defaults, Brightness.light);

      expect(theme.pageTransitionsTheme.builders.keys, containsAll(TargetPlatform.values));
    });

    for (final brightness in Brightness.values) {
      for (final surface in SurfaceStyle.values) {
        test('should keep text readable on cards ($brightness, $surface)', () {
          final theme = buildAppTheme(Appearance(surfaceStyle: surface), brightness);
          final card = Color.alphaBlend(theme.cardTheme.color!, tokensOf(theme).backgroundGradient[1]);

          expect(_contrastRatio(theme.colorScheme.onSurface, card), greaterThanOrEqualTo(minimumTextContrast));
          expect(
            _contrastRatio(theme.colorScheme.onSurfaceVariant, card),
            greaterThanOrEqualTo(minimumTextContrast),
          );
        });
      }
    }
  });
}
