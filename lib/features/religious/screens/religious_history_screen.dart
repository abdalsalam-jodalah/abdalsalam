import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/religious/religious_entry.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/filter_bar.dart';
import '../../../shared/widgets/ui/filter_option.dart';
import '../../../shared/widgets/ui/page_header.dart';
import '../providers/religious_tracking_providers.dart';
import '../widgets/religious_entry_type_style.dart';

class ReligiousHistoryScreen extends ConsumerStatefulWidget {
  static const routeName = '/religious/history';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [ReligiousScreen] shell.
  final bool embedded;

  const ReligiousHistoryScreen({super.key, this.embedded = false});

  @override
  ConsumerState<ReligiousHistoryScreen> createState() => _ReligiousHistoryScreenState();
}

class _ReligiousHistoryScreenState extends ConsumerState<ReligiousHistoryScreen> {
  ReligiousEntryType? _filter;

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        children: [
          const PageHeader(title: 'History'),
          Expanded(child: _buildBody(context)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Religious History')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final state = ref.watch(religiousLogsControllerProvider);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(tokens.spacing.md),
          child: FilterBar<ReligiousEntryType?>(
            options: [
              const FilterOption(null, 'All'),
              for (final type in ReligiousEntryType.values) FilterOption(type, _typeLabel(type)),
            ],
            selected: _filter,
            onSelected: (value) => setState(() => _filter = value),
          ),
        ),
        Expanded(
          child: state.when(
            data: (logs) {
              final filtered =
                  _filter == null ? logs : logs.where((entry) => entry.type == _filter).toList(growable: false);

              if (filtered.isEmpty) {
                return const EmptyState(
                  title: 'No history yet',
                  subtitle: 'Entries you log across the religious module will show up here.',
                );
              }

              return ListView.separated(
                padding: EdgeInsets.fromLTRB(tokens.spacing.lg, 0, tokens.spacing.lg, tokens.spacing.lg),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => SizedBox(height: tokens.spacing.sm),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return EntityTile(
                    icon: ReligiousEntryTypeStyle.icon(item.type),
                    accentColor: ReligiousEntryTypeStyle.color(context, item.type),
                    title: item.title,
                    subtitle: '${AppDateFormatter.dateTime(item.loggedAt)}'
                        '${item.details != null && item.details!.trim().isNotEmpty ? '\n${item.details}' : ''}',
                    subtitleMaxLines: 3,
                    trailing: Text('x${item.count}', style: Theme.of(context).textTheme.labelMedium),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncErrorView(
              error: error,
              onRetry: () => ref.invalidate(religiousLogsControllerProvider),
            ),
          ),
        ),
      ],
    );
  }

  String _typeLabel(ReligiousEntryType type) {
    switch (type) {
      case ReligiousEntryType.prayer:
        return 'Prayer';
      case ReligiousEntryType.quranReading:
        return 'Quran';
      case ReligiousEntryType.badEvent:
        return 'Bad Event';
      case ReligiousEntryType.athkar:
        return 'Athkar';
      case ReligiousEntryType.nightPrayer:
        return 'Night Prayer';
    }
  }
}
