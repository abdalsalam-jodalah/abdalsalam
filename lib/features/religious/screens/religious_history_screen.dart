import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/religious/religious_entry.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/religious_tracking_providers.dart';

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Religious History'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final state = ref.watch(religiousLogsControllerProvider);

    return Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                ...ReligiousEntryType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_typeLabel(type)),
                      selected: _filter == type,
                      onSelected: (_) => setState(() => _filter = type),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.when(
              data: (logs) {
                final filtered = _filter == null
                    ? logs
                    : logs.where((entry) => entry.type == _filter).toList(growable: false);

                if (filtered.isEmpty) {
                  return const EmptyState(
                    title: 'No history yet',
                    subtitle: 'Entries you log across the religious module will show up here.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final color = _colorForType(context, item.type);
                    return Card(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_iconForType(item.type), color: color, size: 20),
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          '${DateFormat('yyyy-MM-dd hh:mm a').format(item.loggedAt)}\n${item.details ?? ''}',
                        ),
                        isThreeLine: item.details != null && item.details!.trim().isNotEmpty,
                        trailing: Text('x${item.count}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
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

  static IconData _iconForType(ReligiousEntryType type) {
    switch (type) {
      case ReligiousEntryType.prayer:
        return Icons.mosque_outlined;
      case ReligiousEntryType.quranReading:
        return Icons.menu_book_outlined;
      case ReligiousEntryType.badEvent:
        return Icons.warning_amber_outlined;
      case ReligiousEntryType.athkar:
        return Icons.favorite_outline;
      case ReligiousEntryType.nightPrayer:
        return Icons.nights_stay_outlined;
    }
  }

  static Color _colorForType(BuildContext context, ReligiousEntryType type) {
    final scheme = Theme.of(context).colorScheme;
    switch (type) {
      case ReligiousEntryType.prayer:
      case ReligiousEntryType.nightPrayer:
        return scheme.primary;
      case ReligiousEntryType.quranReading:
        return scheme.secondary;
      case ReligiousEntryType.athkar:
        return scheme.tertiary;
      case ReligiousEntryType.badEvent:
        return scheme.error;
    }
  }
}
