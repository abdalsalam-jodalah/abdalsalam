// lib/features/sync/providers/sync_join_state.dart — immutable state of the phone-side sync run.

import '../../../data/models/sync/sync_progress_event.dart';
import '../../../data/models/sync/sync_session_report.dart';

class SyncJoinState {
  final bool isJoining;
  final SyncProgressEvent? progress;
  final SyncSessionReport? lastReport;

  const SyncJoinState({this.isJoining = false, this.progress, this.lastReport});

  SyncJoinState copyWith({
    bool? isJoining,
    SyncProgressEvent? progress,
    SyncSessionReport? lastReport,
    bool clearProgress = false,
  }) {
    return SyncJoinState(
      isJoining: isJoining ?? this.isJoining,
      progress: clearProgress ? null : progress ?? this.progress,
      lastReport: lastReport ?? this.lastReport,
    );
  }
}
