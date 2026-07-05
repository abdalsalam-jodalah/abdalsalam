import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

import '../../../data/repositories/planning/life_plan_repository.dart';
import '../../../data/repositories/planning/goal_repository.dart';
import '../../../data/repositories/planning/achievement_repository.dart';
import '../../../data/repositories/planning/review_repository.dart';
import '../../../data/models/planning/life_plan.dart';
import '../../../data/models/planning/goal.dart';
import '../../../data/models/planning/achievement.dart';
import '../../../data/models/planning/review.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/infrastructure/logger_service.dart';

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

final todaysGoalsProvider = FutureProvider<List<Goal>>((ref) async {
  final repo = ref.watch(goalRepositoryProvider);
  final result = await repo.getDueOn(DateTime.now());
  final goals = result.data ?? [];
  return goals.where((goal) => goal.scope == GoalScope.daily).toList(growable: false);
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
