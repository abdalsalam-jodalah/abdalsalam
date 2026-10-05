// test/sync/sync_hub_screen_test.dart — widget tests for the sync hub in Mac, phone and unsupported modes.

import 'package:abdalsalam/core/constants/sync_ui_text.dart';
import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/features/sync/screens/sync_report_screen.dart';
import 'package:abdalsalam/features/sync/services/process_runner.dart';
import 'package:abdalsalam/features/sync/services/sync_platform_role.dart';
import 'package:abdalsalam/features/sync/widgets/sync_history_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sync_report_factory.dart';
import 'support/sync_widget_harness.dart';

void main() {
  const adbPath = '/fake/adb';

  void respondWithDevices(SyncWidgetHarness harness, String devices) {
    harness.runner.respond('which adb', const ProcessOutcome(exitCode: 0, stdout: '$adbPath\n'));
    harness.runner.respond(
      '$adbPath devices',
      ProcessOutcome(exitCode: 0, stdout: 'List of devices attached\n$devices'),
    );
  }

  group('unsupported platform', () {
    testWidgets('should explain that sync is unavailable', (tester) async {
      await SyncWidgetHarness(role: SyncPlatformRole.unsupported).pumpHub(tester);

      expect(find.text(SyncUiText.unsupportedTitle), findsOneWidget);
      expect(find.text(SyncUiText.startLinkLabel), findsNothing);
      expect(find.text(SyncUiText.syncNowLabel), findsNothing);
    });
  });

  group('Mac mode', () {
    testWidgets('should show the adb missing message and the manual command after starting the link', (tester) async {
      final harness = SyncWidgetHarness(role: SyncPlatformRole.host);
      await harness.pumpHub(tester);

      expect(find.text(SyncUiText.adbMissingTitle), findsOneWidget);
      expect(find.text(SyncUiText.startLinkLabel), findsOneWidget);

      await tester.tap(find.text(SyncUiText.startLinkLabel));
      await tester.pumpAndSettle();

      expect(find.text('123456'), findsOneWidget);
      expect(find.text(SyncUiText.linkWaiting), findsOneWidget);
      expect(find.text(SyncUiText.manualCommandTitle), findsOneWidget);
      expect(find.text('adb reverse tcp:47821 tcp:47821'), findsOneWidget);
      expect(find.text(SyncUiText.stopLinkLabel), findsOneWidget);
    });

    testWidgets('should show the phone as connected when adb lists an authorized device', (tester) async {
      final harness = SyncWidgetHarness(role: SyncPlatformRole.host);
      respondWithDevices(harness, 'PHONE1\tdevice\n');

      await harness.pumpHub(tester);

      expect(find.text(SyncUiText.readyTitle), findsOneWidget);
      expect(find.text('${SyncUiText.readyMessagePrefix}PHONE1'), findsOneWidget);
    });

    testWidgets('should tell the user to authorize USB debugging when the phone is unauthorized', (tester) async {
      final harness = SyncWidgetHarness(role: SyncPlatformRole.host);
      respondWithDevices(harness, 'PHONE1\tunauthorized\n');

      await harness.pumpHub(tester);

      expect(find.text(SyncUiText.unauthorizedTitle), findsOneWidget);
      expect(find.text(SyncUiText.unauthorizedMessage), findsOneWidget);
    });

    testWidgets('should show no-device guidance and re-check on demand', (tester) async {
      final harness = SyncWidgetHarness(role: SyncPlatformRole.host);
      respondWithDevices(harness, '');
      await harness.pumpHub(tester);
      expect(find.text(SyncUiText.noDeviceTitle), findsOneWidget);

      respondWithDevices(harness, 'PHONE1\tdevice\n');
      await tester.tap(find.text(SyncUiText.checkAgainLabel));
      await tester.pumpAndSettle();

      expect(find.text(SyncUiText.readyTitle), findsOneWidget);
    });

    testWidgets('should stop the link and hide the PIN', (tester) async {
      final harness = SyncWidgetHarness(role: SyncPlatformRole.host);
      await harness.pumpHub(tester);
      await tester.tap(find.text(SyncUiText.startLinkLabel));
      await tester.pumpAndSettle();

      await tester.tap(find.text(SyncUiText.stopLinkLabel));
      await tester.pumpAndSettle();

      expect(find.text('123456'), findsNothing);
      expect(find.text(SyncUiText.startLinkLabel), findsOneWidget);
      expect(harness.session.stopCount, 1);
    });

    testWidgets('should show the last run and history and open the report from a tile', (tester) async {
      final harness = SyncWidgetHarness(
        role: SyncPlatformRole.host,
        history: [SyncReportFactory.transferred(), SyncReportFactory.empty()],
      );
      await harness.pumpHub(tester);

      expect(find.text(SyncUiText.lastRunSection), findsOneWidget);
      expect(find.byType(SyncHistoryTile), findsNWidgets(2));

      await tester.tap(find.byType(SyncHistoryTile).first);
      await tester.pumpAndSettle();

      expect(find.byType(SyncReportScreen), findsOneWidget);
    });
  });

  group('phone mode', () {
    testWidgets('should reject an incomplete PIN with feedback', (tester) async {
      final harness = SyncWidgetHarness(role: SyncPlatformRole.client);
      await harness.pumpHub(tester);

      await tester.enterText(find.byType(TextField), '12');
      await tester.tap(find.text(SyncUiText.syncNowLabel));
      await tester.pump();

      expect(find.text(SyncUiText.invalidPinMessage), findsOneWidget);
      expect(harness.session.joinedPin, isNull);
    });

    testWidgets('should show feedback and stay on the hub when the host rejects the PIN', (tester) async {
      final harness = SyncWidgetHarness(role: SyncPlatformRole.client);
      harness.session.joinResult = Failure(AuthError('wrong pin'));
      await harness.pumpHub(tester);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text(SyncUiText.syncNowLabel));
      await tester.pump();

      expect(harness.session.joinedPin, '123456');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(SyncReportScreen), findsNothing);
    });

    testWidgets('should open the report after a successful sync', (tester) async {
      final harness = SyncWidgetHarness(role: SyncPlatformRole.client);
      harness.session.joinResult = Success(SyncReportFactory.transferred());
      await harness.pumpHub(tester);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text(SyncUiText.syncNowLabel));
      await tester.pumpAndSettle();

      expect(find.byType(SyncReportScreen), findsOneWidget);
      expect(find.text(SyncUiText.totalsSection), findsOneWidget);
    });

    testWidgets('should not show Mac-only controls', (tester) async {
      await SyncWidgetHarness(role: SyncPlatformRole.client).pumpHub(tester);

      expect(find.text(SyncUiText.startLinkLabel), findsNothing);
      expect(find.text(SyncUiText.checkAgainLabel), findsNothing);
    });
  });
}
