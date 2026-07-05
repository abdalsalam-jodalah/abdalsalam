import 'package:flutter/material.dart';

import 'achievements_screen.dart';
import 'goals_screen.dart';
import 'life_plan_screen.dart';
import 'reviews_screen.dart';

class PlanningHomeScreen extends StatelessWidget {
  static const routeName = '/planning';

  const PlanningHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Life & Day Planning')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PlanningTile(
            icon: Icons.auto_awesome_outlined,
            title: 'Life Plan',
            subtitle: 'Vision, mission, values & principles',
            onTap: () => Navigator.of(context).pushNamed(LifePlanScreen.routeName),
          ),
          const SizedBox(height: 12),
          _PlanningTile(
            icon: Icons.flag_outlined,
            title: 'Goals',
            subtitle: 'Life, quarterly, monthly, weekly & daily goals',
            onTap: () => Navigator.of(context).pushNamed(GoalsScreen.routeName),
          ),
          const SizedBox(height: 12),
          _PlanningTile(
            icon: Icons.emoji_events_outlined,
            title: 'Achievements',
            subtitle: 'What you have accomplished',
            onTap: () => Navigator.of(context).pushNamed(AchievementsScreen.routeName),
          ),
          const SizedBox(height: 12),
          _PlanningTile(
            icon: Icons.rate_review_outlined,
            title: 'Reviews',
            subtitle: 'Daily, weekly, monthly & quarterly self-review',
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
  final VoidCallback onTap;

  const _PlanningTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
