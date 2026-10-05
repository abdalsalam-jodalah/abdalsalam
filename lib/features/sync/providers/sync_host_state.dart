// lib/features/sync/providers/sync_host_state.dart — immutable state of the Mac-side sync link and its adb tunnel.

import '../../../data/models/sync/sync_progress_event.dart';
import '../../../data/models/sync/sync_session_report.dart';
import '../services/adb_reverse_command.dart';
import '../services/adb_status.dart';
import '../services/sync_host_info.dart';
import 'sync_link_state.dart';

class SyncHostState {
  final AdbStatus? adbStatus;
  final bool isCheckingAdb;
  final SyncHostInfo? hostInfo;
  final SyncLinkState linkState;
  final SyncProgressEvent? progress;
  final SyncSessionReport? lastReport;
  final bool isReverseActive;
  final String? reverseFailure;

  const SyncHostState({
    this.adbStatus,
    this.isCheckingAdb = false,
    this.hostInfo,
    this.linkState = SyncLinkState.stopped,
    this.progress,
    this.lastReport,
    this.isReverseActive = false,
    this.reverseFailure,
  });

  bool get isLinkOpen => hostInfo != null;

  bool get needsManualCommand {
    final status = adbStatus;
    final isAdbUnusable = status != null && !status.isAdbAvailable;
    return isLinkOpen && !isReverseActive && (reverseFailure != null || isAdbUnusable);
  }

  String? get manualCommand {
    final info = hostInfo;
    if (info == null || !needsManualCommand) {
      return null;
    }
    return AdbReverseCommand.manualText(info.port);
  }

  SyncHostState copyWith({
    AdbStatus? adbStatus,
    bool? isCheckingAdb,
    SyncHostInfo? hostInfo,
    SyncLinkState? linkState,
    SyncProgressEvent? progress,
    SyncSessionReport? lastReport,
    bool? isReverseActive,
    String? reverseFailure,
    bool clearReverseFailure = false,
  }) {
    return SyncHostState(
      adbStatus: adbStatus ?? this.adbStatus,
      isCheckingAdb: isCheckingAdb ?? this.isCheckingAdb,
      hostInfo: hostInfo ?? this.hostInfo,
      linkState: linkState ?? this.linkState,
      progress: progress ?? this.progress,
      lastReport: lastReport ?? this.lastReport,
      isReverseActive: isReverseActive ?? this.isReverseActive,
      reverseFailure: clearReverseFailure ? null : reverseFailure ?? this.reverseFailure,
    );
  }
}
