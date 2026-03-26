import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/religious/religious_entry.dart';
import '../providers/religious_tracking_providers.dart';

class ReligiousHistoryScreen extends ConsumerStatefulWidget {
  static const routeName = '/religious/history';

  const ReligiousHistoryScreen({super.key});

  @override
  ConsumerState<ReligiousHistoryScreen> createState() => _ReligiousHistoryScreenState();
}

class _ReligiousHistoryScreenState extends ConsumerState<ReligiousHistoryScreen> {
  ReligiousEntryType? _filter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(religiousLogsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Religious History'),
      ),
      body: Column(
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
                  return const Center(child: Text('No history yet.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Card(
                      child: ListTile(
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
      ),
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
