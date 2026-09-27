import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/religious/religious_entry.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/page_header.dart';
import '../providers/religious_tracking_providers.dart';
import '../widgets/religious_daily_reminder_card.dart';
import '../widgets/religious_entry_dialog.dart';
import '../widgets/religious_home_stats.dart';
import '../widgets/religious_prayer_times_section.dart';
import '../widgets/religious_quick_log_grid.dart';
import '../widgets/religious_today_logs_list.dart';
import 'prayer_logs_screen.dart';
import 'quran_reading_screen.dart';
import 'religious_history_screen.dart';

const String _prayerTimesSyncedMessage = 'Prayer times synced successfully';

class ReligiousHomeScreen extends ConsumerWidget {
  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [ReligiousScreen] shell.
  final bool embedded;

  const ReligiousHomeScreen({super.key, this.embedded = false});

  Future<void> _syncPrayerTimes(BuildContext context, WidgetRef ref) async {
    final error = await ref.read(religiousLogsControllerProvider.notifier).syncPrayerTimes();
    if (!context.mounted) {
      return;
    }
    if (error != null) {
      AppFeedback.showError(context, error);
      return;
    }
    AppFeedback.showSuccess(context, _prayerTimesSyncedMessage);
  }

  Future<void> _logNightPrayer(BuildContext context, WidgetRef ref) {
    return showReligiousEntryDialog(
      context,
      ref,
      type: ReligiousEntryType.nightPrayer,
      defaultTitle: 'Night prayer',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (embedded) {
      return Column(
        children: [
          PageHeader(
            title: 'Dashboard',
            actions: [
              IconButton(
                tooltip: 'Sync prayer times',
                onPressed: () => _syncPrayerTimes(context, ref),
                icon: const Icon(Icons.sync),
              ),
            ],
          ),
          Expanded(child: _buildBody(context, ref)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Religious Module'),
        actions: [
          IconButton(
            tooltip: 'Sync prayer times',
            onPressed: () => _syncPrayerTimes(context, ref),
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'History',
            onPressed: () => Navigator.of(context).pushNamed(ReligiousHistoryScreen.routeName),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final prayerTimes = ref.watch(todayPrayerTimesProvider);
    final todayLogs = ref.watch(todayReligiousLogsProvider);
    final isLogsLoading = ref.watch(religiousLogsControllerProvider).isLoading;

    return ListView(
      key: const ValueKey('religious-home'),
      padding: EdgeInsets.all(tokens.spacing.lg),
      children: [
        ReligiousPrayerTimesSection(
          prayerTimes: prayerTimes,
          onRetry: () => ref.invalidate(todayPrayerTimesProvider),
        ),
        SizedBox(height: tokens.spacing.md),
        const ReligiousDailyReminderCard(),
        SizedBox(height: tokens.spacing.md),
        const ReligiousHomeStats(),
        AppSectionHeader(
          title: 'Quick Log',
          action: TextButton(
            onPressed: () => Navigator.of(context).pushNamed(QuranReadingScreen.routeName),
            child: const Text('Quran Log'),
          ),
        ),
        ReligiousQuickLogGrid(onNightPrayerTap: () => _logNightPrayer(context, ref)),
        AppSectionHeader(title: "Today's Logs"),
        if (isLogsLoading)
          Padding(
            padding: EdgeInsets.all(tokens.spacing.xl),
            child: const Center(child: CircularProgressIndicator()),
          )
        else
          ReligiousTodayLogsList(
            logs: todayLogs,
            onLogPrayer: () => Navigator.of(context).pushNamed(PrayerLogsScreen.routeName),
          ),
      ],
    );
  }
}
