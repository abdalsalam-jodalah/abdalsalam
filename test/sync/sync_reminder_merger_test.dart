// test/sync/sync_reminder_merger_test.dart — verifies reminder lists are unioned and local entries win on clashes.

import 'package:abdalsalam/features/sync/services/sync_reminder_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const merger = SyncReminderMerger();

  Map<String, dynamic> reminder(String targetId, {String title = 'title'}) => {
    'module': 'health',
    'targetId': targetId,
    'title': title,
    'scheduledAt': '2026-10-06T09:00:00.000',
  };

  test('should add incoming reminders that the local list does not have', () {
    final result = merger.merge(local: [reminder('a')], incoming: [reminder('b')]);

    expect(result.addedCount, 1);
    expect(result.reminders.map((item) => item['targetId']), ['a', 'b']);
  });

  test('should keep the local entry when the same reminder exists on both sides', () {
    final result = merger.merge(
      local: [reminder('a', title: 'local')],
      incoming: [reminder('a', title: 'remote')],
    );

    expect(result.addedCount, 0);
    expect(result.reminders.single['title'], 'local');
  });

  test('should ignore duplicate reminders inside the incoming list', () {
    final result = merger.merge(local: const [], incoming: [reminder('a'), reminder('a')]);

    expect(result.addedCount, 1);
  });

  test('should normalize stored values and drop non-map entries', () {
    expect(merger.normalize(null), isEmpty);
    expect(merger.normalize([reminder('a'), 'junk', 4]), [reminder('a')]);
  });
}
