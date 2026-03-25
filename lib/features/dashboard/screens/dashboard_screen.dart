import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../religious/providers/prayer_providers.dart';
import '../../religious/providers/quran_providers.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/offline_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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
            const SizedBox(height: 24),
            Text(
              'Use the left sidebar to jump between pages.',
              style: Theme.of(context).textTheme.bodyMedium,
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
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Title',
            hintText: 'Quick entry ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
          ),
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(labelText: 'Notes', hintText: 'Default: Today'),
        ),
        const SizedBox(height: 10),
        const Text('Smart defaults use current date/time context.'),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
                },
                child: const Text('Save'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved. Continue adding another item.')),
                  );
                },
                child: const Text('Save & Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
