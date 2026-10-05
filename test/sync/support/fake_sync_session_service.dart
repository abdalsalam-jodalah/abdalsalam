// test/sync/support/fake_sync_session_service.dart — SyncSessionService fake with scripted results and manually pushed events.

import 'dart:async';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/sync/sync_progress_event.dart';
import 'package:abdalsalam/data/models/sync/sync_session_report.dart';
import 'package:abdalsalam/features/sync/services/sync_client.dart';
import 'package:abdalsalam/features/sync/services/sync_history_store.dart';
import 'package:abdalsalam/features/sync/services/sync_host_info.dart';
import 'package:abdalsalam/features/sync/services/sync_server.dart';
import 'package:abdalsalam/features/sync/services/sync_session_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';

class FakeSyncSessionService implements SyncSessionService {
  final StreamController<SyncProgressEvent> progressController = StreamController<SyncProgressEvent>.broadcast();
  final StreamController<SyncSessionReport> reportController = StreamController<SyncSessionReport>.broadcast();

  Result<SyncHostInfo, AppError> hostResult = const Success(SyncHostInfo(port: 47821, pin: '123456'));
  Result<SyncSessionReport, AppError>? joinResult;
  Completer<Result<SyncSessionReport, AppError>>? joinGate;
  int startCount = 0;
  int stopCount = 0;
  String? joinedPin;

  @override
  Stream<SyncProgressEvent> get progress => progressController.stream;

  @override
  Stream<SyncSessionReport> get completedReports => reportController.stream;

  @override
  bool get isHosting => startCount > stopCount;

  @override
  bool get isJoining => joinGate != null && !joinGate!.isCompleted;

  @override
  Future<Result<SyncHostInfo, AppError>> startHosting({int port = 0}) async {
    startCount++;
    return hostResult;
  }

  @override
  Future<void> stopHosting() async {
    stopCount++;
  }

  @override
  Future<Result<SyncSessionReport, AppError>> joinHost({required String pin, String host = '', int port = 0}) {
    joinedPin = pin;
    final gate = joinGate;
    if (gate != null) {
      return gate.future;
    }
    return Future.value(joinResult!);
  }

  @override
  Future<List<SyncSessionReport>> readHistory() async => const <SyncSessionReport>[];

  @override
  Future<void> dispose() async {
    await progressController.close();
    await reportController.close();
  }

  @override
  SyncServer get server => throw UnimplementedError();

  @override
  SyncClient get client => throw UnimplementedError();

  @override
  SyncHistoryStore get history => throw UnimplementedError();

  @override
  LoggerService get logger => throw UnimplementedError();
}
