import 'package:abdalsalam/shared/services/backup_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 10, 12);

  group('BackupStatus', () {
    test('should count days from the last export when there is one', () {
      final status = BackupStatus(trackingStartedAt: DateTime(2026, 9, 1), lastExportedAt: DateTime(2026, 10, 5, 12));

      expect(status.daysSinceLastExport(now), 5);
    });

    test('should count days from when tracking started when nothing was ever exported', () {
      final status = BackupStatus(trackingStartedAt: DateTime(2026, 10, 3, 12));

      expect(status.daysSinceLastExport(now), 7);
    });

    test('should have no days count before tracking has started', () {
      expect(const BackupStatus().daysSinceLastExport(now), isNull);
    });

    test('should be due when the reminder interval has passed', () {
      final status = BackupStatus(lastExportedAt: DateTime(2026, 10, 3, 12));

      expect(status.isExportReminderDue(reminderDays: 7, now: now), isTrue);
    });

    test('should not be due before the reminder interval has passed', () {
      final status = BackupStatus(lastExportedAt: DateTime(2026, 10, 4, 12));

      expect(status.isExportReminderDue(reminderDays: 7, now: now), isFalse);
    });

    test('should not be due before tracking has started', () {
      expect(const BackupStatus().isExportReminderDue(reminderDays: 1, now: now), isFalse);
    });

    test('should survive a JSON round trip', () {
      final status = BackupStatus(
        trackingStartedAt: DateTime(2026, 9, 1),
        lastExportedAt: DateTime(2026, 10, 5),
        lastAutoBackupAt: DateTime(2026, 10, 6),
      );

      final restored = BackupStatus.fromJson(status.toJson());

      expect(restored.trackingStartedAt, status.trackingStartedAt);
      expect(restored.lastExportedAt, status.lastExportedAt);
      expect(restored.lastAutoBackupAt, status.lastAutoBackupAt);
    });

    test('should read missing fields as unset', () {
      final restored = BackupStatus.fromJson(const {});

      expect(restored.lastExportedAt, isNull);
      expect(restored.lastAutoBackupAt, isNull);
    });
  });
}
