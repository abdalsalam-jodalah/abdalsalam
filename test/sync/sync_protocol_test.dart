// test/sync/sync_protocol_test.dart — end-to-end sync between two in-memory stores over a real loopback HttpServer.

import 'dart:io';
import 'dart:typed_data';

import 'package:abdalsalam/core/constants/sync_constants.dart';
import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/sync/sync_phase.dart';
import 'package:abdalsalam/data/models/sync/sync_progress_event.dart';
import 'package:abdalsalam/data/models/sync/sync_session_report.dart';
import 'package:abdalsalam/features/sync/services/sync_client.dart';
import 'package:abdalsalam/features/sync/services/sync_errors.dart';
import 'package:abdalsalam/features/sync/services/sync_http_transport.dart';
import 'package:abdalsalam/features/sync/services/sync_pairing_service.dart';
import 'package:abdalsalam/features/sync/services/sync_protocol.dart';
import 'package:abdalsalam/features/sync/services/sync_server.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_sync_data_store.dart';
import 'support/fake_sync_safety_backup.dart';
import 'support/sync_row_factory.dart';

void main() {
  const older = '2026-03-01T10:00:00.000';
  const newer = '2026-03-02T10:00:00.000';
  const ephemeralPort = 0;
  const phoneLabel = 'Pixel';
  const macLabel = 'MacBook';

  late FakeSyncDataStore phoneStore;
  late FakeSyncDataStore macStore;
  late FakeSyncSafetyBackup phoneBackup;
  late FakeSyncSafetyBackup macBackup;
  late SyncServer server;
  late SyncClient client;
  late int port;
  late List<SyncProgressEvent> serverEvents;
  late List<SyncSessionReport> serverReports;

  Map<String, dynamic> reminder(String targetId) => {
    'module': 'health',
    'targetId': targetId,
    'title': 'Reminder $targetId',
    'scheduledAt': newer,
  };

  setUpAll(() async {
    await LoggerService.initialize();
  });

  setUp(() async {
    phoneBackup = FakeSyncSafetyBackup();
    macBackup = FakeSyncSafetyBackup();
    phoneStore = FakeSyncDataStore(
      attachmentTables: {'food_logs'},
      rows: {
        'notes': [
          syncRow('n1', updatedAt: newer, title: 'phone edit'),
          syncRow('n2', updatedAt: older),
          syncRow('n3', updatedAt: older),
          syncRow('n4', updatedAt: newer, deletedAt: newer),
        ],
        'habits': [syncRow('h1', updatedAt: older, title: 'phone stale')],
        'food_logs': [
          syncRow('f1', updatedAt: older, extra: {FakeSyncDataStore.attachmentField: 'phone/f1.jpg'}),
        ],
        'credentials': [syncRow('phone-secret', updatedAt: newer)],
      },
    );
    phoneStore.files['phone/f1.jpg'] = Uint8List.fromList([1, 2, 3]);
    phoneStore.reminders.addAll([reminder('r1'), reminder('r3')]);
    macStore = FakeSyncDataStore(
      attachmentTables: {'food_logs'},
      rows: {
        'notes': [
          syncRow('n1', updatedAt: older, title: 'mac stale'),
          syncRow('n2', updatedAt: older),
          syncRow('n4', updatedAt: older),
          syncRow('n5', updatedAt: older),
        ],
        'habits': [syncRow('h1', updatedAt: newer, title: 'mac edit'), syncRow('h2', updatedAt: older)],
        'food_logs': [
          syncRow('f2', updatedAt: older, extra: {FakeSyncDataStore.attachmentField: 'mac/f2.jpg'}),
        ],
        'credentials': [syncRow('mac-secret', updatedAt: newer)],
      },
    );
    macStore.files['mac/f2.jpg'] = Uint8List.fromList([9, 8]);
    macStore.reminders.addAll([reminder('r2'), reminder('r3')]);

    final logger = LoggerService.forModule('SyncProtocolTest');
    server = SyncServer(
      store: macStore,
      pairing: SyncPairingService(),
      safetyBackup: macBackup,
      logger: logger,
      deviceLabel: macLabel,
    );
    client = SyncClient(store: phoneStore, safetyBackup: phoneBackup, logger: logger, deviceLabel: phoneLabel);
    serverEvents = <SyncProgressEvent>[];
    serverReports = <SyncSessionReport>[];
    server.events.listen(serverEvents.add);
    server.completedReports.listen(serverReports.add);
    port = await server.start(port: ephemeralPort);
  });

  tearDown(() async {
    await server.dispose();
  });

  Future<SyncSessionReport> syncPhone() async {
    final outcome = await client.run(pin: server.pin!, port: port);
    expect(outcome.error, isNull);
    await pumpEventQueue();
    return outcome.data!;
  }

  group('SyncServer and SyncClient', () {
    test('should leave both stores identical for synced tables with no duplicates', () async {
      await syncPhone();

      for (final table in ['notes', 'habits']) {
        expect(phoneStore.rowsOf(table), macStore.rowsOf(table), reason: table);
      }
      expect(phoneStore.rowsOf('notes').keys.toSet(), {'n1', 'n2', 'n3', 'n4', 'n5'});
      expect(phoneStore.rowsOf('notes')['n1']!['title'], 'phone edit');
      expect(macStore.rowsOf('notes')['n4']!['deletedAt'], newer);
      expect(macStore.rowsOf('habits')['h1']!['title'], 'mac edit');
      expect(phoneStore.rowsOf('habits').keys.toSet(), {'h1', 'h2'});
    });

    test('should move attachments with their rows and rewrite the path on the receiver', () async {
      await syncPhone();

      expect(macStore.rowsOf('food_logs')['f1']![FakeSyncDataStore.attachmentField], 'local/f1.jpg');
      expect(macStore.files['local/f1.jpg'], Uint8List.fromList([1, 2, 3]));
      expect(phoneStore.rowsOf('food_logs')['f2']![FakeSyncDataStore.attachmentField], 'local/f2.jpg');
      expect(phoneStore.files['local/f2.jpg'], Uint8List.fromList([9, 8]));
    });

    test('should never transfer the credentials tables in either direction', () async {
      final report = await syncPhone();

      expect(phoneStore.rowsOf('credentials').keys, ['phone-secret']);
      expect(macStore.rowsOf('credentials').keys, ['mac-secret']);
      expect(report.moduleStats.containsKey('security'), isFalse);
    });

    test('should report accurate counts from the client perspective', () async {
      final report = await syncPhone();

      final notes = report.moduleStats['notes']!;
      expect(notes.rowsSent, 3);
      expect(notes.rowsReceived, 1);
      expect((notes.added, notes.updated, notes.deleted), (1, 0, 0));
      expect((notes.skipped, notes.conflicts), (1, 2));
      expect(notes.bytesSent, greaterThan(0));
      expect(notes.bytesReceived, greaterThan(0));
      final habits = report.moduleStats['habits']!;
      expect((habits.rowsSent, habits.rowsReceived), (0, 2));
      expect((habits.added, habits.updated), (1, 1));
      final food = report.moduleStats['food']!;
      expect((food.rowsSent, food.rowsReceived, food.attachments), (1, 1, 2));
      expect(report.remoteDeviceLabel, macLabel);
      expect(report.safetyBackupPath, FakeSyncSafetyBackup.savedPath);
      expect(report.totalRowsSent, 4);
      expect(report.totalRowsReceived, 4);
    });

    test('should report accurate counts from the host perspective', () async {
      await syncPhone();

      final report = serverReports.single;
      final notes = report.moduleStats['notes']!;
      expect(notes.rowsSent, 1);
      expect(notes.rowsReceived, 3);
      expect((notes.added, notes.updated, notes.deleted), (1, 1, 1));
      expect((notes.skipped, notes.conflicts), (1, 2));
      expect(report.remoteDeviceLabel, phoneLabel);
      expect(report.moduleStats.containsKey('security'), isFalse);
    });

    test('should transfer nothing on a second sync', () async {
      await syncPhone();

      final second = await syncPhone();

      expect(second.totalRowsSent, 0);
      expect(second.totalRowsReceived, 0);
      expect(second.totalAttachments, 0);
      expect(second.totals.skipped, greaterThan(0));
      expect(serverReports.last.totalRowsReceived, 0);
    });

    test('should write a safety backup and apply rows in one transaction on each side', () async {
      await syncPhone();

      expect(phoneBackup.createCount, 1);
      expect(macBackup.createCount, 1);
      expect(phoneStore.appliedBatches, hasLength(1));
      expect(macStore.appliedBatches, hasLength(1));
    });

    test('should union reminders on both sides', () async {
      await syncPhone();

      final phoneTargets = phoneStore.reminders.map((item) => item['targetId']).toSet();
      final macTargets = macStore.reminders.map((item) => item['targetId']).toSet();
      expect(phoneTargets, {'r1', 'r2', 'r3'});
      expect(macTargets, {'r1', 'r2', 'r3'});
      expect(phoneStore.reminders, hasLength(3));
    });

    test('should emit progress events through the host phases', () async {
      await syncPhone();

      final phases = serverEvents.map((event) => event.phase).toSet();
      expect(
        phases,
        containsAll([
          SyncPhase.waiting,
          SyncPhase.connecting,
          SyncPhase.comparing,
          SyncPhase.receiving,
          SyncPhase.sending,
          SyncPhase.applying,
          SyncPhase.completed,
        ]),
      );
    });

    test('should emit client progress events and finish with completed', () async {
      final events = <SyncProgressEvent>[];

      await client.run(pin: server.pin!, port: port, onProgress: events.add);

      expect(events.first.phase, SyncPhase.connecting);
      expect(events.last.phase, SyncPhase.completed);
      expect(events.map((event) => event.moduleKey), contains('notes'));
    });

    test('should reject a wrong PIN, change nothing and then lock out after repeated failures', () async {
      final before = phoneStore.rowsOf('notes').length;

      final failures = <AppError?>[];
      for (var attempt = 0; attempt < SyncConstants.maxFailedPinAttempts; attempt++) {
        failures.add((await client.run(pin: 'x$attempt', port: port)).error);
      }
      final afterLockout = await client.run(pin: server.pin!, port: port);

      expect(failures.first, isA<SyncPinRejectedError>());
      expect(failures.last, isA<SyncLockedOutError>());
      expect(afterLockout.error, isA<SyncLockedOutError>());
      expect(phoneStore.rowsOf('notes'), hasLength(before));
      expect(phoneBackup.createCount, 0);
    });

    test('should refuse requests without a valid session token', () async {
      final transport = SyncHttpTransport(host: SyncConstants.loopbackHost, port: port);

      await expectLater(
        transport.post(SyncEndpoints.diff, const SyncDiffRequest(table: 'notes', stamps: {}).toJson()),
        throwsA(isA<SyncUnauthorizedError>()),
      );
      transport.close();
    });

    test('should refuse to diff a credentials table even with a valid session', () async {
      final transport = SyncHttpTransport(host: SyncConstants.loopbackHost, port: port);
      final hello = await transport.post(
        SyncEndpoints.hello,
        SyncHelloRequest(
          pin: server.pin!,
          deviceLabel: phoneLabel,
          clientTimeMilliseconds: DateTime.now().millisecondsSinceEpoch,
          protocolVersion: SyncConstants.protocolVersion,
        ).toJson(),
      );
      transport.token = SyncHelloResponse.fromJson(hello.json).token;

      await expectLater(
        transport.post(SyncEndpoints.diff, const SyncDiffRequest(table: 'credentials', stamps: {}).toJson()),
        throwsA(isA<SyncBadRequestError>()),
      );
      await expectLater(
        transport.post(SyncEndpoints.pull, const SyncPullRequest(table: 'credentials', ids: ['mac-secret']).toJson()),
        throwsA(isA<SyncBadRequestError>()),
      );
      transport.close();
    });

    test('should reject a second device while a session is open', () async {
      final firstTransport = SyncHttpTransport(host: SyncConstants.loopbackHost, port: port);
      final secondTransport = SyncHttpTransport(host: SyncConstants.loopbackHost, port: port);
      final hello = SyncHelloRequest(
        pin: server.pin!,
        deviceLabel: phoneLabel,
        clientTimeMilliseconds: DateTime.now().millisecondsSinceEpoch,
        protocolVersion: SyncConstants.protocolVersion,
      ).toJson();
      await firstTransport.post(SyncEndpoints.hello, hello);

      await expectLater(secondTransport.post(SyncEndpoints.hello, hello), throwsA(isA<SyncSessionBusyError>()));
      firstTransport.close();
      secondTransport.close();
    });

    test('should reject a client with an incompatible protocol version', () async {
      final transport = SyncHttpTransport(host: SyncConstants.loopbackHost, port: port);

      await expectLater(
        transport.post(
          SyncEndpoints.hello,
          SyncHelloRequest(
            pin: server.pin!,
            deviceLabel: phoneLabel,
            clientTimeMilliseconds: 0,
            protocolVersion: SyncConstants.protocolVersion + 1,
          ).toJson(),
        ),
        throwsA(isA<SyncVersionMismatchError>()),
      );
      transport.close();
    });

    test('should refuse non-POST requests', () async {
      final httpClient = HttpClient();
      final request = await httpClient.get(SyncConstants.loopbackHost, port, SyncEndpoints.hello);
      final response = await request.close();
      await response.drain<void>();
      httpClient.close(force: true);

      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('should leave local data untouched and free the host when the local safety backup fails', () async {
      phoneBackup.isFailing = true;
      final notesBefore = phoneStore.rowsOf('notes').keys.toSet();

      final failed = await client.run(pin: server.pin!, port: port);
      final notesAfterFailure = phoneStore.rowsOf('notes').keys.toSet();
      phoneBackup.isFailing = false;
      final retried = await client.run(pin: server.pin!, port: port);

      expect(failed.error, isA<ExportError>());
      expect(notesAfterFailure, notesBefore);
      expect(phoneStore.appliedBatches.length, 1);
      expect(retried.isSuccess, isTrue);
      expect(macBackup.createCount, 1);
    });

    test('should fail with a network error when the host is not running', () async {
      final pin = server.pin!;
      await server.stop();

      final outcome = await client.run(pin: pin, port: port);

      expect(outcome.error, isA<NetworkError>());
    });
  });
}
