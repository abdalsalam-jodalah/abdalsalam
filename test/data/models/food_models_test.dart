import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/food/food_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 3, 1, 8);
  final createdAtText = createdAt.toIso8601String();

  Matcher throwsCorruptField(String field) =>
      throwsA(isA<CorruptDataError>().having((error) => error.field, 'field', field));

  group('FoodLog.fromJson', () {
    final foodLog = FoodLog(
      id: 'food-1',
      createdAt: createdAt,
      updatedAt: DateTime(2026, 3, 1, 9),
      userId: 'user',
      category: 'Breakfast',
      dishName: 'Oats',
      quantity: '1 bowl',
      imagePath: '/tmp/oats.jpg',
      components: 'oats, milk',
      description: 'warm',
      loggedAt: DateTime(2026, 3, 1, 7, 30),
      calories: 350,
      proteinGrams: 12.5,
      fatGrams: 6,
      carbGrams: 55,
    );

    test('should keep every field when round tripping valid json', () {
      final parsed = FoodLog.fromJson(foodLog.toJson());

      expect(parsed.toJson(), foodLog.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final parsed = FoodLog.fromJson({'id': 'food-1', 'createdAt': createdAtText});

      expect(parsed.updatedAt, createdAt);
      expect(parsed.category, '');
      expect(parsed.dishName, '');
      expect(parsed.quantity, '');
      expect(parsed.loggedAt, createdAt);
      expect(parsed.calories, isNull);
    });

    test('should tolerate wrong types when numbers are stored as text or ints', () {
      final parsed = FoodLog.fromJson({
        'id': 'food-1',
        'createdAt': createdAtText,
        'calories': '350.5',
        'proteinGrams': 12,
        'quantity': 2,
      });

      expect(parsed.calories, 350.5);
      expect(parsed.proteinGrams, 12.0);
      expect(parsed.quantity, '2');
    });

    test('should fall back to createdAt when loggedAt is malformed', () {
      final parsed = FoodLog.fromJson({
        'id': 'food-1',
        'createdAt': createdAtText,
        'loggedAt': 'lunchtime',
        'deletedAt': 'never',
      });

      expect(parsed.loggedAt, createdAt);
      expect(parsed.deletedAt, isNull);
    });

    test('should throw CorruptDataError when id is missing', () {
      expect(() => FoodLog.fromJson({'createdAt': createdAtText}), throwsCorruptField('id'));
    });

    test('should throw CorruptDataError when createdAt is malformed', () {
      expect(
        () => FoodLog.fromJson({'id': 'food-1', 'createdAt': 'today'}),
        throwsCorruptField('createdAt'),
      );
    });
  });
}
