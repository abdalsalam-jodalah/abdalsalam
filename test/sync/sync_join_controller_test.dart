// test/sync/sync_join_controller_test.dart — verifies the phone flow: PIN validation, progress while joining and outcomes.

import 'dart:async';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/sync/sync_phase.dart';
import 'package:abdalsalam/data/models/sync/sync_progress_event.dart';
import 'package:abdalsalam/data/models/sync/sync_session_report.dart';
import 'package:abdalsalam/features/sync/providers/sync_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_sync_session_service.dart';
import 'support/sync_report_factory.dart';

void main() {
  late FakeSyncSessionService session;
  late ProviderContainer container;

  setUp(() {
    session = FakeSyncSessionService();
    container = ProviderContainer(overrides: [syncSessionServiceProvider.overrideWithValue(session)]);
    addTearDown(container.dispose);
    addTearDown(session.dispose);
  });

  test('should reject a PIN that is not six digits without contacting the host', () async {
    final controller = container.read(syncJoinControllerProvider.notifier);

    final outcome = await controller.join('12ab');

    expect(outcome.isFailure, isTrue);
    expect(outcome.error, isA<ValidationError>());
    expect(session.joinedPin, isNull);
  });

  test('should join with the trimmed PIN and keep the report on success', () async {
    final report = SyncReportFactory.transferred();
    session.joinResult = Success(report);
    final controller = container.read(syncJoinControllerProvider.notifier);

    final outcome = await controller.join(' 123456 ');
    final state = container.read(syncJoinControllerProvider);

    expect(outcome.data, report);
    expect(session.joinedPin, '123456');
    expect(state.isJoining, isFalse);
    expect(state.lastReport, report);
  });

  test('should keep the previous report and return the error when joining fails', () async {
    session.joinResult = Failure(AuthError('wrong pin'));
    final controller = container.read(syncJoinControllerProvider.notifier);

    final outcome = await controller.join('123456');

    expect(outcome.error!.message, 'wrong pin');
    expect(container.read(syncJoinControllerProvider).isJoining, isFalse);
    expect(container.read(syncJoinControllerProvider).lastReport, isNull);
  });

  test('should expose progress while joining and refuse a second join', () async {
    session.joinGate = Completer<Result<SyncSessionReport, AppError>>();
    final controller = container.read(syncJoinControllerProvider.notifier);

    final running = controller.join('123456');
    session.progressController.add(
      const SyncProgressEvent(phase: SyncPhase.receiving, moduleKey: 'notes', rowsDone: 2, rowsTotal: 5),
    );
    await Future<void>.delayed(Duration.zero);
    final duringState = container.read(syncJoinControllerProvider);
    final second = await controller.join('123456');
    session.joinGate!.complete(Success(SyncReportFactory.empty()));
    await running;

    expect(duringState.isJoining, isTrue);
    expect(duringState.progress!.phase, SyncPhase.receiving);
    expect(second.isFailure, isTrue);
    expect(container.read(syncJoinControllerProvider).isJoining, isFalse);
  });
}
