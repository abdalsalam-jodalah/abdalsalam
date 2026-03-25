import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../infrastructure/logger_service.dart';
import '../infrastructure/storage_gateway.dart';

enum SyncPolicy { wifiOnly, wifiOrCellular }

class StateAwareSettings {
  final bool forceSync;
  final bool disableBatteryOptimization;
  final SyncPolicy syncPolicy;

  const StateAwareSettings({
    this.forceSync = false,
    this.disableBatteryOptimization = false,
    this.syncPolicy = SyncPolicy.wifiOnly,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'forceSync': forceSync,
        'disableBatteryOptimization': disableBatteryOptimization,
        'syncPolicy': syncPolicy.name,
      };

  factory StateAwareSettings.fromJson(Map<String, dynamic> json) {
    final policy = (json['syncPolicy'] as String?) ?? SyncPolicy.wifiOnly.name;
    return StateAwareSettings(
      forceSync: json['forceSync'] == true,
      disableBatteryOptimization: json['disableBatteryOptimization'] == true,
      syncPolicy: SyncPolicy.values.firstWhere(
        (item) => item.name == policy,
        orElse: () => SyncPolicy.wifiOnly,
      ),
    );
  }
}

class StateAwareService {
  static const _settingsKey = 'state_aware_settings';

  final AppStateManager appState;
  final StorageGateway storage;
  final LoggerService logger;

  const StateAwareService({
    required this.appState,
    required this.storage,
    required this.logger,
  });

  Future<StateAwareSettings> getSettings() async {
    final raw = await storage.get<Map<String, dynamic>>(_settingsKey);
    if (raw == null) {
      return const StateAwareSettings();
    }
    return StateAwareSettings.fromJson(raw);
  }

  Future<void> saveSettings(StateAwareSettings settings) async {
    await storage.save(key: _settingsKey, value: settings.toJson());
    logger.info('[StateAwareService] settings persisted');
  }

  Result<void, AppError> canRunNonCriticalOperation({
    required StateAwareSettings settings,
  }) {
    final battery = appState.batteryInfo;
    if (settings.disableBatteryOptimization || settings.forceSync) {
      return const Success(null);
    }

    if (battery?.isLowBattery == true) {
      logger.warning('[StateAwareService] deferred non-critical operation at low battery');
      return Failure(ServiceError('Deferred: battery below 20%'));
    }

    return const Success(null);
  }

  Result<void, AppError> canAutoSync({
    required StateAwareSettings settings,
  }) {
    if (settings.forceSync) {
      return const Success(null);
    }

    final battery = appState.batteryInfo;
    if (!settings.disableBatteryOptimization && battery?.isCriticalBattery == true) {
      logger.warning('[StateAwareService] auto-sync disabled due to critical battery');
      return Failure(ServiceError('Auto-sync disabled at battery below 10%'));
    }

    final network = appState.networkInfo;
    if (network == null || !network.isOnline) {
      return Failure(NetworkError('Cannot sync while offline'));
    }

    if (settings.syncPolicy == SyncPolicy.wifiOnly && !network.isWifi) {
      return Failure(ServiceError('Cellular connection requires user confirmation'));
    }

    return const Success(null);
  }

  bool isStorageLow() {
    final storageInfo = appState.storageInfo;
    return storageInfo.usagePercentage >= 90;
  }

  bool shouldPromptLargeSyncOnCellular({required StateAwareSettings settings}) {
    if (settings.forceSync || settings.syncPolicy == SyncPolicy.wifiOrCellular) {
      return false;
    }
    final network = appState.networkInfo;
    return network != null && network.isMobile;
  }

  bool shouldAutoSyncOnWifi({required StateAwareSettings settings}) {
    final network = appState.networkInfo;
    if (network == null || !network.isWifi) {
      return false;
    }

    final decision = canAutoSync(settings: settings);
    return decision.isSuccess;
  }

  String? storageWarningMessage() {
    if (!isStorageLow()) {
      return null;
    }
    return 'Storage is running low. Consider exporting and cleaning old logs.';
  }

  List<String> cleanupSuggestions() {
    return const <String>[
      'Export old records and archive them externally.',
      'Delete soft-deleted entries you no longer need.',
      'Clear large temporary exports from local storage.',
    ];
  }
}
