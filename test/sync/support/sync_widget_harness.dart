// test/sync/support/sync_widget_harness.dart — pumps sync screens inside a ProviderScope with fake services and a test router.

import 'package:abdalsalam/core/constants/sync_constants.dart';
import 'package:abdalsalam/data/models/sync/sync_session_report.dart';
import 'package:abdalsalam/features/sync/providers/sync_providers.dart';
import 'package:abdalsalam/features/sync/screens/sync_hub_screen.dart';
import 'package:abdalsalam/features/sync/screens/sync_report_screen.dart';
import 'package:abdalsalam/features/sync/services/adb_locator.dart';
import 'package:abdalsalam/features/sync/services/sync_platform_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_process_runner.dart';
import 'fake_sync_session_service.dart';

class SyncWidgetHarness {
  final FakeProcessRunner runner = FakeProcessRunner();
  final FakeSyncSessionService session = FakeSyncSessionService();
  final SyncPlatformRole role;
  final List<SyncSessionReport> history;

  SyncWidgetHarness({required this.role, this.history = const <SyncSessionReport>[]});

  Future<void> pumpHub(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(session.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncPlatformRoleProvider.overrideWithValue(role),
          syncSessionServiceProvider.overrideWithValue(session),
          processRunnerProvider.overrideWithValue(runner),
          adbLocatorProvider.overrideWithValue(AdbLocator(runner: runner, fileExists: (_) => false, homeDirectory: '')),
          syncHistoryProvider.overrideWith((ref) async => history),
        ],
        child: MaterialApp(
          initialRoute: SyncConstants.routeName,
          onGenerateRoute: (settings) {
            return switch (settings.name) {
              SyncConstants.routeName => MaterialPageRoute<void>(
                builder: (_) => const SyncHubScreen(),
                settings: settings,
              ),
              SyncConstants.reportRouteName => MaterialPageRoute<void>(
                builder: (_) => SyncReportScreen(report: settings.arguments as SyncSessionReport),
                settings: settings,
              ),
              _ => null,
            };
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}
