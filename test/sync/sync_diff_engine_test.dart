// test/sync/sync_diff_engine_test.dart — verifies newest-wins, skip, tombstone and conflict decisions of SyncDiffEngine.

import 'package:abdalsalam/data/models/sync/sync_row_stamp.dart';
import 'package:abdalsalam/features/sync/services/sync_diff_engine.dart';
import 'package:abdalsalam/features/sync/services/sync_row_comparison.dart';
import 'package:flutter_test/flutter_test.dart';

SyncRowStamp stamp(String updatedAt, {bool isDeleted = false}) =>
    SyncRowStamp(updatedAt: updatedAt, isDeleted: isDeleted);

void main() {
  const engine = SyncDiffEngine();
  const older = '2026-03-01T10:00:00.000';
  const newer = '2026-03-02T10:00:00.000';

  group('SyncDiffEngine.compare', () {
    test('should send local rows that are newer and receive remote rows that are newer', () {
      final local = {'a': stamp(newer), 'b': stamp(older)};
      final remote = {'a': stamp(older), 'b': stamp(newer)};

      final diff = engine.compare(local: local, remote: remote);

      expect(diff.idsToSend, ['a']);
      expect(diff.idsToReceive, ['b']);
      expect(diff.conflictCount, 2);
      expect(diff.skippedCount, 0);
    });

    test('should skip rows with equal stamps and count them as skipped', () {
      final diff = engine.compare(local: {'a': stamp(older)}, remote: {'a': stamp(older)});

      expect(diff.idsToSend, isEmpty);
      expect(diff.idsToReceive, isEmpty);
      expect(diff.skippedCount, 1);
      expect(diff.conflictCount, 0);
    });

    test('should send rows missing remotely and receive rows missing locally', () {
      final diff = engine.compare(local: {'only-local': stamp(older)}, remote: {'only-remote': stamp(newer)});

      expect(diff.idsToSend, ['only-local']);
      expect(diff.idsToReceive, ['only-remote']);
      expect(diff.conflictCount, 0);
    });

    test('should propagate a newer tombstone to the side that still has the live row', () {
      final diff = engine.compare(local: {'a': stamp(newer, isDeleted: true)}, remote: {'a': stamp(older)});

      expect(diff.idsToSend, ['a']);
    });

    test('should let a newer live row win over an older tombstone', () {
      final diff = engine.compare(local: {'a': stamp(older, isDeleted: true)}, remote: {'a': stamp(newer)});

      expect(diff.idsToReceive, ['a']);
    });

    test('should let the tombstone win when stamps are equal but only one side is deleted', () {
      final diff = engine.compare(local: {'a': stamp(older)}, remote: {'a': stamp(older, isDeleted: true)});

      expect(diff.idsToReceive, ['a']);
      expect(diff.conflictCount, 1);
    });
  });

  group('SyncDiffEngine.compareStamps', () {
    test('should treat a row with an unreadable timestamp as older than one with a readable timestamp', () {
      expect(engine.compareStamps(stamp(''), stamp(older)), SyncRowComparison.remoteNewer);
      expect(engine.compareStamps(stamp(older), stamp('')), SyncRowComparison.localNewer);
    });

    test('should treat different strings that parse to the same instant as the same row', () {
      expect(
        engine.compareStamps(stamp('2026-03-01T10:00:00.000Z'), stamp('2026-03-01T10:00:00Z')),
        SyncRowComparison.same,
      );
    });
  });

  group('SyncDiffEngine.shouldApplyIncoming', () {
    test('should apply an incoming row when there is no local copy', () {
      expect(engine.shouldApplyIncoming(local: null, incoming: stamp(older)), isTrue);
    });

    test('should not apply an incoming row that is older or equal', () {
      expect(engine.shouldApplyIncoming(local: stamp(newer), incoming: stamp(older)), isFalse);
      expect(engine.shouldApplyIncoming(local: stamp(older), incoming: stamp(older)), isFalse);
    });

    test('should apply an incoming row that is newer', () {
      expect(engine.shouldApplyIncoming(local: stamp(older), incoming: stamp(newer)), isTrue);
    });
  });
}
