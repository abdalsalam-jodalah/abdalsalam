import 'package:abdalsalam/features/dashboard/services/life_age.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final birthDate = DateTime(2002, 10, 1, 16);

  group('LifeAge.between', () {
    test('should be zero everywhere at the moment of birth', () {
      final age = LifeAge.between(birthDate, birthDate);

      expect([age.years, age.days, age.hours, age.minutes], [0, 0, 0, 0]);
      expect([age.totalDays, age.totalHours, age.totalMinutes], [0, 0, 0]);
    });

    test('should break the age into years, days, hours and minutes since the last birthday', () {
      final age = LifeAge.between(birthDate, DateTime(2026, 10, 6, 18, 45));

      expect(age.years, 24);
      expect(age.days, 5);
      expect(age.hours, 2);
      expect(age.minutes, 45);
    });

    test('should not count the new year before the birthday hour on the birthday', () {
      final beforeBirthHour = LifeAge.between(birthDate, DateTime(2026, 10, 1, 15, 59));
      final atBirthHour = LifeAge.between(birthDate, DateTime(2026, 10, 1, 16));

      expect(beforeBirthHour.years, 23);
      expect(beforeBirthHour.days, 364);
      expect(beforeBirthHour.hours, 23);
      expect(beforeBirthHour.minutes, 59);
      expect([atBirthHour.years, atBirthHour.days, atBirthHour.hours, atBirthHour.minutes], [24, 0, 0, 0]);
    });

    test('should total days, hours and minutes lived', () {
      final age = LifeAge.between(birthDate, DateTime(2002, 10, 3, 18, 30));

      expect(age.totalDays, 2);
      expect(age.totalHours, 50);
      expect(age.totalMinutes, 50 * 60 + 30);
    });

    test('should count leap days in the total days lived', () {
      final age = LifeAge.between(birthDate, DateTime(2004, 10, 1, 16));

      expect(age.totalDays, 731);
      expect(age.years, 2);
    });
  });
}
