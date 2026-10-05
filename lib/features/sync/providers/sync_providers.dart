// lib/features/sync/providers/sync_providers.dart — Riverpod wiring for USB device sync services and controllers.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/sync/sync_session_report.dart';
import '../../../providers/app_providers.dart';
import '../services/adb_locator.dart';
import '../services/adb_service.dart';
import '../services/backup_service_safety_backup.dart';
import '../services/process_runner.dart';
import '../services/storage_sync_data_store.dart';
import '../services/sync_client.dart';
import '../services/sync_data_store.dart';
import '../services/sync_history_store.dart';
import '../services/sync_pairing_service.dart';
import '../services/sync_platform_role.dart';
import '../services/sync_safety_backup.dart';
import '../services/sync_server.dart';
import '../services/sync_session_service.dart';
import '../services/system_process_runner.dart';
import 'sync_host_controller.dart';
import 'sync_host_state.dart';
import 'sync_join_controller.dart';
import 'sync_join_state.dart';

final syncPlatformRoleProvider = Provider<SyncPlatformRole>((ref) => SyncPlatformRole.detect());

final syncDataStoreProvider = Provider<SyncDataStore>((ref) {
  return StorageSyncDataStore(
    storage: ref.watch(storageGatewayProvider),
    attachmentBundler: ref.watch(backupAttachmentBundlerProvider),
  );
});

final syncSafetyBackupProvider = Provider<SyncSafetyBackup>((ref) {
  return BackupServiceSafetyBackup(ref.watch(backupServiceProvider));
});

final syncPairingServiceProvider = Provider<SyncPairingService>((ref) => SyncPairingService());

final syncHistoryStoreProvider = Provider<SyncHistoryStore>((ref) {
  return SyncHistoryStore(ref.watch(storageGatewayProvider));
});

final syncServerProvider = Provider<SyncServer>((ref) {
  return SyncServer(
    store: ref.watch(syncDataStoreProvider),
    pairing: ref.watch(syncPairingServiceProvider),
    safetyBackup: ref.watch(syncSafetyBackupProvider),
    logger: ref.watch(loggerProvider),
    deviceLabel: ref.watch(syncPlatformRoleProvider).deviceLabel,
  );
});

final syncClientProvider = Provider<SyncClient>((ref) {
  return SyncClient(
    store: ref.watch(syncDataStoreProvider),
    safetyBackup: ref.watch(syncSafetyBackupProvider),
    logger: ref.watch(loggerProvider),
    deviceLabel: ref.watch(syncPlatformRoleProvider).deviceLabel,
  );
});

final syncSessionServiceProvider = Provider<SyncSessionService>((ref) {
  final service = SyncSessionService(
    server: ref.watch(syncServerProvider),
    client: ref.watch(syncClientProvider),
    history: ref.watch(syncHistoryStoreProvider),
    logger: ref.watch(loggerProvider),
    onDataChanged: () async {
      await ref.read(reminderServiceProvider).rescheduleAll();
      ref.invalidate(syncHistoryProvider);
      ref.invalidate(recordCountsByModuleProvider);
    },
  );
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final syncHistoryProvider = FutureProvider.autoDispose<List<SyncSessionReport>>((ref) {
  return ref.watch(syncHistoryStoreProvider).readAll();
});

final processRunnerProvider = Provider<ProcessRunner>((ref) => const SystemProcessRunner());

final adbLocatorProvider = Provider<AdbLocator>((ref) => AdbLocator(runner: ref.watch(processRunnerProvider)));

final adbServiceProvider = Provider<AdbService>((ref) {
  return AdbService(
    runner: ref.watch(processRunnerProvider),
    locator: ref.watch(adbLocatorProvider),
    logger: ref.watch(loggerProvider),
  );
});

final syncHostControllerProvider = NotifierProvider<SyncHostController, SyncHostState>(SyncHostController.new);

final syncJoinControllerProvider = NotifierProvider<SyncJoinController, SyncJoinState>(SyncJoinController.new);
