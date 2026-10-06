import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/base_model.dart';
import 'package:abdalsalam/data/models/planning/achievement.dart';
import 'package:abdalsalam/data/models/planning/goal.dart';
import 'package:abdalsalam/data/models/planning/life_plan.dart';
import 'package:abdalsalam/data/models/planning/plan_topic.dart';
import 'package:abdalsalam/data/models/planning/planning_task.dart';
import 'package:abdalsalam/data/models/planning/review.dart';
import 'package:abdalsalam/data/models/planning/task_category.dart';
import 'package:abdalsalam/data/repositories/planning/achievement_repository.dart';
import 'package:abdalsalam/data/repositories/planning/goal_repository.dart';
import 'package:abdalsalam/data/repositories/planning/life_plan_repository.dart';
import 'package:abdalsalam/data/repositories/planning/plan_topic_repository.dart';
import 'package:abdalsalam/data/repositories/planning/planning_task_repository.dart';
import 'package:abdalsalam/data/repositories/planning/review_repository.dart';
import 'package:abdalsalam/data/repositories/planning/task_category_repository.dart';

AppError fakePlanningStorageFailure() => DatabaseError('fake planning storage failure');

class FakePlanningCrudRepository<T extends BaseModel> {
  final List<T> items;
  bool shouldFailGetActive = false;
  bool shouldFailCreate = false;
  bool shouldFailUpdate = false;
  bool shouldFailSoftDelete = false;

  FakePlanningCrudRepository([List<T>? seed]) : items = seed ?? <T>[];

  Future<Result<List<T>, AppError>> getActive() async {
    if (shouldFailGetActive) {
      return Failure(fakePlanningStorageFailure());
    }
    return Success(List<T>.of(items));
  }

  Future<Result<T, AppError>> create(T entity) async {
    if (shouldFailCreate) {
      return Failure(fakePlanningStorageFailure());
    }
    items.add(entity);
    return Success(entity);
  }

  Future<Result<void, AppError>> update(T entity) async {
    if (shouldFailUpdate) {
      return Failure(fakePlanningStorageFailure());
    }
    final index = items.indexWhere((item) => item.id == entity.id);
    if (index != -1) {
      items[index] = entity;
    }
    return const Success(null);
  }

  Future<Result<void, AppError>> updateBulk(List<T> entities) async {
    if (shouldFailUpdate) {
      return Failure(fakePlanningStorageFailure());
    }
    for (final entity in entities) {
      final index = items.indexWhere((item) => item.id == entity.id);
      if (index != -1) {
        items[index] = entity;
      }
    }
    return const Success(null);
  }

