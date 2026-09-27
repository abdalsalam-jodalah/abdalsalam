import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/religious/prayer_times_snapshot.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/ui/app_card.dart';
import 'prayer_time_card.dart';

class ReligiousPrayerTimesSection extends StatelessWidget {
  final AsyncValue<PrayerTimesSnapshot> prayerTimes;
  final VoidCallback onRetry;

  const ReligiousPrayerTimesSection({super.key, required this.prayerTimes, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return AppCard(
      child: prayerTimes.when(
        data: (times) => _PrayerTimesContent(times: times),
        loading: () => Padding(
          padding: EdgeInsets.all(tokens.spacing.xl),
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => AsyncErrorView(error: error, isCompact: true, onRetry: onRetry),
      ),
    );
  }
}

class _PrayerTimesContent extends StatelessWidget {
  final PrayerTimesSnapshot times;

  const _PrayerTimesContent({required this.times});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final now = clock.now();
    final entries = <MapEntry<String, DateTime>>[
      MapEntry('Fajr', times.fajr),
      MapEntry('Dhuhr', times.dhuhr),
      MapEntry('Asr', times.asr),
      MapEntry('Maghrib', times.maghrib),
      MapEntry('Isha', times.isha),
    ];
    final nextEntry = entries.firstWhere(
      (entry) => entry.value.isAfter(now),
      orElse: () => entries.first,
    );
    final untilNext = nextEntry.value.isAfter(now)
        ? nextEntry.value.difference(now)
        : nextEntry.value.add(const Duration(days: 1)).difference(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Prayer Times', style: theme.textTheme.titleMedium),
            Text(
              'Next: ${nextEntry.key} in ${untilNext.inHours}h ${untilNext.inMinutes.remainder(60)}m',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spacing.xs),
        Text(
          'Updated ${AppDateFormatter.time(times.fetchedAt)}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        SizedBox(height: tokens.spacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in entries) ...[
                PrayerTimeCard(
                  prayerName: item.key,
                  time: item.value,
                  isNext: item.key == nextEntry.key,
                  isPast: item.value.isBefore(now),
                ),
                SizedBox(width: tokens.spacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
