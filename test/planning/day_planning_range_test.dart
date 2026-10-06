import 'package:abdalsalam/features/planning/services/day_planning_range.dart';
import 'package:abdalsalam/features/planning/services/day_planning_view_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DayPlanningRange.of', () {
    test('should cover a single day in day mode', () {
      final range = DayPlanningRange.of(DayPlanningViewMode.day, DateTime(2026, 3, 11, 15));

      expect(range.start, DateTime(2026, 3, 11));
      expect(range.end, DateTime(2026, 3, 11));
      expect(range.dayCount, 1);
    });

    test('should span the week from the configured first day', () {
      final monday = DayPlanningRange.of(DayPlanningViewMode.week, DateTime(2026, 3, 11), weekStartDay: DateTime.monday);
      final saturday = DayPlanningRange.of(DayPlanningViewMode.week, DateTime(2026, 3, 11));
      final sunday = DayPlanningRange.of(DayPlanningViewMode.week, DateTime(2026, 3, 8), weekStartDay: DateTime.sunday);

      expect([monday.start, monday.end], [DateTime(2026, 3, 9), DateTime(2026, 3, 15)]);
      expect([saturday.start, saturday.end], [DateTime(2026, 3, 7), DateTime(2026, 3, 13)]);
      expect([sunday.start, sunday.end], [DateTime(2026, 3, 8), DateTime(2026, 3, 14)]);
      expect(monday.dayCount, 7);
    });

    test('should map the first day of week setting to a weekday', () {
      expect(DayPlanningRange.weekStartDayFromSetting('saturday'), DateTime.saturday);
      expect(DayPlanningRange.weekStartDayFromSetting('sunday'), DateTime.sunday);
      expect(DayPlanningRange.weekStartDayFromSetting('monday'), DateTime.monday);
      expect(DayPlanningRange.weekStartDayFromSetting(null), DateTime.saturday);
    });

    test('should span the whole calendar month in month mode', () {
      final range = DayPlanningRange.of(DayPlanningViewMode.month, DateTime(2028, 2, 10));

      expect(range.start, DateTime(2028, 2, 1));
      expect(range.end, DateTime(2028, 2, 29));
      expect(range.dayCount, 29);
    });

    test('should span the requested number of days in custom mode', () {
      final range = DayPlanningRange.of(DayPlanningViewMode.custom, DateTime(2026, 12, 30), customDays: 5);

      expect(range.end, DateTime(2027, 1, 3));
      expect(range.days.length, 5);
    });

    test('should clamp a custom day count to the allowed bounds', () {
      expect(DayPlanningRange.of(DayPlanningViewMode.custom, DateTime(2026), customDays: 0).dayCount, 1);
      expect(
        DayPlanningRange.of(DayPlanningViewMode.custom, DateTime(2026), customDays: 9999).dayCount,
        DayPlanningRange.maxCustomDays,
      );
    });
  });

  group('DayPlanningRange.shiftAnchor', () {
    test('should move by whole periods for each mode', () {
      final anchor = DateTime(2026, 3, 11);

      expect(DayPlanningRange.shiftAnchor(DayPlanningViewMode.day, anchor, 1), DateTime(2026, 3, 12));
      expect(DayPlanningRange.shiftAnchor(DayPlanningViewMode.week, anchor, -1), DateTime(2026, 3, 4));
      expect(DayPlanningRange.shiftAnchor(DayPlanningViewMode.month, anchor, 1), DateTime(2026, 4, 1));
      expect(DayPlanningRange.shiftAnchor(DayPlanningViewMode.month, anchor, -3), DateTime(2025, 12, 1));
      expect(DayPlanningRange.shiftAnchor(DayPlanningViewMode.custom, anchor, 2, customDays: 4), DateTime(2026, 3, 19));
    });
  });
}
