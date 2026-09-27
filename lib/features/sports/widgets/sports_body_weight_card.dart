import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../shared/widgets/charts/app_line_chart.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/async_section.dart';
import '../providers/sports_providers.dart';
import 'sports_measurement_dialog.dart';

/// A [ConsumerStatefulWidget] rather than a stateless [ConsumerWidget] so
/// [ref] stays bound to a stable [State] across the `await` calls in
/// [_showAddMeasurementDialog].
class SportsBodyWeightCard extends ConsumerStatefulWidget {
  const SportsBodyWeightCard({super.key});

  @override
  ConsumerState<SportsBodyWeightCard> createState() => _SportsBodyWeightCardState();
}

class _SportsBodyWeightCardState extends ConsumerState<SportsBodyWeightCard> {
  static const String _title = 'Body weight';
  static const String _logWeightLabel = 'Log weight';
  static const String _emptyMessage = 'No body-weight entries yet.';
  static const double _chartHeight = 160;
  static const int _heightLookbackDays = 1095;
  static const int _windowDays = 90;

  DateRangeQuery get _range {
    final today = dateOnly(DateTime.now());
    return (start: today.subtract(const Duration(days: _windowDays)), end: today);
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    final measurementsAsync = ref.watch(bodyMeasurementsInRangeProvider(range));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: _title,
            padding: EdgeInsets.zero,
            action: TextButton.icon(
              onPressed: _showAddMeasurementDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text(_logWeightLabel),
            ),
          ),
          AsyncSection(
            value: measurementsAsync,
            onRetry: () => ref.invalidate(bodyMeasurementsInRangeProvider(range)),
            builder: (measurements) {
              if (measurements.isEmpty) {
                return Text(_emptyMessage, style: Theme.of(context).textTheme.bodyMedium);
              }
              final sorted = [...measurements]..sort((a, b) => a.date.compareTo(b.date));
              return AppLineChart(
                points: [for (final entry in sorted) entry.weightKg],
                color: AppModuleAccents.forModule('sports'),
                height: _chartHeight,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMeasurementDialog() async {
    final longRange = (
      start: DateTime.now().subtract(const Duration(days: _heightLookbackDays)),
      end: DateTime.now(),
    );
    final history = await ref.read(bodyMeasurementsInRangeProvider(longRange).future);
    final sortedHistory = [...history]..sort((a, b) => b.date.compareTo(a.date));
    double? lastHeight;
    for (final entry in sortedHistory) {
      lastHeight = entry.heightCm;
      break;
    }

    if (!mounted) {
      return;
    }

    await showSportsMeasurementDialog(context, ref: ref, lastHeight: lastHeight);
  }
}
