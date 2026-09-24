import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/planning/goal.dart';
import 'package:abdalsalam/data/models/planning/review.dart';
import 'package:abdalsalam/features/planning/providers/planning_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'planning_fakes.dart';

void main() {
  group('lifePlanProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeLifePlanRepository()..shouldFailGetForUser = true;
      final container = ProviderContainer(overrides: [
        lifePlanRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(lifePlanProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns the plan on success', () async {
      final repo = FakeLifePlanRepository([buildLifePlan(userId: planningUserId)]);
      final container = ProviderContainer(overrides: [
        lifePlanRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final plan = await container.read(lifePlanProvider.future);
      expect(plan?.id, 'life-plan-1');
    });

    test('returns null when no plan exists yet, without treating it as failure', () async {
      final repo = FakeLifePlanRepository();
      final container = ProviderContainer(overrides: [
        lifePlanRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final plan = await container.read(lifePlanProvider.future);
      expect(plan, isNull);
    });
  });

  group('activeGoalsProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeGoalRepository()..shouldFailGetActive = true;
      final container = ProviderContainer(overrides: [
        goalRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(activeGoalsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns active goals on success', () async {
      final repo = FakeGoalRepository([buildGoal()]);
      final container = ProviderContainer(overrides: [
        goalRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final goals = await container.read(activeGoalsProvider.future);
      expect(goals.length, 1);
    });
  });

  group('goalsByScopeProvider', () {
    test('propagates a failure from activeGoalsProvider', () async {
      final repo = FakeGoalRepository()..shouldFailGetActive = true;
      final container = ProviderContainer(overrides: [
        goalRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(goalsByScopeProvider(GoalScope.daily).future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('filters active goals by scope on success', () async {
      final repo = FakeGoalRepository([
        buildGoal(id: 'g1', scope: GoalScope.daily),
        buildGoal(id: 'g2', scope: GoalScope.weekly),
      ]);
      final container = ProviderContainer(overrides: [
        goalRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final goals = await container.read(goalsByScopeProvider(GoalScope.daily).future);
      expect(goals.map((goal) => goal.id), ['g1']);
    });
  });

  group('goalsForDateProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeGoalRepository()..shouldFailGetDueOn = true;
      final container = ProviderContainer(overrides: [
        goalRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(goalsForDateProvider(DateTime(2026, 1, 1)).future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns only daily goals due on the date on success', () async {
      final due = DateTime(2026, 1, 1);
      final repo = FakeGoalRepository([
        buildGoal(id: 'g1', scope: GoalScope.daily, targetDate: due),
        buildGoal(id: 'g2', scope: GoalScope.weekly, targetDate: due),
      ]);
      final container = ProviderContainer(overrides: [
        goalRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final goals = await container.read(goalsForDateProvider(due).future);
      expect(goals.map((goal) => goal.id), ['g1']);
    });
  });

  group('achievementsProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeAchievementRepository()..shouldFailGetActive = true;
      final container = ProviderContainer(overrides: [
        achievementRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(achievementsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns achievements on success', () async {
      final repo = FakeAchievementRepository([buildAchievement()]);
      final container = ProviderContainer(overrides: [
        achievementRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final achievements = await container.read(achievementsProvider.future);
      expect(achievements.length, 1);
    });
  });

  group('reviewsByPeriodProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeReviewRepository()..shouldFailGetByPeriod = true;
      final container = ProviderContainer(overrides: [
        reviewRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(reviewsByPeriodProvider(ReviewPeriod.weekly).future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns reviews for the period on success', () async {
      final repo = FakeReviewRepository([buildReview(period: ReviewPeriod.weekly)]);
      final container = ProviderContainer(overrides: [
        reviewRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final reviews = await container.read(reviewsByPeriodProvider(ReviewPeriod.weekly).future);
      expect(reviews.length, 1);
    });
  });

  group('tasksForDateProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakePlanningTaskRepository()..shouldFailGetByDate = true;
      final container = ProviderContainer(overrides: [
        planningTaskRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(tasksForDateProvider(DateTime(2026, 1, 1)).future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns tasks for the date on success', () async {
      final repo = FakePlanningTaskRepository([buildPlanningTask(date: DateTime(2026, 1, 1))]);
      final container = ProviderContainer(overrides: [
        planningTaskRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final tasks = await container.read(tasksForDateProvider(DateTime(2026, 1, 1)).future);
      expect(tasks.length, 1);
    });
  });

  group('tasksForGoalProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakePlanningTaskRepository()..shouldFailGetByGoal = true;
      final container = ProviderContainer(overrides: [
        planningTaskRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(tasksForGoalProvider('goal-1').future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns tasks for the goal on success', () async {
      final repo = FakePlanningTaskRepository([buildPlanningTask(goalId: 'goal-1')]);
      final container = ProviderContainer(overrides: [
        planningTaskRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final tasks = await container.read(tasksForGoalProvider('goal-1').future);
      expect(tasks.length, 1);
    });
  });

  group('rootTopicsProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakePlanTopicRepository()..shouldFailGetRootTopics = true;
      final container = ProviderContainer(overrides: [
        planTopicRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(rootTopicsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns root topics on success', () async {
      final repo = FakePlanTopicRepository([buildPlanTopic()]);
      final container = ProviderContainer(overrides: [
        planTopicRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final topics = await container.read(rootTopicsProvider.future);
      expect(topics.length, 1);
    });
  });

  group('subTopicsProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakePlanTopicRepository()..shouldFailGetChildren = true;
      final container = ProviderContainer(overrides: [
        planTopicRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(subTopicsProvider('topic-1').future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns children on success', () async {
      final repo = FakePlanTopicRepository([buildPlanTopic(id: 'child-1', parentTopicId: 'topic-1')]);
      final container = ProviderContainer(overrides: [
        planTopicRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final topics = await container.read(subTopicsProvider('topic-1').future);
      expect(topics.map((topic) => topic.id), ['child-1']);
    });
  });

  group('goalsForTopicProvider', () {
    test('propagates a failure from activeGoalsProvider', () async {
      final repo = FakeGoalRepository()..shouldFailGetActive = true;
      final container = ProviderContainer(overrides: [
        goalRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(goalsForTopicProvider('topic-1').future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('filters active goals by topic on success', () async {
      final repo = FakeGoalRepository([
        buildGoal(id: 'g1', topicId: 'topic-1'),
        buildGoal(id: 'g2', topicId: 'topic-2'),
      ]);
      final container = ProviderContainer(overrides: [
        goalRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final goals = await container.read(goalsForTopicProvider('topic-1').future);
      expect(goals.map((goal) => goal.id), ['g1']);
    });
  });
}
