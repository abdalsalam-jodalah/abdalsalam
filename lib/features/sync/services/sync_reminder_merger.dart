// lib/features/sync/services/sync_reminder_merger.dart — unions two scheduled-reminder lists, keeping the local entry on identity clashes.

typedef SyncReminderMergeResult = ({List<Map<String, dynamic>> reminders, int addedCount});

class SyncReminderMerger {
  const SyncReminderMerger();

  List<Map<String, dynamic>> normalize(List<dynamic>? stored) {
    if (stored == null) {
      return const <Map<String, dynamic>>[];
    }
    return <Map<String, dynamic>>[
      for (final item in stored)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  String identityOf(Map<String, dynamic> reminder) {
    return '${reminder['module']}|${reminder['targetId']}|${reminder['scheduledAt']}';
  }

  SyncReminderMergeResult merge({
    required List<Map<String, dynamic>> local,
    required List<Map<String, dynamic>> incoming,
  }) {
    final knownIdentities = local.map(identityOf).toSet();
    final merged = <Map<String, dynamic>>[...local];
    var addedCount = 0;
    for (final reminder in incoming) {
      if (knownIdentities.add(identityOf(reminder))) {
        merged.add(reminder);
        addedCount++;
      }
    }
    return (reminders: merged, addedCount: addedCount);
  }
}
