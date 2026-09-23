import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

import '../../../data/repositories/planning/life_plan_repository.dart';
import '../../../data/repositories/planning/goal_repository.dart';
import '../../../data/repositories/planning/achievement_repository.dart';
import '../../../data/repositories/planning/review_repository.dart';
import '../../../data/repositories/planning/planning_task_repository.dart';
import '../../../data/repositories/planning/plan_topic_repository.dart';
import '../../../data/models/planning/life_plan.dart';
import '../../../data/models/planning/goal.dart';
import '../../../data/models/planning/achievement.dart';
import '../../../data/models/planning/review.dart';
import '../../../data/models/planning/planning_task.dart';
import '../../../data/models/planning/plan_topic.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../services/achievement_service.dart';
import '../services/goal_service.dart';
import '../services/life_plan_service.dart';
import '../services/plan_topic_service.dart';
import '../services/planning_task_service.dart';
import '../services/review_service.dart';

const String planningUserId = 'user1';

// Repository Providers
final lifePlanRepositoryProvider = Provider<LifePlanRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'LifePlanRepository',
    moduleType: logic.ModuleType.repository,
  );
  return LifePlanRepositoryImpl(storage, logger);
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'GoalRepository',
    moduleType: logic.ModuleType.repository,
  );
  return GoalRepositoryImpl(storage, logger);
});

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'AchievementRepository',
    moduleType: logic.ModuleType.repository,
  );
  return AchievementRepositoryImpl(storage, logger);
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'ReviewRepository',
    moduleType: logic.ModuleType.repository,
  );
  return ReviewRepositoryImpl(storage, logger);
});

final planningTaskRepositoryProvider = Provider<PlanningTaskRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'PlanningTaskRepository',
    moduleType: logic.ModuleType.repository,
  );
  return PlanningTaskRepositoryImpl(storage, logger);
});

final planTopicRepositoryProvider = Provider<PlanTopicRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'PlanTopicRepository',
    moduleType: logic.ModuleType.repository,
  );
  return PlanTopicRepositoryImpl(storage, logger);
});

final lifePlanServiceProvider = Provider<LifePlanService>((ref) {
  return LifePlanService(
    ref.watch(lifePlanRepositoryProvider),
    LoggerService.forModule('LifePlanService', moduleType: logic.ModuleType.service),
  );
});

final goalServiceProvider = Provider<GoalService>((ref) {
  return GoalService(
    ref.watch(goalRepositoryProvider),
    LoggerService.forModule('GoalService', moduleType: logic.ModuleType.service),
  );
});

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService(
    ref.watch(achievementRepositoryProvider),
    LoggerService.forModule('AchievementService', moduleType: logic.ModuleType.service),
  );
});

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(
    ref.watch(reviewRepositoryProvider),
    LoggerService.forModule('ReviewService', moduleType: logic.ModuleType.service),
  );
});

final planningTaskServiceProvider = Provider<PlanningTaskService>((ref) {
  return PlanningTaskService(
    ref.watch(planningTaskRepositoryProvider),
    LoggerService.forModule('PlanningTaskService', moduleType: logic.ModuleType.service),
  );
});

final planTopicServiceProvider = Provider<PlanTopicService>((ref) {
  return PlanTopicService(
    ref.watch(planTopicRepositoryProvider),
    LoggerService.forModule('PlanTopicService', moduleType: logic.ModuleType.service),
  );
});

// Data Providers
final lifePlanProvider = FutureProvider<LifePlan?>((ref) async {
  final repo = ref.watch(lifePlanRepositoryProvider);
  final result = await repo.getForUser(planningUserId);
  return result.data;
});

final activeGoalsProvider = FutureProvider<List<Goal>>((ref) async {
  final repo = ref.watch(goalRepositoryProvider);
  final result = await repo.getActive();
  return result.data ?? [];
});

final goalsByScopeProvider = FutureProvider.family<List<Goal>, GoalScope>((ref, scope) async {
  final goals = await ref.watch(activeGoalsProvider.future);
  return goals.where((goal) => goal.scope == scope).toList(growable: false);
});

final goalsForDateProvider = FutureProvider.family<List<Goal>, DateTime>((ref, date) async {
  final repo = ref.watch(goalRepositoryProvider);
  final result = await repo.getDueOn(date);
  final goals = result.data ?? [];
  return goals.where((goal) => goal.scope == GoalScope.daily).toList(growable: false);
});

final todaysGoalsProvider = FutureProvider<List<Goal>>((ref) {
  return ref.watch(goalsForDateProvider(DateTime.now()).future);
});

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final repo = ref.watch(achievementRepositoryProvider);
  final result = await repo.getActive();
  return result.data ?? [];
});

final reviewsByPeriodProvider = FutureProvider.family<List<Review>, ReviewPeriod>((ref, period) async {
  final repo = ref.watch(reviewRepositoryProvider);
  final result = await repo.getByPeriod(period);
  return result.data ?? [];
});

final tasksForDateProvider = FutureProvider.family<List<PlanningTask>, DateTime>((ref, date) async {
  final repo = ref.watch(planningTaskRepositoryProvider);
  final result = await repo.getByDate(date);
  return result.data ?? [];
});

final tasksForGoalProvider = FutureProvider.family<List<PlanningTask>, String>((ref, goalId) async {
  final repo = ref.watch(planningTaskRepositoryProvider);
  final result = await repo.getByGoal(goalId);
  return result.data ?? [];
});

final rootTopicsProvider = FutureProvider<List<PlanTopic>>((ref) async {
  final repo = ref.watch(planTopicRepositoryProvider);
  final result = await repo.getRootTopics();
  return result.data ?? [];
});

final subTopicsProvider = FutureProvider.family<List<PlanTopic>, String>((ref, parentTopicId) async {
  final repo = ref.watch(planTopicRepositoryProvider);
  final result = await repo.getChildren(parentTopicId);
  return result.data ?? [];
});

final goalsForTopicProvider = FutureProvider.family<List<Goal>, String>((ref, topicId) async {
  final goals = await ref.watch(activeGoalsProvider.future);
  return goals.where((goal) => goal.topicId == topicId).toList(growable: false);
});
