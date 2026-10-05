// lib/data/models/sync/sync_phase.dart — the stages a device sync session moves through.

enum SyncPhase {
  idle,
  waiting,
  connecting,
  comparing,
  sending,
  receiving,
  backingUp,
  applying,
  finalizing,
  completed,
  failed,
}
