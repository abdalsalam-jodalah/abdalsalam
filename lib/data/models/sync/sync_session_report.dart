// lib/data/models/sync/sync_session_report.dart — the summary of one finished sync session, per module and in total.

import 'package:equatable/equatable.dart';

import '../../../core/constants/sync_constants.dart';
import '../../../core/json/json_reader.dart';
import 'sync_module_stats.dart';

class SyncSessionReport extends Equatable {
  static const String _source = 'SyncSessionReport';

  final DateTime startedAt;
  final DateTime endedAt;
  final String remoteDeviceLabel;
  final Duration clockSkew;
  final Map<String, SyncModuleStats> moduleStats;
  final String? safetyBackupPath;

  const SyncSessionReport({
    required this.startedAt,
    required this.endedAt,
    required this.remoteDeviceLabel,
    required this.clockSkew,
    required this.moduleStats,
    this.safetyBackupPath,
  });

  factory SyncSessionReport.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: _source);
    return SyncSessionReport(
      startedAt: reader.requireDate('startedAt'),
      endedAt: reader.requireDate('endedAt'),
      remoteDeviceLabel: reader.readString('remoteDeviceLabel'),
      clockSkew: Duration(milliseconds: reader.readInt('clockSkewMilliseconds')),
      moduleStats: <String, SyncModuleStats>{
        for (final entry in reader.readMap('moduleStats').entries)
          if (entry.value is Map) entry.key: SyncModuleStats.fromJson(Map<String, dynamic>.from(entry.value as Map)),
      },
      safetyBackupPath: reader.optionalString('safetyBackupPath'),
    );
  }

  Duration get duration => endedAt.difference(startedAt);

  SyncModuleStats get totals => moduleStats.values.fold<SyncModuleStats>(const SyncModuleStats(), (sum, stats) => sum + stats);

  int get totalRowsSent => totals.rowsSent;
  int get totalRowsReceived => totals.rowsReceived;
  int get totalAttachments => totals.attachments;
  int get totalBytesSent => totals.bytesSent;
  int get totalBytesReceived => totals.bytesReceived;

  bool get hasClockSkewWarning => clockSkew.abs() > SyncConstants.clockSkewWarningThreshold;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'remoteDeviceLabel': remoteDeviceLabel,
      'clockSkewMilliseconds': clockSkew.inMilliseconds,
      'moduleStats': <String, dynamic>{for (final entry in moduleStats.entries) entry.key: entry.value.toJson()},
      'safetyBackupPath': safetyBackupPath,
    };
  }

  @override
  List<Object?> get props => [startedAt, endedAt, remoteDeviceLabel, clockSkew, moduleStats, safetyBackupPath];
}
