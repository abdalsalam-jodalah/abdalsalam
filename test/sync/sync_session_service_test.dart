// test/sync/sync_session_service_test.dart — verifies hosting, joining, progress, history and change hooks of SyncSessionService.

import 'dart:io';

import 'package:abdalsalam/core/constants/sync_constants.dart';
import 'package:abdalsalam/data/models/sync/sync_phase.dart';
import 'package:abdalsalam/data/models/sync/sync_progress_event.dart';
import 'package:abdalsalam/data/models/sync/sync_session_report.dart';
import 'package:abdalsalam/features/sync/services/sync_client.dart';
import 'package:abdalsalam/features/sync/services/sync_errors.dart';
import 'package:abdalsalam/features/sync/services/sync_history_store.dart';
import 'package:abdalsalam/features/sync/services/sync_pairing_service.dart';
import 'package:abdalsalam/features/sync/services/sync_server.dart';
import 'package:abdalsalam/features/sync/services/sync_session_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_sync_data_store.dart';
import 'support/fake_sync_safety_backup.dart';
import 'support/sync_row_factory.dart';
import 'support/sync_test_storage.dart';

void main() {
  initializeSyncTestStorage();
  HttpOverrides.global = null;
  const ephemeralPort = 0;
  const older = '2026-03-01T10:00:00.000';
  final storage = StorageGateway.instance;

  late SyncSessionService hostService;
  late SyncSessionService joinService;
  late FakeSyncDataStore hostStore;
  late FakeSyncDataStore joinStore;
  late int hostChangeCount;
  late int joinChangeCount;

  SyncSessionService buildService(FakeSyncDataStore store, String label, void Function() onChanged) {
    final logger = LoggerService.forModule('SyncSessionServiceTest');
    final backup = FakeSyncSafetyBackup();
    return SyncSessionService(
      server: SyncServer(
        store: store,
        pairing: SyncPairingService(),
        safetyBackup: backup,
        logger: logger,
        deviceLabel: label,
      ),
      client: SyncClient(store: store, safetyBackup: backup, logger: logger, deviceLabel: label),
      history: SyncHistoryStore(storage),
      logger: logger,
      onDataChanged: () async => onChanged(),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: syncTestDatabaseName);
    await storage.delete(SyncConstants.historyPreferenceKey);
    hostChangeCount = 0;
    joinChangeCount = 0;
    hostStore = FakeSyncDataStore(
      rows: {
        'notes': [syncRow('mac-note', updatedAt: older)],
      },
    );
    joinStore = FakeSyncDataStore(
      rows: {
        'notes': [syncRow('phone-note', updatedAt: older)],
      },
    );
    hostService = buildService(hostStore, 'MacBook', () => hostChangeCount++);
    joinService = buildService(joinStore, 'Pixel', () => joinChangeCount++);
  });

  tearDown(() async {
    await hostService.dispose();
    await joinService.dispose();
  });

  test('should expose the bound port and a PIN when hosting starts', () async {
    final result = await hostService.startHosting(port: ephemeralPort);

    expect(result.isSuccess, isTrue);
    expect(result.data!.pin, matches(RegExp('^\\d{${SyncConstants.pinLength}}\$')));
    expect(result.data!.port, greaterThan(0));
    expect(hostService.isHosting, isTrue);
  });

  test('should stop hosting and invalidate the PIN', () async {
    await hostService.startHosting(port: ephemeralPort);

    await hostService.stopHosting();

    expect(hostService.isHosting, isFalse);
    expect(hostService.server.pin, isNull);
  });

  test('should sync both devices, record history and notify each side once', () async {
    final host = (await hostService.startHosting(port: ephemeralPort)).data!;
    final hostReport = hostService.completedReports.first;

    final outcome = await joinService.joinHost(pin: host.pin, port: host.port);
    final hostSideReport = await hostReport;

    expect(outcome.isSuccess, isTrue);
    expect(joinStore.rowsOf('notes').keys.toSet(), {'mac-note', 'phone-note'});
    expect(hostStore.rowsOf('notes').keys.toSet(), {'mac-note', 'phone-note'});
    expect(outcome.data!.totalRowsSent, 1);
    expect(outcome.data!.totalRowsReceived, 1);
    expect(hostSideReport.remoteDeviceLabel, 'Pixel');
    expect(joinChangeCount, 1);
    expect(hostChangeCount, 1);
    expect(await joinService.readHistory(), hasLength(2));
  });

  test('should emit progress from the joining side ending in completed', () async {
    final host = (await hostService.startHosting(port: ephemeralPort)).data!;
    final events = <SyncProgressEvent>[];
    final subscription = joinService.progress.listen(events.add);

    await joinService.joinHost(pin: host.pin, port: host.port);
    await subscription.cancel();

    expect(events.first.phase, SyncPhase.connecting);
    expect(events.last.phase, SyncPhase.completed);
    expect(joinService.isJoining, isFalse);
  });

  test('should emit hosting progress through the service', () async {
    final events = <SyncProgressEvent>[];
    final subscription = hostService.progress.listen(events.add);
    final host = (await hostService.startHosting(port: ephemeralPort)).data!;
    final reportFuture = hostService.completedReports.first;

    await joinService.joinHost(pin: host.pin, port: host.port);
    await reportFuture;
    await subscription.cancel();

    expect(events.map((event) => event.phase), containsAll([SyncPhase.connecting, SyncPhase.completed]));
  });

  test('should return the failure and keep history empty when the PIN is wrong', () async {
    final host = (await hostService.startHosting(port: ephemeralPort)).data!;
    final wrongPin = host.pin == '000000' ? '111111' : '000000';

    final outcome = await joinService.joinHost(pin: wrongPin, port: host.port);

    expect(outcome.error, isA<SyncPinRejectedError>());
    expect(await joinService.readHistory(), isEmpty);
    expect(joinChangeCount, 0);
    expect(joinStore.rowsOf('notes').keys, ['phone-note']);
  });

  test('should return a report whose totals match its modules', () async {
    final host = (await hostService.startHosting(port: ephemeralPort)).data!;

    final report = (await joinService.joinHost(pin: host.pin, port: host.port)).data as SyncSessionReport;

    expect(report.totals.rowsSent, report.moduleStats['notes']!.rowsSent);
    expect(report.totals.added, 1);
  });
}
