import 'dart:convert';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/sync_queue_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storage = StorageGateway.instance;
  late SyncQueueService service;

  SyncQueueItem item(String id) => SyncQueueItem(
        id: id,
        module: 'notes',
        operation: 'create',
        payload: {'id': id},
        createdAt: DateTime(2026, 1, 1),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_sync_queue_service_test.db');
    await storage.delete(SyncQueueService.queueKey);
    storage.integrityReporter.clearReports();
    service = SyncQueueService(storage, LoggerService.forModule('SyncQueueTest'));
  });

  test('should keep every item when many are enqueued at the same time', () async {
    await Future.wait([for (var i = 0; i < 20; i++) service.enqueue(item('item-$i'))]);

    final queue = await service.getQueue();

    expect(queue.data, hasLength(20));
  });

  test('should skip and report a corrupt entry but keep the valid ones', () async {
    await storage.save(
      key: SyncQueueService.queueKey,
      value: jsonEncode([
        item('good').toJson(),
        {'id': 'broken'},
      ]),
    );

    final queue = await service.getQueue();

    expect(queue.data?.map((entry) => entry.id), ['good']);
    expect(storage.integrityReporter.corruptRecordCount, 1);
  });

  test('should keep items whose processing fails or throws and remove the successful ones', () async {
    for (final id in ['ok', 'fails', 'throws']) {
      await service.enqueue(item(id));
    }

    final result = await service.processQueue((entry) async {
      if (entry.id == 'fails') {
        return Failure(NetworkError('offline'));
      }
      if (entry.id == 'throws') {
        throw StateError('boom');
      }
      return const Success(null);
    });

    expect(result.isSuccess, isTrue);
    expect((await service.getQueue()).data?.map((entry) => entry.id), ['fails', 'throws']);
  });
}
