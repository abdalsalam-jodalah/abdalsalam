import 'package:abdalsalam/core/theme/app_theme_builder.dart';
import 'package:abdalsalam/core/theme/app_theme_tokens.dart';
import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/core/theme/appearance_options.dart';
import 'package:abdalsalam/features/settings/screens/appearance_settings_screen.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam/providers/appearance_controller.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemorySettingsService extends SettingsService {
  _InMemorySettingsService() : super(StorageGateway.instance);

  @override
  Future<void> updateSettings(Map<String, dynamic> values) async {}
}

class _LiveThemeApp extends ConsumerWidget {
  const _LiveThemeApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    return MaterialApp(
      theme: buildAppTheme(appearance, Brightness.light),
      darkTheme: buildAppTheme(appearance, Brightness.dark),
      themeMode: appearance.themeMode,
      home: const AppearanceSettingsScreen(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    container = ProviderContainer(overrides: [settingsServiceProvider.overrideWithValue(_InMemorySettingsService())]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const _LiveThemeApp()));
    await tester.pumpAndSettle();
  }

  ThemeData currentTheme(WidgetTester tester) => Theme.of(tester.element(find.byType(AppearanceSettingsScreen)));

  testWidgets('should switch to dark mode immediately', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(currentTheme(tester).brightness, Brightness.dark);
  });

  testWidgets('should apply a new accent colour immediately', (tester) async {
    await pumpScreen(tester);
    final before = currentTheme(tester).colorScheme.primary;

    await tester.tap(find.bySemanticsLabel('Rose'));
    await tester.pumpAndSettle();

    expect(container.read(appearanceProvider).accentId, 'rose');
    expect(currentTheme(tester).colorScheme.primary, isNot(before));
  });

  testWidgets('should apply corner, density, surface, and text size options immediately', (tester) async {
    await pumpScreen(tester);
    final comfortableSpacing = AppThemeTokens.of(tester.element(find.byType(AppearanceSettingsScreen))).spacing.lg;

    await tester.tap(find.text('Extra round'));
    await tester.tap(find.text('Compact'));
    await tester.tap(find.text('Solid'));
    await tester.tap(find.text('Large'));
    await tester.pumpAndSettle();

    final appearance = container.read(appearanceProvider);
    final tokens = AppThemeTokens.of(tester.element(find.byType(AppearanceSettingsScreen)));
    expect(appearance.cornerStyle, CornerStyle.extraRound);
    expect(appearance.surfaceStyle, SurfaceStyle.solid);
    expect(appearance.textSize, TextSizeOption.large);
    expect(tokens.glass.isGlass, isFalse);
    expect(tokens.spacing.lg, lessThan(comfortableSpacing));
  });

  testWidgets('should reset everything to defaults', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset appearance'));
    await tester.pumpAndSettle();

    expect(container.read(appearanceProvider), Appearance.defaults);
  });
}
