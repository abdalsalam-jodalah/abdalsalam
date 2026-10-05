// test/sync/support/sync_report_factory.dart — builds SyncSessionReport values for controller and widget tests.

import 'package:abdalsalam/data/models/sync/sync_module_stats.dart';
import 'package:abdalsalam/data/models/sync/sync_session_report.dart';

class SyncReportFactory {
  const SyncReportFactory._();

  static SyncSessionReport transferred({Duration clockSkew = Duration.zero}) {
    return SyncSessionReport(
      startedAt: DateTime(2026, 3, 1, 10),
      endedAt: DateTime(2026, 3, 1, 10, 0, 5),
      remoteDeviceLabel: 'Phone',
      clockSkew: clockSkew,
      moduleStats: const <String, SyncModuleStats>{
        'notes': SyncModuleStats(
          rowsSent: 3,
          rowsReceived: 2,
          added: 2,
          updated: 1,
          bytesSent: 2048,
          bytesReceived: 512,
        ),
        'financial': SyncModuleStats(skipped: 9),
      },
      safetyBackupPath: '/backups/pre-sync.zip',
    );
  }

  static SyncSessionReport empty() {
    return SyncSessionReport(
      startedAt: DateTime(2026, 3, 2, 9),
      endedAt: DateTime(2026, 3, 2, 9, 0, 1),
      remoteDeviceLabel: 'Mac',
      clockSkew: Duration.zero,
      moduleStats: const <String, SyncModuleStats>{'notes': SyncModuleStats(skipped: 4)},
    );
  }
}
