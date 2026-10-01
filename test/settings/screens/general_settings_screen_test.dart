import 'package:abdalsalam/features/settings/screens/general_settings_screen.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettingsService extends SettingsService {
  final Map<String, dynamic> stored;
  final Map<String, dynamic> updates = <String, dynamic>{};

  _FakeSettingsService(this.stored) : super(StorageGateway.instance);

  @override
  Future<Map<String, dynamic>> getSettings() async => <String, dynamic>{...defaults, ...stored};

  @override
  Future<void> updateSetting(String key, dynamic value) async {
    updates[key] = value;
  }
}

void main() {
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 8000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget host(SettingsService service) {
    return ProviderScope(
      overrides: [settingsServiceProvider.overrideWithValue(service)],
      child: const MaterialApp(home: GeneralSettingsScreen()),
    );
  }

  group('SettingsService defaults', () {
    test('should close the sidebar after ten seconds by default', () {
      expect(SettingsService(StorageGateway.instance).defaults['sidebarAutoCloseSeconds'], 10);
    });
  });

  testWidgets('should show the current sidebar auto-close time', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(host(_FakeSettingsService({'sidebarAutoCloseSeconds': 30})));
    await tester.pumpAndSettle();

    expect(find.text('Close sidebar when untouched'), findsOneWidget);
    expect(find.text('After 30 seconds'), findsOneWidget);
  });

  testWidgets('should show ten seconds when nothing has been chosen yet', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(host(_FakeSettingsService(const {})));
    await tester.pumpAndSettle();

    expect(find.text('After 10 seconds'), findsOneWidget);
  });

  testWidgets('should save the chosen time', (tester) async {
    useTallScreen(tester);
    final service = _FakeSettingsService(const {});
    await tester.pumpWidget(host(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Close sidebar when untouched'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('After 20 seconds').last);
    await tester.pumpAndSettle();

    expect(service.updates['sidebarAutoCloseSeconds'], 20);
  });

  testWidgets('should allow turning the auto-close off', (tester) async {
    useTallScreen(tester);
    final service = _FakeSettingsService(const {});
    await tester.pumpWidget(host(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Close sidebar when untouched'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Never').last);
    await tester.pumpAndSettle();

    expect(service.updates['sidebarAutoCloseSeconds'], 0);
  });
}
