import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/core/theme/appearance_options.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam/providers/appearance_controller.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingSettingsService extends SettingsService {
  final List<Map<String, dynamic>> savedValues = <Map<String, dynamic>>[];
  bool isFailing = false;

  _RecordingSettingsService() : super(StorageGateway.instance);

  @override
  Future<void> updateSettings(Map<String, dynamic> values) async {
    if (isFailing) {
      throw StateError('disk full');
    }
    savedValues.add(values);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingSettingsService settings;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    settings = _RecordingSettingsService();
    container = ProviderContainer(overrides: [
      settingsServiceProvider.overrideWithValue(settings),
      initialAppearanceProvider.overrideWithValue(const Appearance(accentId: 'ocean')),
    ]);
  });

  tearDown(() => container.dispose());

  test('should start from the appearance loaded at startup', () {
    expect(container.read(appearanceProvider).accentId, 'ocean');
  });

  test('should apply and persist a change', () async {
    final next = container.read(appearanceProvider).copyWith(themeMode: ThemeMode.dark);

    final error = await container.read(appearanceProvider.notifier).update(next);

    expect(error, isNull);
    expect(container.read(appearanceProvider).themeMode, ThemeMode.dark);
    expect(settings.savedValues.single[Appearance.themeModeKey], 'dark');
  });

  test('should keep the previous appearance and return an error when saving fails', () async {
    settings.isFailing = true;
    final next = container.read(appearanceProvider).copyWith(cornerStyle: CornerStyle.soft);

    final error = await container.read(appearanceProvider.notifier).update(next);

    expect(error, isA<AppError>());
    expect(container.read(appearanceProvider).cornerStyle, CornerStyle.round);
  });

  test('should reset to defaults', () async {
    await container.read(appearanceProvider.notifier).reset();

    expect(container.read(appearanceProvider), Appearance.defaults);
  });
}
