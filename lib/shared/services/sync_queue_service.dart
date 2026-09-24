import 'dart:convert';

import '../../core/errors/app_error.dart';
import '../../core/json/json_reader.dart';
import '../../core/result/result.dart';
import '../infrastructure/logger_service.dart';
import '../infrastructure/serial_task_queue.dart';
import '../infrastructure/storage_gateway.dart';
import 'error_handler.dart';

class SyncQueueItem {
  final String id;
  final String module;
  final String operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const SyncQueueItem({
    required this.id,
    required this.module,
    required this.operation,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'module': module,
        'operation': operation,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'SyncQueueItem');
    return SyncQueueItem(
      id: reader.requireString('id'),
      module: reader.requireString('module'),
      operation: reader.requireString('operation'),
      payload: reader.readMap('payload'),
      createdAt: reader.requireDate('createdAt'),
    );
  }
}

class SyncQueueService {
  static const String queueKey = 'sync_queue';

  final StorageGateway storage;
  final LoggerService logger;
  final SerialTaskQueue _writeQueue = SerialTaskQueue();

  SyncQueueService(this.storage, this.logger);

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  Future<Result<void, AppError>> enqueue(SyncQueueItem item) {
    return _writeQueue.run(() => _guard('enqueue', () async {
          final queue = await _readQueue();
          await _persist([...queue, item]);
          logger.info('[SyncQueue] enqueued ${item.id}');
        }));
  }

  Future<Result<List<SyncQueueItem>, AppError>> getQueue() {
    return _writeQueue.run(() => _guard('getQueue', _readQueue));
  }

  Future<Result<void, AppError>> processQueue(
    Future<Result<void, AppError>> Function(SyncQueueItem item) processor,
  ) {
    return _writeQueue.run(() => _guard('processQueue', () async {
          final queue = await _readQueue();
          final remaining = <SyncQueueItem>[];
          for (final item in queue) {
            if (!await _processItem(item, processor)) {
              remaining.add(item);
            }
          }
          await _persist(remaining);
          logger.info('[SyncQueue] processed total=${queue.length} remaining=${remaining.length}');
        }));
  }

  Future<bool> _processItem(
    SyncQueueItem item,
    Future<Result<void, AppError>> Function(SyncQueueItem item) processor,
  ) async {
    try {
      final result = await processor(item);
      if (result.isFailure) {
        logger.warning('[SyncQueue] item ${item.id} stays queued: ${result.error!.message}');
      }
      return result.isSuccess;
    } catch (error, stackTrace) {
      _errorHandler.mapException(error, context: 'SyncQueue.process(${item.id})', stackTrace: stackTrace);
      return false;
    }
  }

  Future<List<SyncQueueItem>> _readQueue() async {
    final raw = await _readRawQueue();
    if (raw == null || raw.isEmpty) {
      return <SyncQueueItem>[];
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error, stackTrace) {
      _reportCorrupt('queue', error, stackTrace);
      return <SyncQueueItem>[];
    }
    if (decoded is! List) {
      _reportCorrupt('queue', CorruptDataError('Sync queue is not a list', source: queueKey), StackTrace.current);
      return <SyncQueueItem>[];
    }
    final items = <SyncQueueItem>[];
    for (var index = 0; index < decoded.length; index++) {
      final entry = decoded[index];
      try {
        if (entry is! Map<String, dynamic>) {
          throw CorruptDataError('Sync queue entry is not an object', source: queueKey);
        }
        items.add(SyncQueueItem.fromJson(entry));
      } on CorruptDataError catch (error, stackTrace) {
        _reportCorrupt('entry-$index', error, stackTrace);
      }
    }
    return items;
  }

  Future<String?> _readRawQueue() async {
    try {
      return await storage.get<String>(queueKey);
    } on CorruptDataError catch (error, stackTrace) {
      _reportCorrupt('queue', error, stackTrace);
      return null;
    }
  }

  Future<void> _persist(List<SyncQueueItem> items) async {
    final payload = jsonEncode(items.map((item) => item.toJson()).toList(growable: false));
    await storage.save(key: queueKey, value: payload);
  }

  void _reportCorrupt(String recordId, Object error, StackTrace stackTrace) {
    storage.integrityReporter.reportCorruptRecord(
      table: queueKey,
      recordId: recordId,
      reason: error,
      stackTrace: stackTrace,
    );
  }

  Future<Result<T, AppError>> _guard<T>(String operation, Future<T> Function() body) {
    return Result.guardAsync<T, AppError>(
      body,
      onError: (error, stackTrace) =>
          _errorHandler.mapException(error, context: 'SyncQueue.$operation', stackTrace: stackTrace),
    );
  }
}
