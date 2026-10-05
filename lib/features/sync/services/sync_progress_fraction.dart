// lib/features/sync/services/sync_progress_fraction.dart — maps a sync phase to an approximate overall progress fraction.

import '../../../data/models/sync/sync_phase.dart';

class SyncProgressFraction {
  static const Map<SyncPhase, double> _fractionByPhase = <SyncPhase, double>{
    SyncPhase.idle: 0,
    SyncPhase.waiting: 0,
    SyncPhase.connecting: 0.1,
    SyncPhase.comparing: 0.25,
    SyncPhase.sending: 0.45,
    SyncPhase.receiving: 0.65,
    SyncPhase.backingUp: 0.75,
    SyncPhase.applying: 0.85,
    SyncPhase.finalizing: 0.95,
    SyncPhase.completed: 1,
    SyncPhase.failed: 0,
  };

  const SyncProgressFraction._();

  static double of(SyncPhase phase) => _fractionByPhase[phase] ?? 0;
}