  Future<Result<void, AppError>> softDelete(String id) async {
    if (shouldFailSoftDelete) {
      return Failure(fakePlanningStorageFailure());
    }
    items.removeWhere((item) => item.id == id);
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class FakeLifePlanRepository extends FakePlanningCrudRepository<LifePlan> implements LifePlanRepository {
  bool shouldFailGetForUser = false;

  FakeLifePlanRepository([super.seed]);

  @override
  Future<Result<LifePlan?, AppError>> getForUser(String userId) async {
    if (shouldFailGetForUser) {
      return Failure(fakePlanningStorageFailure());
    }
    final matches = items.where((plan) => plan.userId == userId);
    return Success(matches.isEmpty ? null : matches.first);
  }
}

class FakeGoalRepository extends FakePlanningCrudRepository<Goal> implements GoalRepository {
  bool shouldFailGetByScope = false;
  bool shouldFailGetChildren = false;
  bool shouldFailGetDueOn = false;

  FakeGoalRepository([super.seed]);

  @override
  Future<Result<List<Goal>, AppError>> getByScope(GoalScope scope) async {
    if (shouldFailGetByScope) {
      return Failure(fakePlanningStorageFailure());
    }
    return Success(items.where((goal) => goal.scope == scope).toList());
  }

  @override
  Future<Result<List<Goal>, AppError>> getChildren(String parentGoalId) async {
    if (shouldFailGetChildren) {
      return Failure(fakePlanningStorageFailure());
    }
    return Success(items.where((goal) => goal.parentGoalId == parentGoalId).toList());
  }

  @override
  Future<Result<List<Goal>, AppError>> getDueOn(DateTime date) async {
    if (shouldFailGetDueOn) {
      return Failure(fakePlanningStorageFailure());
    }
    return Success(items
        .where((goal) =>
            goal.targetDate != null &&
            goal.targetDate!.year == date.year &&
            goal.targetDate!.month == date.month &&
            goal.targetDate!.day == date.day)
        .toList());
  }
}

class FakeAchievementRepository extends FakePlanningCrudRepository<Achievement> implements AchievementRepository {
  bool shouldFailGetByGoal = false;

  FakeAchievementRepository([super.seed]);

  @override
  Future<Result<List<Achievement>, AppError>> getByGoal(String goalId) async {
    if (shouldFailGetByGoal) {
      return Failure(fakePlanningStorageFailure());
    }
    return Success(items.where((achievement) => achievement.goalId == goalId).toList());
  }
}

class FakeReviewRepository extends FakePlanningCrudRepository<Review> implements ReviewRepository {
  bool shouldFailGetByPeriod = false;

  FakeReviewRepository([super.seed]);

  @override
  Future<Result<List<Review>, AppError>> getByPeriod(ReviewPeriod period) async {
    if (shouldFailGetByPeriod) {
      return Failure(fakePlanningStorageFailure());
    }
    return Success(items.where((review) => review.period == period).toList());
  }
}

class FakePlanningTaskRepository extends FakePlanningCrudRepository<PlanningTask>
    implements PlanningTaskRepository {
  bool shouldFailGetByDate = false;
  bool shouldFailGetByGoal = false;

  FakePlanningTaskRepository([super.seed]);

  @override
  Future<Result<List<PlanningTask>, AppError>> getByDate(DateTime date) async {
    if (shouldFailGetByDate) {
      return Failure(fakePlanningStorageFailure());
    }
    return Success(items
        .where((task) =>
            task.date != null &&
            task.date!.year == date.year &&
            task.date!.month == date.month &&
            task.date!.day == date.day)
        .toList());
  }

  @override
  Future<Result<List<PlanningTask>, AppError>> getBoardTasks() async {
    if (shouldFailGetByDate) {
      return Failure(fakePlanningStorageFailure());
    }
    return Success(items.where((task) => task.date != null || task.goalId == null).toList());
  }

  @override
  Future<Result<List<PlanningTask>, AppError>> getByCategory(String categoryId) async {
    if (shouldFailGetByDate) {
      return Failure(fakePlanningStorageFailure());
    }
    return Success(items.where((task) => task.categoryIds.contains(categoryId)).toList());
  }

  @override
  Future<Result<List<PlanningTask>, AppError>> getByGoal(String goalId) async {
    if (shouldFailGetByGoal) {
      return Failure(fakePlanningStorageFailure());
    }
    return Success(items.where((task) => task.goalId == goalId).toList());
  }
}

class FakeTaskCategoryRepository extends FakePlanningCrudRepository<TaskCategory>
    implements TaskCategoryRepository {
  FakeTaskCategoryRepository([super.seed]);
}

class FakePlanTopicRepository extends FakePlanningCrudRepository<PlanTopic> implements PlanTopicRepository {
  bool shouldFailGetChildren = false;
  bool shouldFailGetRootTopics = false;

  FakePlanTopicRepository([super.seed]);

  @override
  Future<Result<List<PlanTopic>, AppError>> getChildren(String parentTopicId) async {
    if (shouldFailGetChildren) {
      return Failure(fakePlanningStorageFailure());
    }
    return Success(items.where((topic) => topic.parentTopicId == parentTopicId).toList());
  }

  @override
  Future<Result<List<PlanTopic>, AppError>> getRootTopics() async {
    if (shouldFailGetRootTopics) {
      return Failure(fakePlanningStorageFailure());
    }
    return Success(items.where((topic) => topic.parentTopicId == null).toList());
  }
}

LifePlan buildLifePlan({
  String id = 'life-plan-1',
  String userId = 'user1',
}) {
  final now = DateTime(2026, 1, 1);
  return LifePlan(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    visionStatement: 'Vision',
    missionStatement: 'Mission',
    values: const <String>['Discipline'],
    principles: const <String>['Consistency'],
  );
}

Goal buildGoal({
  String id = 'goal-1',
  String userId = 'user1',
  String title = 'Read daily',
  GoalScope scope = GoalScope.daily,
  GoalStatus status = GoalStatus.inProgress,
  DateTime? targetDate,
  String? parentGoalId,
  String? topicId,
}) {
  final now = DateTime(2026, 1, 1);
  return Goal(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    title: title,
    scope: scope,
    status: status,
    targetDate: targetDate,
    parentGoalId: parentGoalId,
    topicId: topicId,
  );
}

Achievement buildAchievement({
  String id = 'achievement-1',
  String userId = 'user1',
  String? goalId,
  String title = 'Finished a book',
}) {
  final now = DateTime(2026, 1, 1);
  return Achievement(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    goalId: goalId,
    title: title,
    achievedAt: now,
  );
}

Review buildReview({
  String id = 'review-1',
  String userId = 'user1',
  ReviewPeriod period = ReviewPeriod.weekly,
}) {
  final now = DateTime(2026, 1, 1);
  return Review(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    period: period,
    periodStart: now,
    periodEnd: now,
  );
}

PlanningTask buildPlanningTask({
  String id = 'task-1',
  String userId = 'user1',
  String title = 'Draft outline',
  DateTime? date,
  String? goalId,
  List<String> categoryIds = const <String>[],
}) {
  final now = DateTime(2026, 1, 1);
  return PlanningTask(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    title: title,
    date: date,
    goalId: goalId,
    categoryIds: categoryIds,
  );
}

TaskCategory buildTaskCategory({
  String id = 'category-1',
  String userId = 'user1',
  String name = 'iOS',
  String color = '#F5A623',
}) {
  final now = DateTime(2026, 1, 1);
  return TaskCategory(id: id, createdAt: now, updatedAt: now, userId: userId, name: name, color: color);
}

PlanTopic buildPlanTopic({
  String id = 'topic-1',
  String userId = 'user1',
  String title = 'Career',
  String? parentTopicId,
}) {
  final now = DateTime(2026, 1, 1);
  return PlanTopic(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    title: title,
    parentTopicId: parentTopicId,
  );
}
