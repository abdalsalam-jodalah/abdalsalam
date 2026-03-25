import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../analytics/screens/analytics_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../financial/screens/financial_screen.dart';
import '../../habits/screens/habits_screen.dart';
import '../../health/screens/health_screen.dart';
import '../../notes/screens/notes_screen.dart';
import '../../religious/providers/prayer_providers.dart';
import '../../religious/providers/quran_providers.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../religious/screens/prayer_logs_screen.dart';
import '../../security/screens/security_screen.dart';
import '../../sports/screens/sports_screen.dart';

class _ModuleCardData {
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;

  const _ModuleCardData({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
  });
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _modules = <_ModuleCardData>[
    _ModuleCardData(
      title: 'Religious Tracking',
      subtitle: 'Log daily prayers and Quran progress',
      route: PrayerLogsScreen.routeName,
      icon: Icons.mosque_outlined,
    ),
    _ModuleCardData(
      title: 'Financial Management',
      subtitle: 'Track expenses, income, and budgets',
      route: FinancialScreen.routeName,
      icon: Icons.account_balance_wallet_outlined,
    ),
    _ModuleCardData(
      title: 'Habits & Daily Events',
      subtitle: 'Build streaks and capture routines',
      route: HabitsScreen.routeName,
      icon: Icons.repeat_rounded,
    ),
    _ModuleCardData(
      title: 'Sports & Fitness',
      subtitle: 'Record workouts and progress',
      route: SportsScreen.routeName,
      icon: Icons.fitness_center,
    ),
    _ModuleCardData(
      title: 'Health Management',
      subtitle: 'Track medications and health metrics',
      route: HealthScreen.routeName,
      icon: Icons.health_and_safety_outlined,
    ),
    _ModuleCardData(
      title: 'Notes & Tasks',
      subtitle: 'Capture notes and daily todos',
      route: NotesScreen.routeName,
      icon: Icons.sticky_note_2_outlined,
    ),
    _ModuleCardData(
      title: 'Calendar Integration',
      subtitle: 'Manage events and reminders',
      route: CalendarScreen.routeName,
      icon: Icons.calendar_month_outlined,
    ),
    _ModuleCardData(
      title: 'Security Vault',
      subtitle: 'Secure your credentials safely',
      route: SecurityScreen.routeName,
      icon: Icons.lock_outline,
    ),
    _ModuleCardData(
      title: 'Dashboard & Analytics',
      subtitle: 'Visualize progress and trends',
      route: AnalyticsScreen.routeName,
      icon: Icons.insights_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerCount = ref.watch(prayerCountProvider);
    final quranPages = ref.watch(quranPagesTodayProvider);
    final isOffline = ref.watch(isOfflineProvider);
    final batteryInfo = ref.watch(batteryInfoProvider);
    final storageInfo = ref.watch(storageInfoProvider);
    final stateAware = ref.watch(stateAwareServiceProvider);
    final lowStorage = storageInfo.maybeWhen(
      data: (info) => info.usagePercentage >= 90,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abdalsalam Dashboard'),
        actions: [
          Icon(
            isOffline ? Icons.cloud_off : Icons.cloud_done,
            color: isOffline ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          batteryInfo.maybeWhen(
            data: (battery) {
              final level = battery.batteryLevel ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    '$level%',
                    style: TextStyle(
                      color: level < 20 ? Colors.red : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => Future<void>.delayed(const Duration(milliseconds: 400)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OfflineBanner(isOffline: isOffline),
            if (isOffline) const SizedBox(height: 12),
            if (lowStorage) ...[
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stateAware.storageWarningMessage() ?? 'Storage is running low.',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      ...stateAware.cleanupSuggestions().map((tip) => Text('• $tip')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Religious Tracking status'),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$prayerCount / 5 prayers',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '$quranPages pages today',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Today\'s Agenda', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 8),
                    Text('• Prayer: Maghrib in 40 min'),
                    Text('• Medication: Vitamin D at 20:00'),
                    Text('• Workout: Push session at 19:00'),
                    Text('• Todo: Review monthly budget'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'All Sections',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              itemCount: _modules.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final module = _modules[index];
                return _ModuleTile(module: module);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickAddModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
      ),
    );
  }

  Future<void> _showQuickAddModal(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DefaultTabController(
          length: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SizedBox(
              height: 360,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Prayer'),
                      Tab(text: 'Expense'),
                      Tab(text: 'Habit'),
                      Tab(text: 'Todo'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        _QuickAddPane(label: 'Quick prayer log saved'),
                        _QuickAddPane(label: 'Quick expense saved'),
                        _QuickAddPane(label: 'Quick habit completion saved'),
                        _QuickAddPane(label: 'Quick todo saved'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickAddPane extends StatelessWidget {
  final String label;

  const _QuickAddPane({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextField(decoration: InputDecoration(labelText: 'Title')),
        const SizedBox(height: 10),
        const TextField(decoration: InputDecoration(labelText: 'Notes')),
        const Spacer(),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final _ModuleCardData module;

  const _ModuleTile({required this.module});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).pushNamed(module.route),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(module.icon),
              const SizedBox(height: 8),
              Text(
                module.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                module.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
