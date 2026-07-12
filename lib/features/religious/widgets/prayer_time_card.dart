// lib/features/religious/widgets/prayer_time_card.dart
import 'package:flutter/material.dart';

class PrayerTimeCard extends StatelessWidget {
  final String prayerName;
  final DateTime time;
  final bool isNext;
  final bool isPast;

  const PrayerTimeCard({
    super.key,
    required this.prayerName,
    required this.time,
    this.isNext = false,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = isNext ? scheme.onPrimary : scheme.onSurface;
    final muted = isNext ? scheme.onPrimary.withValues(alpha: 0.85) : scheme.onSurfaceVariant;

    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isNext ? scheme.primary : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: isNext ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNext ? Icons.notifications_active_outlined : Icons.access_time,
            size: 18,
            color: isPast && !isNext ? muted : foreground,
          ),
          const SizedBox(height: 6),
          Text(
            prayerName,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isPast && !isNext ? muted : foreground,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            TimeOfDay.fromDateTime(time).format(context),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isPast && !isNext ? muted : foreground,
                ),
          ),
        ],
      ),
    );
  }
}
