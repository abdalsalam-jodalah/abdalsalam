// test/sync/sync_display_formatter_test.dart — verifies progress fractions and display formatting for sync screens.

import 'package:abdalsalam/data/models/sync/sync_phase.dart';
import 'package:abdalsalam/features/sync/services/sync_display_formatter.dart';
import 'package:abdalsalam/features/sync/services/sync_progress_fraction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncProgressFraction', () {
    test('should never decrease across the phases of a successful session', () {
      const order = [
        SyncPhase.waiting,
        SyncPhase.connecting,
        SyncPhase.comparing,
        SyncPhase.sending,
        SyncPhase.receiving,
        SyncPhase.backingUp,
        SyncPhase.applying,
        SyncPhase.finalizing,
        SyncPhase.completed,
      ];

      final fractions = order.map(SyncProgressFraction.of).toList();

      expect(fractions, orderedEquals([...fractions]..sort()));
      expect(fractions.last, 1);
    });

    test('should be zero when the session failed', () {
      expect(SyncProgressFraction.of(SyncPhase.failed), 0);
    });
  });

  group('SyncDisplayFormatter', () {
    test('should format bytes with the right unit', () {
      expect(SyncDisplayFormatter.bytes(512), '512 B');
      expect(SyncDisplayFormatter.bytes(2048), '2.0 KB');
      expect(SyncDisplayFormatter.bytes(5 * 1024 * 1024), '5.0 MB');
      expect(SyncDisplayFormatter.bytes(20 * 1024 * 1024), '20 MB');
    });

    test('should format durations in ms, seconds and minutes', () {
      expect(SyncDisplayFormatter.duration(const Duration(milliseconds: 250)), '250 ms');
      expect(SyncDisplayFormatter.duration(const Duration(seconds: 5)), '5 s');
      expect(SyncDisplayFormatter.duration(const Duration(seconds: 125)), '2 min 5 s');
    });

    test('should resolve module labels from the registry and fall back to Other', () {
      expect(SyncDisplayFormatter.moduleLabel('notes'), 'Notes');
      expect(SyncDisplayFormatter.moduleLabel('other'), 'Other');
    });
  });
}
