import 'dart:convert';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../infrastructure/logger_service.dart';
import '../infrastructure/storage_gateway.dart';

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

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
        id: json['id'].toString(),
        module: json['module'].toString(),
        operation: json['operation'].toString(),
        payload: (json['payload'] as Map).cast<String, dynamic>(),
        createdAt: DateTime.parse(json['createdAt'].toString()),
      );
}

class SyncQueueService {
  static const _queueKey = 'sync_queue';

  final StorageGateway storage;
  final LoggerService logger;

  const SyncQueueService(this.storage, this.logger);

  Future<Result<void, AppError>> enqueue(SyncQueueItem item) async {
    try {
      final queue = await getQueue();
      if (queue.isFailure) {
        return Failure(queue.error!);
      }

      final updated = [...queue.data!, item];
      await _persist(updated);
      logger.info('[SyncQueue] enqueued ${item.id}');
      return const Success(null);
    } catch (e, st) {
      logger.error('[SyncQueue] enqueue failed', error: e, stackTrace: st);
      return Failure(ServiceError(e.toString()));
    }
  }

  Future<Result<List<SyncQueueItem>, AppError>> getQueue() async {
    try {
      final raw = await storage.get<String>(_queueKey);
      if (raw == null || raw.isEmpty) {
        return const Success(<SyncQueueItem>[]);
      }
      final decoded = jsonDecode(raw) as List<dynamic>;
      final items = decoded
          .whereType<Map<String, dynamic>>()
          .map(SyncQueueItem.fromJson)
          .toList(growable: false);
      return Success(items);
    } catch (e, st) {
      logger.error('[SyncQueue] getQueue failed', error: e, stackTrace: st);
      return Failure(ServiceError(e.toString()));
    }
  }

  Future<Result<void, AppError>> processQueue(
    Future<Result<void, AppError>> Function(SyncQueueItem item) processor,
  ) async {
    final queueResult = await getQueue();
    if (queueResult.isFailure) {
      return Failure(queueResult.error!);
    }

    final remaining = <SyncQueueItem>[];
    for (final item in queueResult.data!) {
      final result = await processor(item);
      if (result.isFailure) {
        remaining.add(item);
      }
    }

    await _persist(remaining);
    logger.info('[SyncQueue] processed total=${queueResult.data!.length} remaining=${remaining.length}');
    return const Success(null);
  }

  Future<void> _persist(List<SyncQueueItem> items) async {
    final payload = jsonEncode(items.map((item) => item.toJson()).toList(growable: false));
    await storage.save(key: _queueKey, value: payload);
  }
}
