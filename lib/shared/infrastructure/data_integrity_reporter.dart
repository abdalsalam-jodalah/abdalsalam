import 'dart:async';

import 'corrupt_record_report.dart';
import 'logger_service.dart';

class DataIntegrityReporter {
  final Map<String, CorruptRecordReport> _reports = <String, CorruptRecordReport>{};
  final StreamController<int> _countController = StreamController<int>.broadcast();

  LoggerService get _logger => LoggerService.forModule('DataIntegrity');

  int get corruptRecordCount => _reports.length;

  List<CorruptRecordReport> get reports => List<CorruptRecordReport>.unmodifiable(_reports.values);

  Stream<int> get corruptRecordCountChanges => _countController.stream;

  void reportCorruptRecord({
    required String table,
    required String recordId,
    required Object reason,
    StackTrace? stackTrace,
  }) {
    final reportKey = '$table:$recordId';
    if (_reports.containsKey(reportKey)) {
      return;
    }
    _reports[reportKey] = CorruptRecordReport(
      table: table,
      recordId: recordId,
      reason: reason.toString(),
      detectedAt: DateTime.now(),
    );
    _logger.error(
      '[$table] skipped unreadable record $recordId',
      error: reason,
      stackTrace: stackTrace,
    );
    _countController.add(_reports.length);
  }

  void clearReports() {
    _reports.clear();
    _countController.add(0);
  }
}
