// test/sync/sync_row_applier_test.dart — verifies SyncRowApplier counts, filters stale rows and restores attachments.

import 'dart:typed_data';

import 'package:abdalsalam/data/models/sync/sync_row_bundle.dart';
import 'package:abdalsalam/features/sync/services/sync_row_applier.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_sync_data_store.dart';
import 'support/sync_row_factory.dart';

void main() {
  const older = '2026-03-01T10:00:00.000';
  const newer = '2026-03-02T10:00:00.000';
  const table = 'notes';

  test('should add, update and delete newer rows and report each count', () async {
    final store = FakeSyncDataStore(
      rows: {
        table: [syncRow('update-me', updatedAt: older), syncRow('delete-me', updatedAt: older)],
      },
    );
    final applier = SyncRowApplier(store);
    final incoming = SyncRowBundle(
      rows: [
        syncRow('new-row', updatedAt: newer),
        syncRow('update-me', updatedAt: newer, title: 'changed'),
        syncRow('delete-me', updatedAt: newer, deletedAt: newer),
      ],
    );

    final outcomes = await applier.apply({
      table: [incoming],
    });

    expect(outcomes[table]!.added, 1);
    expect(outcomes[table]!.updated, 1);
    expect(outcomes[table]!.deleted, 1);
    expect(outcomes[table]!.skipped, 0);
    expect(store.rowsOf(table)['update-me']!['title'], 'changed');
    expect(store.rowsOf(table)['delete-me']!['deletedAt'], newer);
  });

  test('should skip incoming rows that are older or equal to the local copy', () async {
    final store = FakeSyncDataStore(
      rows: {
        table: [syncRow('a', updatedAt: newer, title: 'local'), syncRow('b', updatedAt: newer, title: 'local')],
      },
    );
    final applier = SyncRowApplier(store);
    final incoming = SyncRowBundle(
      rows: [
        syncRow('a', updatedAt: older, title: 'stale'),
        syncRow('b', updatedAt: newer, title: 'same'),
      ],
    );

    final outcomes = await applier.apply({
      table: [incoming],
    });

    expect(outcomes[table]!.skipped, 2);
    expect(store.rowsOf(table)['a']!['title'], 'local');
    expect(store.rowsOf(table)['b']!['title'], 'local');
  });

  test('should write all tables in a single store call', () async {
    final store = FakeSyncDataStore();
    final applier = SyncRowApplier(store);

    await applier.apply({
      'notes': [
        SyncRowBundle(rows: [syncRow('n', updatedAt: newer)]),
      ],
      'todos': [
        SyncRowBundle(rows: [syncRow('t', updatedAt: newer)]),
      ],
    });

    expect(store.appliedBatches, hasLength(1));
    expect(store.appliedBatches.single.keys, containsAll(['notes', 'todos']));
  });

  test('should restore attachments only for rows that are applied', () async {
    final store = FakeSyncDataStore(
      rows: {
        'food_logs': [syncRow('kept', updatedAt: newer)],
      },
      attachmentTables: {'food_logs'},
    );
    final applier = SyncRowApplier(store);
    final incoming = SyncRowBundle(
      rows: [
        syncRow(
          'kept',
          updatedAt: older,
          extra: {FakeSyncDataStore.attachmentField: 'attachments/food_logs/stale.jpg'},
        ),
        syncRow(
          'fresh',
          updatedAt: newer,
          extra: {FakeSyncDataStore.attachmentField: 'attachments/food_logs/fresh.jpg'},
        ),
      ],
      attachments: {
        'attachments/food_logs/stale.jpg': Uint8List.fromList([1]),
        'attachments/food_logs/fresh.jpg': Uint8List.fromList([2]),
      },
    );

    await applier.apply({
      'food_logs': [incoming],
    });

    expect(store.files.keys, ['local/fresh.jpg']);
    expect(store.rowsOf('food_logs')['fresh']![FakeSyncDataStore.attachmentField], 'local/fresh.jpg');
  });
}
