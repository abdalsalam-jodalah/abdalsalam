import 'package:flutter/material.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import 'achievements_screen.dart';
import 'goals_screen.dart';
import 'life_plan_screen.dart';
import 'life_planning_topics_screen.dart';
import 'reviews_screen.dart';

class PlanningHomeScreen extends StatelessWidget {
  static const routeName = '/planning';

  const PlanningHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final accent = AppModuleAccents.forModule('planning');
    return Scaffold(
      appBar: AppBar(title: const Text('Life Planning')),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          _PlanningTile(
            icon: Icons.account_tree_outlined,
            title: 'Topics',
            subtitle: 'Topics, sub-topics, goals & tasks',
            accentColor: accent,
            onTap: () => Navigator.of(context).pushNamed(LifePlanningTopicsScreen.routeName),
          ),
          SizedBox(height: spacing.md),
          _PlanningTile(
            icon: Icons.auto_awesome_outlined,
            title: 'Life Plan',
            subtitle: 'Vision, mission, values & principles',
            accentColor: accent,
            onTap: () => Navigator.of(context).pushNamed(LifePlanScreen.routeName),
          ),
          SizedBox(height: spacing.md),
          _PlanningTile(
            icon: Icons.flag_outlined,
            title: 'Goals',
            subtitle: 'Life, quarterly, monthly, weekly & daily goals',
            accentColor: accent,
            onTap: () => Navigator.of(context).pushNamed(GoalsScreen.routeName),
          ),
          SizedBox(height: spacing.md),
          _PlanningTile(
            icon: Icons.emoji_events_outlined,
            title: 'Achievements',
            subtitle: 'What you have accomplished',
            accentColor: accent,
            onTap: () => Navigator.of(context).pushNamed(AchievementsScreen.routeName),
          ),
          SizedBox(height: spacing.md),
          _PlanningTile(
            icon: Icons.rate_review_outlined,
            title: 'Reviews',
            subtitle: 'Daily, weekly, monthly & quarterly self-review',
            accentColor: accent,
            onTap: () => Navigator.of(context).pushNamed(ReviewsScreen.routeName),
          ),
        ],
      ),
    );
  }
}

class _PlanningTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _PlanningTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return EntityTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      accentColor: accentColor,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
