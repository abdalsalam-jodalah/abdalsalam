import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/goal.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/async_section.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/progress_ring.dart';
import '../../planning/providers/planning_providers.dart';
import '../../../core/constants/dashboard_card_catalog.dart';

class DashboardGoalsSection extends ConsumerWidget {
  static const double _ringSize = 40;
  static const int _percentScale = 100;
  static const String _emptyTitle = 'No goals set for today.';
  static const String _emptySubtitle = 'Plan your day to see goals here';
  static const Map<GoalStatus, String> _statusLabels = <GoalStatus, String>{
    GoalStatus.notStarted: 'Not started',
    GoalStatus.inProgress: 'In progress',
    GoalStatus.achieved: 'Achieved',
    GoalStatus.abandoned: 'Abandoned',
  };

  const DashboardGoalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = AppThemeTokens.of(context).spacing;
    final accent = AppModuleAccents.forModule('planning');
    return AsyncSection<List<Goal>>(
      title: DashboardCardCatalog.labels[DashboardCardCatalog.goals],
      value: ref.watch(todaysGoalsProvider),
      onRetry: () => ref.invalidate(todaysGoalsProvider),
      builder: (goals) {
        if (goals.isEmpty) {
          return const AppCard(
            child: EmptyState(
              title: _emptyTitle,
              subtitle: _emptySubtitle,
              icon: Icons.flag_rounded,
              isCompact: true,
            ),
          );
        }
        return Column(
          children: [
            for (final goal in goals)
              Padding(
                padding: EdgeInsets.only(bottom: spacing.sm),
                child: EntityTile(
                  title: goal.title,
                  subtitle: _statusLabels[goal.status],
                  leading: ProgressRing(
                    value: goal.progress,
                    size: _ringSize,
                    color: accent,
                    center: Text(
                      '${(goal.progress * _percentScale).round()}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
