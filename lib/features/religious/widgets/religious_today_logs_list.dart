import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/religious/religious_entry.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import 'religious_entry_type_style.dart';

class ReligiousTodayLogsList extends StatelessWidget {
  static const String _emptyTitle = 'No logs for today yet';
  static const String _emptySubtitle = 'Use quick log above to record a prayer, Quran reading, athkar, or event.';
  static const String _emptyActionLabel = 'Log Prayer';

  final List<ReligiousEntry> logs;
  final VoidCallback onLogPrayer;

  const ReligiousTodayLogsList({super.key, required this.logs, required this.onLogPrayer});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return EmptyState(
        title: _emptyTitle,
        subtitle: _emptySubtitle,
        actionLabel: _emptyActionLabel,
        onAction: onLogPrayer,
      );
    }
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final item in logs)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spacing.sm),
            child: EntityTile(
              icon: ReligiousEntryTypeStyle.icon(item.type),
              accentColor: ReligiousEntryTypeStyle.color(context, item.type),
              title: item.title,
              subtitle: '${AppDateFormatter.time(item.loggedAt)} • ${_typeLabel(item.type)}'
                  '${item.details == null || item.details!.isEmpty ? '' : '\n${item.details}'}',
              subtitleMaxLines: 3,
              trailing: Text('x${item.count}', style: theme.textTheme.labelMedium),
            ),
          ),
      ],
    );
  }

  static String _typeLabel(ReligiousEntryType type) {
    switch (type) {
      case ReligiousEntryType.prayer:
        return 'Prayer';
      case ReligiousEntryType.quranReading:
        return 'Quran Reading';
      case ReligiousEntryType.badEvent:
        return 'Bad Event';
      case ReligiousEntryType.athkar:
        return 'Athkar';
      case ReligiousEntryType.nightPrayer:
        return 'Night Prayer';
    }
  }
}
