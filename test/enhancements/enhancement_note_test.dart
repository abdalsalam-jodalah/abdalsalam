import 'package:abdalsalam/data/models/enhancements/enhancement_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 10, 1, 9);

  EnhancementNote buildNote({String? details, bool isDone = false, DateTime? completedAt}) {
    return EnhancementNote(
      id: 'n1',
      createdAt: createdAt,
      updatedAt: createdAt,
      userId: 'user1',
      title: 'Make the sidebar smoother',
      details: details,
      priority: EnhancementPriority.high,
      isDone: isDone,
      completedAt: completedAt,
    );
  }

  group('EnhancementNote', () {
    test('should survive a JSON round trip', () {
      final note = buildNote(details: 'Animate closing', isDone: true, completedAt: DateTime(2026, 10, 2));

      final restored = EnhancementNote.fromJson(note.toJson());

      expect(restored.title, note.title);
      expect(restored.details, 'Animate closing');
      expect(restored.priority, EnhancementPriority.high);
      expect(restored.isDone, isTrue);
      expect(restored.completedAt, DateTime(2026, 10, 2));
      expect(restored.createdAt, createdAt);
    });

    test('should fall back to medium priority and not done when those fields are missing or unknown', () {
      final json = buildNote().toJson()
        ..remove('isDone')
        ..['priority'] = 'urgent';

      final restored = EnhancementNote.fromJson(json);

      expect(restored.priority, EnhancementPriority.medium);
      expect(restored.isDone, isFalse);
    });

    test('should clear details and completion time only when asked', () {
      final note = buildNote(details: 'keep', isDone: true, completedAt: DateTime(2026, 10, 2));

      expect(note.copyWith(title: 'new').details, 'keep');
      expect(note.copyWith(clearDetails: true).details, isNull);
      expect(note.copyWith(title: 'new').completedAt, DateTime(2026, 10, 2));
      expect(note.copyWith(clearCompletedAt: true).completedAt, isNull);
    });
  });
}
