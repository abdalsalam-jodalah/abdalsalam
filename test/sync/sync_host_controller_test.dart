// test/sync/sync_host_controller_test.dart — verifies the Mac flow: hosting, adb tunnel, manual fallback, progress and stop.

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/sync/sync_phase.dart';
import 'package:abdalsalam/data/models/sync/sync_progress_event.dart';
import 'package:abdalsalam/features/sync/providers/sync_link_state.dart';
import 'package:abdalsalam/features/sync/providers/sync_providers.dart';
import 'package:abdalsalam/features/sync/services/adb_locator.dart';
import 'package:abdalsalam/features/sync/services/adb_status.dart';
import 'package:abdalsalam/features/sync/services/process_runner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_process_runner.dart';
import 'support/fake_sync_session_service.dart';
import 'support/sync_report_factory.dart';

void main() {
  const adbPath = '/fake/adb';
  const port = 47821;

  late FakeProcessRunner runner;
  late FakeSyncSessionService session;
  late ProviderContainer container;

  void respondWithDevices(String devices) {
    runner.respond('which adb', const ProcessOutcome(exitCode: 0, stdout: '$adbPath\n'));
    runner.respond('$adbPath devices', ProcessOutcome(exitCode: 0, stdout: 'List of devices attached\n$devices'));
  }

  setUp(() {
    runner = FakeProcessRunner();
    session = FakeSyncSessionService();
    container = ProviderContainer(
      overrides: [
        syncSessionServiceProvider.overrideWithValue(session),
        processRunnerProvider.overrideWithValue(runner),
        adbLocatorProvider.overrideWithValue(AdbLocator(runner: runner, fileExists: (_) => false, homeDirectory: '')),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(session.dispose);
  });

  test('should open the adb tunnel and expose the PIN when the phone is ready', () async {
    respondWithDevices('PHONE1\tdevice\n');
    runner.respond('$adbPath -s PHONE1 reverse tcp:$port tcp:$port', const ProcessOutcome(exitCode: 0));
    final controller = container.read(syncHostControllerProvider.notifier);

    final error = await controller.startLink();
    final state = container.read(syncHostControllerProvider);

    expect(error, isNull);
    expect(state.hostInfo!.pin, '123456');
    expect(state.linkState, SyncLinkState.waiting);
    expect(state.isReverseActive, isTrue);
    expect(state.manualCommand, isNull);
    expect(state.adbStatus!.kind, AdbStatusKind.ready);
  });

  test('should return the hosting error and stay stopped when the port cannot be bound', () async {
    session.hostResult = Failure(NetworkError('port busy'));
    final controller = container.read(syncHostControllerProvider.notifier);

    final error = await controller.startLink();
    final state = container.read(syncHostControllerProvider);

    expect(error!.message, 'port busy');
    expect(state.isLinkOpen, isFalse);
    expect(state.linkState, SyncLinkState.stopped);
  });

  test('should expose the manual adb command when adb cannot be found', () async {
    final controller = container.read(syncHostControllerProvider.notifier);

    await controller.startLink();
    final state = container.read(syncHostControllerProvider);

    expect(state.adbStatus!.kind, AdbStatusKind.adbMissing);
    expect(state.isLinkOpen, isTrue);
    expect(state.needsManualCommand, isTrue);
    expect(state.manualCommand, 'adb reverse tcp:$port tcp:$port');
  });

  test('should expose the manual command with the failure when adb reverse fails', () async {
    respondWithDevices('PHONE1\tdevice\n');
    runner.respond(
      '$adbPath -s PHONE1 reverse tcp:$port tcp:$port',
      const ProcessOutcome(exitCode: 1, stderr: 'denied'),
    );
    final controller = container.read(syncHostControllerProvider.notifier);

    await controller.startLink();
    final state = container.read(syncHostControllerProvider);

    expect(state.isReverseActive, isFalse);
    expect(state.reverseFailure, contains('denied'));
    expect(state.manualCommand, isNotNull);
  });

  test('should not ask for the manual command when only the phone is missing', () async {
    respondWithDevices('');
    final controller = container.read(syncHostControllerProvider.notifier);

    await controller.startLink();
    final state = container.read(syncHostControllerProvider);

    expect(state.adbStatus!.kind, AdbStatusKind.noDevice);
    expect(state.needsManualCommand, isFalse);
  });

  test('should open the tunnel on retry after the phone is plugged in', () async {
    respondWithDevices('');
    final controller = container.read(syncHostControllerProvider.notifier);
    await controller.startLink();
    respondWithDevices('PHONE1\tdevice\n');
    runner.respond('$adbPath -s PHONE1 reverse tcp:$port tcp:$port', const ProcessOutcome(exitCode: 0));

    await controller.openTunnel();

    expect(container.read(syncHostControllerProvider).isReverseActive, isTrue);
  });

  test('should follow progress events and record the finished report', () async {
    respondWithDevices('PHONE1\tdevice\n');
    runner.respond('$adbPath -s PHONE1 reverse tcp:$port tcp:$port', const ProcessOutcome(exitCode: 0));
    await container.read(syncHostControllerProvider.notifier).startLink();

    session.progressController.add(
      const SyncProgressEvent(phase: SyncPhase.sending, moduleKey: 'notes', rowsDone: 1, rowsTotal: 4),
    );
    await Future<void>.delayed(Duration.zero);
    final syncing = container.read(syncHostControllerProvider);
    final report = SyncReportFactory.transferred();
    session.reportController.add(report);
    await Future<void>.delayed(Duration.zero);
    final finished = container.read(syncHostControllerProvider);

    expect(syncing.linkState, SyncLinkState.syncing);
    expect(syncing.progress!.rowsTotal, 4);
    expect(finished.linkState, SyncLinkState.completed);
    expect(finished.lastReport, report);
  });

  test('should show failed link state when the session fails', () async {
    respondWithDevices('PHONE1\tdevice\n');
    runner.respond('$adbPath -s PHONE1 reverse tcp:$port tcp:$port', const ProcessOutcome(exitCode: 0));
    await container.read(syncHostControllerProvider.notifier).startLink();

    session.progressController.add(const SyncProgressEvent(phase: SyncPhase.failed));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(syncHostControllerProvider).linkState, SyncLinkState.failed);
  });

  test('should stop hosting and remove the adb tunnel on stop', () async {
    respondWithDevices('PHONE1\tdevice\n');
    runner.respond('$adbPath -s PHONE1 reverse tcp:$port tcp:$port', const ProcessOutcome(exitCode: 0));
    runner.respond('$adbPath -s PHONE1 reverse --remove tcp:$port', const ProcessOutcome(exitCode: 0));
    final controller = container.read(syncHostControllerProvider.notifier);
    await controller.startLink();

    await controller.stopLink();
    final state = container.read(syncHostControllerProvider);

    expect(session.stopCount, 1);
    expect(state.isLinkOpen, isFalse);
    expect(state.linkState, SyncLinkState.stopped);
    expect(runner.invocations, contains('$adbPath -s PHONE1 reverse --remove tcp:$port'));
  });
}
