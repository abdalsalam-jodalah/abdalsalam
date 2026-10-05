// test/sync/sync_session_report_test.dart — verifies report totals, duration, skew warning and JSON round-trips.

import 'package:abdalsalam/core/constants/sync_constants.dart';
import 'package:abdalsalam/data/models/sync/sync_manifest.dart';
import 'package:abdalsalam/data/models/sync/sync_module_stats.dart';
import 'package:abdalsalam/data/models/sync/sync_row_stamp.dart';
import 'package:abdalsalam/data/models/sync/sync_session_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final startedAt = DateTime(2026, 10, 6, 9);

  SyncSessionReport buildReport({Duration clockSkew = Duration.zero}) {
    return SyncSessionReport(
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(seconds: 42)),
      remoteDeviceLabel: 'MacBook',
      clockSkew: clockSkew,
      safetyBackupPath: '/backups/pre-sync.zip',
      moduleStats: const {
        'notes': SyncModuleStats(
          rowsSent: 3,
          rowsReceived: 1,
          added: 1,
          skipped: 2,
          conflicts: 1,
          bytesSent: 300,
          bytesReceived: 100,
        ),
        'food': SyncModuleStats(
          rowsSent: 1,
          rowsReceived: 2,
          updated: 1,
          deleted: 1,
          attachments: 3,
          bytesSent: 5000,
          bytesReceived: 7000,
        ),
      },
    );
  }

  group('SyncSessionReport', () {
    test('should sum every module into the totals', () {
      final totals = buildReport().totals;

      expect(totals.rowsSent, 4);
      expect(totals.rowsReceived, 3);
      expect((totals.added, totals.updated, totals.deleted), (1, 1, 1));
      expect((totals.skipped, totals.conflicts), (2, 1));
      expect(totals.attachments, 3);
      expect(totals.bytesSent, 5300);
      expect(totals.bytesReceived, 7100);
    });

    test('should expose total getters and duration', () {
      final report = buildReport();

      expect(report.totalRowsSent, 4);
      expect(report.totalRowsReceived, 3);
      expect(report.totalAttachments, 3);
      expect(report.totalBytesSent, 5300);
      expect(report.totalBytesReceived, 7100);
      expect(report.duration, const Duration(seconds: 42));
    });

    test('should have empty totals when no module was touched', () {
      final report = SyncSessionReport(
        startedAt: startedAt,
        endedAt: startedAt,
        remoteDeviceLabel: 'MacBook',
        clockSkew: Duration.zero,
        moduleStats: const {},
      );

      expect(report.totals, const SyncModuleStats());
    });

    test('should warn about clock skew only above the threshold in either direction', () {
      final threshold = SyncConstants.clockSkewWarningThreshold;

      expect(buildReport(clockSkew: threshold).hasClockSkewWarning, isFalse);
      expect(buildReport(clockSkew: threshold + const Duration(seconds: 1)).hasClockSkewWarning, isTrue);
      expect(buildReport(clockSkew: -(threshold + const Duration(seconds: 1))).hasClockSkewWarning, isTrue);
    });

    test('should survive a JSON round-trip unchanged', () {
      final report = buildReport(clockSkew: const Duration(milliseconds: -1500));

      final restored = SyncSessionReport.fromJson(report.toJson());

      expect(restored, report);
    });
  });

  group('SyncManifest', () {
    test('should round-trip stamps through JSON and count rows', () {
      const manifest = SyncManifest({
        'notes': {
          'a': SyncRowStamp(updatedAt: '2026-03-01T10:00:00.000', isDeleted: false),
          'b': SyncRowStamp(updatedAt: '2026-03-02T10:00:00.000', isDeleted: true),
        },
        'todos': {},
      });

      final restored = SyncManifest.fromJson(manifest.toJson());

      expect(restored, manifest);
      expect(restored.rowCount, 2);
      expect(restored.stampsOf('missing'), isEmpty);
    });

    test('should reject a malformed stamp', () {
      expect(() => SyncRowStamp.fromJson(['only-one']), throwsFormatException);
    });
  });
}
