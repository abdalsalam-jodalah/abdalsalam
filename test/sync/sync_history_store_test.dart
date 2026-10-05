// test/sync/sync_history_store_test.dart — verifies SyncHistoryStore ordering, trimming, corruption tolerance and backup exclusion.

import 'package:abdalsalam/core/constants/sync_constants.dart';
import 'package:abdalsalam/data/models/sync/sync_module_stats.dart';
import 'package:abdalsalam/data/models/sync/sync_session_report.dart';
import 'package:abdalsalam/features/sync/services/sync_history_store.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/backup_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/sync_test_storage.dart';

void main() {
  initializeSyncTestStorage();
  final storage = StorageGateway.instance;
  final baseTime = DateTime(2026, 10, 6, 9);

  SyncSessionReport reportAt(int minute) {
    return SyncSessionReport(
      startedAt: baseTime.add(Duration(minutes: minute)),
      endedAt: baseTime.add(Duration(minutes: minute, seconds: 5)),
      remoteDeviceLabel: 'MacBook',
      clockSkew: Duration.zero,
      moduleStats: {'notes': SyncModuleStats(rowsSent: minute)},
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: syncTestDatabaseName);
    await storage.delete(SyncConstants.historyPreferenceKey);
  });

  test('should return an empty list when nothing was stored', () async {
    expect(await SyncHistoryStore(storage).readAll(), isEmpty);
  });

  test('should return the newest report first', () async {
    final store = SyncHistoryStore(storage);

    await store.add(reportAt(1));
    await store.add(reportAt(2));

    final reports = await store.readAll();
    expect(reports.map((report) => report.totalRowsSent), [2, 1]);
  });

  test('should keep only the most recent reports up to the limit', () async {
    final store = SyncHistoryStore(storage, maxEntries: 3);

    for (var minute = 1; minute <= 5; minute++) {
      await store.add(reportAt(minute));
    }

    final reports = await store.readAll();
    expect(reports.map((report) => report.totalRowsSent), [5, 4, 3]);
  });

  test('should persist across store instances', () async {
    await SyncHistoryStore(storage).add(reportAt(1));

    final reports = await SyncHistoryStore(storage).readAll();

    expect(reports.single, reportAt(1));
  });

  test('should skip unreadable entries and survive corrupt stored data', () async {
    await storage.save(
      key: SyncConstants.historyPreferenceKey,
      value: [
        reportAt(1).toJson(),
        'garbage',
        {'startedAt': 'nope'},
      ],
    );
    final store = SyncHistoryStore(storage);

    expect((await store.readAll()).map((report) => report.totalRowsSent), [1]);

    await storage.save(key: SyncConstants.historyPreferenceKey, value: 'not a list');
    expect(await store.readAll(), isEmpty);
  });

  test('should clear the stored history', () async {
    final store = SyncHistoryStore(storage);
    await store.add(reportAt(1));

    await store.clear();

    expect(await store.readAll(), isEmpty);
  });

  test('should record concurrent additions without losing any', () async {
    final store = SyncHistoryStore(storage);

    await Future.wait([for (var minute = 1; minute <= 4; minute++) store.add(reportAt(minute))]);

    expect(await store.readAll(), hasLength(4));
  });

  test('should be excluded from backups as a transient preference', () {
    expect(BackupKeys.transientPreferenceKeys, contains(SyncConstants.historyPreferenceKey));
  });
}
