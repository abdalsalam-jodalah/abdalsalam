// lib/features/sync/providers/sync_host_controller.dart — orchestrates the Mac flow: host, open the adb tunnel, track progress.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../data/models/sync/sync_phase.dart';
import '../../../data/models/sync/sync_progress_event.dart';
import '../../../data/models/sync/sync_session_report.dart';
import '../services/adb_status.dart';
import 'sync_host_state.dart';
import 'sync_link_state.dart';
import 'sync_providers.dart';

class SyncHostController extends Notifier<SyncHostState> {
  StreamSubscription<SyncProgressEvent>? _progressSubscription;
  StreamSubscription<SyncSessionReport>? _reportSubscription;

  @override
  SyncHostState build() {
    final session = ref.watch(syncSessionServiceProvider);
    _progressSubscription = session.progress.listen(_onProgress);
    _reportSubscription = session.completedReports.listen(_onReport);
    ref.onDispose(() {
      unawaited(_progressSubscription?.cancel());
      unawaited(_reportSubscription?.cancel());
    });
    return const SyncHostState();
  }

  Future<void> refreshAdbStatus() async {
    state = state.copyWith(isCheckingAdb: true);
    final status = await ref.read(adbServiceProvider).checkStatus();
    state = state.copyWith(adbStatus: status, isCheckingAdb: false);
  }

  Future<AppError?> startLink() async {
    if (state.isLinkOpen || state.linkState == SyncLinkState.starting) {
      return null;
    }
    state = state.copyWith(linkState: SyncLinkState.starting);
    final hosting = await ref.read(syncSessionServiceProvider).startHosting();
    if (hosting.isFailure) {
      state = state.copyWith(linkState: SyncLinkState.stopped);
      return hosting.error;
    }
    state = state.copyWith(hostInfo: hosting.data, linkState: SyncLinkState.waiting);
    await openTunnel();
    return null;
  }

  Future<void> openTunnel() async {
    final info = state.hostInfo;
    if (info == null) {
      return;
    }
    final status = await _checkStatus();
    if (!status.isReady) {
      state = state.copyWith(isReverseActive: false, clearReverseFailure: true);
      return;
    }
    final result = await ref
        .read(adbServiceProvider)
        .reverse(info.port, adbPath: status.adbPath!, serial: status.deviceSerial);
    state = state.copyWith(
      isReverseActive: result.isSuccess,
      reverseFailure: result.error?.message,
      clearReverseFailure: result.isSuccess,
    );
  }

  Future<void> stopLink() async {
    final info = state.hostInfo;
    final status = state.adbStatus;
    final wasTunnelOpen = state.isReverseActive;
    await ref.read(syncSessionServiceProvider).stopHosting();
    state = SyncHostState(adbStatus: status, lastReport: state.lastReport);
    if (info != null && wasTunnelOpen && status != null && status.isReady) {
      await ref
          .read(adbServiceProvider)
          .removeReverse(info.port, adbPath: status.adbPath!, serial: status.deviceSerial);
    }
  }

  Future<AdbStatus> _checkStatus() async {
    state = state.copyWith(isCheckingAdb: true);
    final status = await ref.read(adbServiceProvider).checkStatus();
    state = state.copyWith(adbStatus: status, isCheckingAdb: false);
    return status;
  }

  void _onProgress(SyncProgressEvent event) {
    if (!state.isLinkOpen) {
      return;
    }
    state = state.copyWith(progress: event, linkState: _linkStateFor(event.phase));
  }

  void _onReport(SyncSessionReport report) {
    state = state.copyWith(lastReport: report, linkState: SyncLinkState.completed);
  }

  SyncLinkState _linkStateFor(SyncPhase phase) {
    return switch (phase) {
      SyncPhase.idle || SyncPhase.waiting => SyncLinkState.waiting,
      SyncPhase.completed => SyncLinkState.completed,
      SyncPhase.failed => SyncLinkState.failed,
      _ => SyncLinkState.syncing,
    };
  }
}
