import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/accent_palette.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/theme/appearance.dart';
import '../../../core/theme/appearance_options.dart';
import '../../../providers/appearance_controller.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../widgets/accent_swatch_picker.dart';
import '../widgets/appearance_preview_card.dart';
import '../widgets/appearance_segmented_setting.dart';
import '../widgets/settings_section_header.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  static const routeName = '/settings/appearance';

  static const String _title = 'Appearance';
  static const String _themeSection = 'Theme';
  static const String _shapeSection = 'Shape & size';
  static const String _accentSection = 'Accent colour';
  static const String _resetLabel = 'Reset appearance';

  const AppearanceSettingsScreen({super.key});

  Future<void> _apply(BuildContext context, WidgetRef ref, Appearance Function(Appearance current) change) async {
    final error = await ref.read(appearanceProvider.notifier).update(change(ref.read(appearanceProvider)));
    if (error != null && context.mounted) {
      AppFeedback.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final spacing = AppThemeTokens.of(context).spacing;
    return Scaffold(
      appBar: AppBar(title: const Text(_title)),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          const AppearancePreviewCard(),
          const SettingsSectionHeader(_themeSection),
          AppearanceSegmentedSetting<ThemeMode>(
            title: 'Mode',
            value: appearance.themeMode,
            options: const [
              AppearanceSegmentOption(ThemeMode.light, 'Light', icon: Icons.light_mode_rounded),
              AppearanceSegmentOption(ThemeMode.system, 'System', icon: Icons.brightness_auto_rounded),
              AppearanceSegmentOption(ThemeMode.dark, 'Dark', icon: Icons.dark_mode_rounded),
            ],
            onChanged: (value) => _apply(context, ref, (current) => current.copyWith(themeMode: value)),
          ),
          AppearanceSegmentedSetting<SurfaceStyle>(
            title: 'Surfaces',
            subtitle: 'Glass uses soft translucent cards over a gentle gradient',
            value: appearance.surfaceStyle,
            options: const [
              AppearanceSegmentOption(SurfaceStyle.glass, 'Glass', icon: Icons.blur_on_rounded),
              AppearanceSegmentOption(SurfaceStyle.solid, 'Solid', icon: Icons.crop_square_rounded),
            ],
            onChanged: (value) => _apply(context, ref, (current) => current.copyWith(surfaceStyle: value)),
          ),
          const SettingsSectionHeader(_accentSection),
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.sm),
            child: AccentSwatchPicker(
              options: AccentPalette.options,
              selectedId: appearance.accentId,
              onSelected: (option) => _apply(context, ref, (current) => current.copyWith(accentId: option.id)),
            ),
          ),
          const SettingsSectionHeader(_shapeSection),
          AppearanceSegmentedSetting<CornerStyle>(
            title: 'Corners',
            value: appearance.cornerStyle,
            options: const [
              AppearanceSegmentOption(CornerStyle.soft, 'Soft'),
              AppearanceSegmentOption(CornerStyle.round, 'Round'),
              AppearanceSegmentOption(CornerStyle.extraRound, 'Extra round'),
            ],
            onChanged: (value) => _apply(context, ref, (current) => current.copyWith(cornerStyle: value)),
          ),
          AppearanceSegmentedSetting<TextSizeOption>(
            title: 'Text size',
            value: appearance.textSize,
            options: const [
              AppearanceSegmentOption(TextSizeOption.small, 'Small'),
              AppearanceSegmentOption(TextSizeOption.standard, 'Default'),
              AppearanceSegmentOption(TextSizeOption.large, 'Large'),
            ],
            onChanged: (value) => _apply(context, ref, (current) => current.copyWith(textSize: value)),
          ),
          AppearanceSegmentedSetting<DensityOption>(
            title: 'Density',
            value: appearance.density,
            options: const [
              AppearanceSegmentOption(DensityOption.comfortable, 'Comfortable'),
              AppearanceSegmentOption(DensityOption.compact, 'Compact'),
            ],
            onChanged: (value) => _apply(context, ref, (current) => current.copyWith(density: value)),
          ),
          SizedBox(height: spacing.lg),
          OutlinedButton.icon(
            onPressed: () async {
              final error = await ref.read(appearanceProvider.notifier).reset();
              if (error != null && context.mounted) {
                AppFeedback.showError(context, error);
              }
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text(_resetLabel),
          ),
        ],
      ),
    );
  }
}
