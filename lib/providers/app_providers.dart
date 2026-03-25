import 'dart:async';

import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result/result.dart';
import '../shared/infrastructure/logger_service.dart';
import '../shared/infrastructure/storage_gateway.dart';
import '../shared/services/state_aware_service.dart';
import '../shared/services/sync_queue_service.dart';

final loggerProvider = Provider<LoggerService>((ref) {
  return LoggerService.forModule('App', moduleType: logic.ModuleType.service);
});

final storageGatewayProvider = Provider<StorageGateway>((ref) {
  return StorageGateway.instance;
});

final appStateManagerProvider = Provider<logic.AppStateManager>((ref) {
  throw UnimplementedError('appStateManagerProvider must be overridden in main.dart');
});

final appStateInfoProvider = StreamProvider<logic.AppStateInfo>((ref) {
  final appState = ref.watch(appStateManagerProvider);
  return appState.stateStream;
});

final batteryInfoProvider = StreamProvider<logic.BatteryInfo>((ref) {
  final appState = ref.watch(appStateManagerProvider);
  return appState.batteryStream;
});

final storageInfoProvider = StreamProvider<logic.StorageInfo>((ref) {
  final appState = ref.watch(appStateManagerProvider);
  return appState.storageStream;
});

final isOfflineProvider = Provider<bool>((ref) {
  final appState = ref.watch(appStateInfoProvider);
  return appState.maybeWhen(
    data: (state) => state.isOffline,
    orElse: () => false,
  );
});

final syncQueueProcessorProvider = Provider<SyncQueueConnectivityProcessor>((ref) {
  final appState = ref.watch(appStateManagerProvider);
  final logger = ref.watch(loggerProvider);
  final syncQueueService = ref.watch(syncQueueServiceProvider);
  final processor = SyncQueueConnectivityProcessor(appState, logger, syncQueueService);
  ref.onDispose(processor.dispose);
  return processor;
});

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final logger = ref.watch(loggerProvider);
  final storage = ref.watch(storageGatewayProvider);
  return SyncQueueService(storage, logger);
});

final stateAwareServiceProvider = Provider<StateAwareService>((ref) {
  return StateAwareService(
    appState: ref.watch(appStateManagerProvider),
    storage: ref.watch(storageGatewayProvider),
    logger: ref.watch(loggerProvider),
  );
});

class SyncQueueConnectivityProcessor {
  final logic.AppStateManager _appStateManager;
  final LoggerService _logger;
  final SyncQueueService _syncQueueService;
  StreamSubscription<logic.AppStateInfo>? _subscription;
  StreamSubscription<logic.StorageInfo>? _storageSubscription;

  SyncQueueConnectivityProcessor(this._appStateManager, this._logger, this._syncQueueService) {
    _subscription = _appStateManager.stateStream.listen((state) {
      if (state.isOnline) {
        _logger.info('[SyncQueue] connectivity restored; queued operations can sync now');
        _syncQueueService.processQueue((item) async {
          _logger.debug('[SyncQueue] auto-processed item=${item.id} operation=${item.operation}');
          return const Success(null);
        });
      }
    });

    _storageSubscription = _appStateManager.storageStream.listen((info) {
      if (info.usagePercentage >= 90) {
        _logger.warning('[Storage] low storage warning usage=${info.usagePercentage.toStringAsFixed(1)}%');
      } else {
        _logger.debug('[Storage] usage=${info.usagePercentage.toStringAsFixed(1)}%');
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _storageSubscription?.cancel();
  }
}
