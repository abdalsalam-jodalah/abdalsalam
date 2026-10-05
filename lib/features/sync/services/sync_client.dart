// lib/features/sync/services/sync_client.dart — connects to a sync host with its PIN and runs a full session, returning a Result.

import '../../../core/constants/sync_constants.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/sync/sync_phase.dart';
import '../../../data/models/sync/sync_progress_event.dart';
import '../../../data/models/sync/sync_session_report.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/services/error_handler.dart';
import 'sync_client_session.dart';
import 'sync_data_store.dart';
import 'sync_http_transport.dart';
import 'sync_safety_backup.dart';

class SyncClient {
  final SyncDataStore store;
  final SyncSafetyBackup safetyBackup;
  final LoggerService logger;
  final String deviceLabel;
  final DateTime Function() _clock;

  SyncClient({
    required this.store,
    required this.safetyBackup,
    required this.logger,
    required this.deviceLabel,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  Future<Result<SyncSessionReport, AppError>> run({
    required String pin,
    String host = SyncConstants.loopbackHost,
    int port = SyncConstants.defaultPort,
    void Function(SyncProgressEvent event)? onProgress,
  }) async {
    final transport = SyncHttpTransport(host: host, port: port);
    final emit = onProgress ?? (SyncProgressEvent _) {};
    try {
      final report = await SyncClientSession(
        store: store,
        safetyBackup: safetyBackup,
        transport: transport,
        deviceLabel: deviceLabel,
        clock: _clock,
        emit: emit,
      ).run(pin);
      logger.info('[SyncClient] sync completed rows=${report.totalRowsSent}/${report.totalRowsReceived}');
      return Success(report);
    } catch (error, stackTrace) {
      emit(const SyncProgressEvent(phase: SyncPhase.failed));
      return Failure(_errorHandler.mapException(error, context: 'SyncClient.run', stackTrace: stackTrace));
    } finally {
      transport.close();
    }
  }
}
