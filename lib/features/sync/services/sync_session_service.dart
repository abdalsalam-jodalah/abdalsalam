// lib/features/sync/services/sync_session_service.dart — orchestrates hosting and joining sync sessions, progress, reports and history.

import 'dart:async';

import '../../../core/constants/sync_constants.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/sync/sync_progress_event.dart';
import '../../../data/models/sync/sync_session_report.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/services/error_handler.dart';
import 'sync_client.dart';
import 'sync_history_store.dart';
import 'sync_host_info.dart';
import 'sync_server.dart';

class SyncSessionService {
  final SyncServer server;
  final SyncClient client;
  final SyncHistoryStore history;
  final LoggerService logger;
  final Future<void> Function()? _onDataChanged;
  final StreamController<SyncProgressEvent> _progress = StreamController<SyncProgressEvent>.broadcast();
  final StreamController<SyncSessionReport> _reports = StreamController<SyncSessionReport>.broadcast();

  StreamSubscription<SyncProgressEvent>? _serverProgressSubscription;
  StreamSubscription<SyncSessionReport>? _serverReportSubscription;
  bool _isJoining = false;

  SyncSessionService({
    required this.server,
    required this.client,
    required this.history,
    required this.logger,
    Future<void> Function()? onDataChanged,
  }) : _onDataChanged = onDataChanged;

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  bool get isHosting => server.isRunning;

  bool get isJoining => _isJoining;

  Stream<SyncProgressEvent> get progress => _progress.stream;

  Stream<SyncSessionReport> get completedReports => _reports.stream;

  Future<List<SyncSessionReport>> readHistory() => history.readAll();

  Future<Result<SyncHostInfo, AppError>> startHosting({int port = SyncConstants.defaultPort}) async {
    try {
      final boundPort = await server.start(port: port);
      _serverProgressSubscription ??= server.events.listen(_progress.add);
      _serverReportSubscription ??= server.completedReports.listen((report) => unawaited(_finishSession(report)));
      return Success(SyncHostInfo(port: boundPort, pin: server.pin!));
    } catch (error, stackTrace) {
      return Failure(
        _errorHandler.mapException(error, context: 'SyncSessionService.startHosting', stackTrace: stackTrace),
      );
    }
  }

  Future<void> stopHosting() async {
    await _serverProgressSubscription?.cancel();
    await _serverReportSubscription?.cancel();
    _serverProgressSubscription = null;
    _serverReportSubscription = null;
    await server.stop();
  }

  Future<Result<SyncSessionReport, AppError>> joinHost({
    required String pin,
    String host = SyncConstants.loopbackHost,
    int port = SyncConstants.defaultPort,
  }) async {
    _isJoining = true;
    try {
      final outcome = await client.run(pin: pin, host: host, port: port, onProgress: _progress.add);
      if (outcome.isSuccess) {
        await _finishSession(outcome.data!);
      }
      return outcome;
    } finally {
      _isJoining = false;
    }
  }

  Future<void> dispose() async {
    await stopHosting();
    await _progress.close();
    await _reports.close();
  }

  Future<void> _finishSession(SyncSessionReport report) async {
    try {
      await history.add(report);
      await _onDataChanged?.call();
    } catch (error, stackTrace) {
      _errorHandler.mapException(error, context: 'SyncSessionService.finishSession', stackTrace: stackTrace);
    }
    if (!_reports.isClosed) {
      _reports.add(report);
    }
  }
}
