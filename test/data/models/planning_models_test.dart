import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/planning/achievement.dart';
import 'package:abdalsalam/data/models/planning/goal.dart';
import 'package:abdalsalam/data/models/planning/life_plan.dart';
import 'package:abdalsalam/data/models/planning/plan_topic.dart';
import 'package:abdalsalam/data/models/planning/planning_task.dart';
import 'package:abdalsalam/data/models/planning/review.dart';
import 'package:flutter_test/flutter_test.dart';

const String createdAtIso = '2026-01-01T08:00:00.000';
final DateTime createdAt = DateTime(2026, 1, 1, 8);

Map<String, dynamic> baseJson() => <String, dynamic>{
      'id': 'record-1',
      'createdAt': createdAtIso,
      'userId': 'user1',
    };

void main() {
  group('Goal.fromJson', () {
    test('should keep every field when round tripping valid json', () {
      final goal = Goal(
        id: 'goal-1',
        createdAt: createdAt,
        updatedAt: DateTime(2026, 1, 2),
        deletedAt: DateTime(2026, 1, 3),
        userId: 'user1',
        title: 'Run a marathon',
        description: 'Train',
        scope: GoalScope.yearly,
        status: GoalStatus.inProgress,
        targetDate: DateTime(2026, 12, 1),
        parentGoalId: 'goal-0',
        progress: 0.4,
        area: LifeArea.body,
        topicId: 'topic-1',
      );

      final parsed = Goal.fromJson(goal.toJson());

      expect(parsed.toJson(), goal.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final json = baseJson();

      final parsed = Goal.fromJson(json);

      expect(parsed.updatedAt, createdAt);
      expect(parsed.title, '');
      expect(parsed.scope, GoalScope.life);
      expect(parsed.status, GoalStatus.notStarted);
      expect(parsed.progress, 0);
      expect(parsed.area, isNull);
      expect(parsed.targetDate, isNull);
    });

    test('should tolerate wrong types when values are convertible', () {
      final json = baseJson()..['progress'] = '0.75';

      final parsed = Goal.fromJson(json);

      expect(parsed.progress, 0.75);
    });

    test('should return null when an optional date is invalid', () {
      final json = baseJson()..['targetDate'] = 'not-a-date';

      final parsed = Goal.fromJson(json);

      expect(parsed.targetDate, isNull);
    });

    test('should fall back when enum values are unknown', () {
      final json = baseJson()
        ..['scope'] = 'decade'
        ..['status'] = 'paused'
        ..['area'] = 'career';

      final parsed = Goal.fromJson(json);

      expect(parsed.scope, GoalScope.life);
      expect(parsed.status, GoalStatus.notStarted);
      expect(parsed.area, isNull);
    });

    test('should throw CorruptDataError when id is missing', () {
      final json = baseJson()..remove('id');

      expect(() => Goal.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('Achievement.fromJson', () {
    test('should keep every field when round tripping valid json', () {
      final achievement = Achievement(
        id: 'achievement-1',
        createdAt: createdAt,
        updatedAt: DateTime(2026, 1, 2),
        userId: 'user1',
        goalId: 'goal-1',
        title: 'Finished',
        description: 'Done',
        achievedAt: DateTime(2026, 1, 2, 12),
        scope: GoalScope.monthly,
      );

      final parsed = Achievement.fromJson(achievement.toJson());

      expect(parsed.toJson(), achievement.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final json = baseJson();

      final parsed = Achievement.fromJson(json);

      expect(parsed.title, '');
      expect(parsed.goalId, isNull);
      expect(parsed.achievedAt, createdAt);
      expect(parsed.scope, isNull);
    });

    test('should tolerate wrong types when values are convertible', () {
      final json = baseJson()..['title'] = 10;

      final parsed = Achievement.fromJson(json);

      expect(parsed.title, '10');
    });

    test('should fall back when dates are invalid', () {
      final json = baseJson()
        ..['achievedAt'] = 'not-a-date'
        ..['deletedAt'] = 'not-a-date';

      final parsed = Achievement.fromJson(json);

      expect(parsed.achievedAt, createdAt);
      expect(parsed.deletedAt, isNull);
    });

    test('should return null scope when the enum is unknown', () {
      final json = baseJson()..['scope'] = 'decade';

      final parsed = Achievement.fromJson(json);

      expect(parsed.scope, isNull);
    });

    test('should throw CorruptDataError when createdAt is missing', () {
      final json = baseJson()..remove('createdAt');

      expect(() => Achievement.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('LifePlan.fromJson', () {
    test('should keep every field when round tripping valid json', () {
      final plan = LifePlan(
        id: 'plan-1',
        createdAt: createdAt,
        updatedAt: DateTime(2026, 1, 2),
        userId: 'user1',
        visionStatement: 'Vision',
        missionStatement: 'Mission',
        values: const <String>['Honesty'],
        principles: const <String>['Consistency'],
      );

      final parsed = LifePlan.fromJson(plan.toJson());

      expect(parsed.toJson(), plan.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final json = baseJson();

      final parsed = LifePlan.fromJson(json);

      expect(parsed.visionStatement, '');
      expect(parsed.missionStatement, '');
      expect(parsed.values, isEmpty);
      expect(parsed.principles, isEmpty);
    });

    test('should tolerate wrong types when values are convertible', () {
      final json = baseJson()
        ..['values'] = <dynamic>['Honesty', 1, null]
        ..['principles'] = 'not-a-list';

      final parsed = LifePlan.fromJson(json);

      expect(parsed.values, <String>['Honesty']);
      expect(parsed.principles, isEmpty);
    });

    test('should fall back when dates are invalid', () {
      final json = baseJson()..['updatedAt'] = 'not-a-date';

      final parsed = LifePlan.fromJson(json);

      expect(parsed.updatedAt, createdAt);
    });

    test('should throw CorruptDataError when id is missing', () {
      final json = baseJson()..remove('id');

      expect(() => LifePlan.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('PlanTopic.fromJson', () {
    test('should keep every field when round tripping valid json', () {
      final topic = PlanTopic(
        id: 'topic-1',
        createdAt: createdAt,
        updatedAt: DateTime(2026, 1, 2),
        userId: 'user1',
        title: 'Health',
        description: 'Body goals',
        parentTopicId: 'topic-0',
      );

      final parsed = PlanTopic.fromJson(topic.toJson());

      expect(parsed.toJson(), topic.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final json = baseJson();

      final parsed = PlanTopic.fromJson(json);

      expect(parsed.title, '');
      expect(parsed.description, isNull);
      expect(parsed.parentTopicId, isNull);
    });

    test('should tolerate wrong types when values are convertible', () {
      final json = baseJson()..['title'] = true;

      final parsed = PlanTopic.fromJson(json);

      expect(parsed.title, 'true');
    });

    test('should return null when an optional date is invalid', () {
      final json = baseJson()..['deletedAt'] = 'not-a-date';

      final parsed = PlanTopic.fromJson(json);

      expect(parsed.deletedAt, isNull);
    });

    test('should throw CorruptDataError when id has an unusable type', () {
      final json = baseJson()..['id'] = <String>['bad'];

      expect(() => PlanTopic.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('PlanningTask.fromJson', () {
    test('should keep every field when round tripping valid json', () {
      final task = PlanningTask(
        id: 'task-1',
        createdAt: createdAt,
        updatedAt: DateTime(2026, 1, 2),
        userId: 'user1',
        title: 'Plan day',
        description: 'Morning',
        isCompleted: true,
        order: 3,
        date: DateTime(2026, 1, 1),
        goalId: 'goal-1',
      );

      final parsed = PlanningTask.fromJson(task.toJson());

      expect(parsed.toJson(), task.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final json = baseJson();

      final parsed = PlanningTask.fromJson(json);

      expect(parsed.title, '');
      expect(parsed.isCompleted, isFalse);
      expect(parsed.order, 0);
      expect(parsed.date, isNull);
      expect(parsed.goalId, isNull);
    });

    test('should tolerate wrong types when values are convertible', () {
      final json = baseJson()
        ..['order'] = 3.0
        ..['isCompleted'] = 'false';

      final parsed = PlanningTask.fromJson(json);

      expect(parsed.order, 3);
      expect(parsed.isCompleted, isFalse);
    });

    test('should return null when an optional date is invalid', () {
      final json = baseJson()..['date'] = 'not-a-date';

      final parsed = PlanningTask.fromJson(json);

      expect(parsed.date, isNull);
    });

    test('should throw CorruptDataError when createdAt is invalid', () {
      final json = baseJson()..['createdAt'] = 'not-a-date';

      expect(() => PlanningTask.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('Review.fromJson', () {
    Map<String, dynamic> reviewJson() => baseJson()
      ..['period'] = 'weekly'
      ..['periodStart'] = '2026-01-05T00:00:00.000'
      ..['periodEnd'] = '2026-01-11T00:00:00.000';

    test('should keep every field when round tripping valid json', () {
      final review = Review(
        id: 'review-1',
        createdAt: createdAt,
        updatedAt: DateTime(2026, 1, 2),
        userId: 'user1',
        period: ReviewPeriod.monthly,
        periodStart: DateTime(2026, 1, 1),
        periodEnd: DateTime(2026, 1, 31),
        wins: 'wins',
        challenges: 'challenges',
        lessonsLearned: 'lessons',
        nextFocus: 'focus',
        rating: 4,
        relatedGoalIds: const <String>['goal-1'],
      );

      final parsed = Review.fromJson(review.toJson());

      expect(parsed.toJson(), review.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final json = reviewJson();

      final parsed = Review.fromJson(json);

      expect(parsed.updatedAt, createdAt);
      expect(parsed.wins, isNull);
      expect(parsed.rating, isNull);
      expect(parsed.relatedGoalIds, isEmpty);
    });

    test('should tolerate wrong types when values are convertible', () {
      final json = reviewJson()..['rating'] = '4';

      final parsed = Review.fromJson(json);

      expect(parsed.rating, 4);
    });

    test('should return null when an optional date is invalid', () {
      final json = reviewJson()..['deletedAt'] = 'not-a-date';

      final parsed = Review.fromJson(json);

      expect(parsed.deletedAt, isNull);
    });

    test('should throw CorruptDataError when the period enum is unknown', () {
      final json = reviewJson()..['period'] = 'yearly';

      expect(() => Review.fromJson(json), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when periodStart is invalid', () {
      final json = reviewJson()..['periodStart'] = 'not-a-date';

      expect(() => Review.fromJson(json), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when periodEnd is missing', () {
      final json = reviewJson()..remove('periodEnd');

      expect(() => Review.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });
}
