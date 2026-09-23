import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/user_error_messages.dart';
import '../../../data/models/sports/body_measurement.dart';
import '../../../data/models/sports/exercise.dart';
import '../providers/sports_providers.dart';

const _uuid = Uuid();

enum _TimePeriod { day, week, month }

class SportsDashboardScreen extends ConsumerStatefulWidget {
  static const routeName = '/sports/dashboard';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [SportsScreen] shell.
  final bool embedded;

  const SportsDashboardScreen({super.key, this.embedded = false});

  @override
  ConsumerState<SportsDashboardScreen> createState() => _SportsDashboardScreenState();
}

class _SportsDashboardScreenState extends ConsumerState<SportsDashboardScreen> {
  _TimePeriod _period = _TimePeriod.week;
  String? _selectedCategoryId;
  String? _selectedExerciseId;

  DateRangeQuery _dateRange() {
    final now = dateOnly(DateTime.now());
    switch (_period) {
      case _TimePeriod.day:
        return (start: now, end: now);
      case _TimePeriod.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (start: start, end: now);
      case _TimePeriod.month:
        return (start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.embedded)
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 12),
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          _buildActivityChart(),
          const SizedBox(height: 24),
          _buildCategorySection(),
          const SizedBox(height: 24),
          _buildBodyWeightSection(),
        ],
      ),
    );

    if (widget.embedded) {
      return body;
    }
    return Scaffold(appBar: AppBar(title: const Text('Sport Dashboard')), body: body);
  }

  Widget _buildPeriodSelector() {
    return SegmentedButton<_TimePeriod>(
      segments: const [
        ButtonSegment(value: _TimePeriod.day, label: Text('Day')),
        ButtonSegment(value: _TimePeriod.week, label: Text('Week')),
        ButtonSegment(value: _TimePeriod.month, label: Text('Month')),
      ],
      selected: {_period},
      onSelectionChanged: (selection) => setState(() => _period = selection.first),
    );
  }

  Widget _buildActivityChart() {
    final range = _dateRange();
    final logsAsync = ref.watch(logsInRangeProvider(range));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: logsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const Center(child: Text('Failed to load activity')),
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Center(child: Text('No activity for this period'));
                  }
                  final countByDay = <int, int>{};
                  for (final log in logs) {
                    final dayIndex = log.date.difference(range.start).inDays;
                    countByDay[dayIndex] = (countByDay[dayIndex] ?? 0) + 1;
                  }
                  final maxY = countByDay.values.reduce((a, b) => a > b ? a : b).toDouble();
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY + 1,
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) =>
                                Text('${range.start.add(Duration(days: value.toInt())).day}',
                                    style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                        ),
                      ),
                      barGroups: [
                        for (final entry in countByDay.entries)
                          BarChartGroupData(
                            x: entry.key,
                            barRods: [BarChartRodData(toY: entry.value.toDouble(), width: 12)],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    final categoriesAsync = ref.watch(exerciseCategoriesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Category breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Text('Failed to load categories'),
              data: (categories) {
                if (categories.isEmpty) {
                  return const Text('No categories yet — add some in the Library tab.');
                }
                _selectedCategoryId ??= categories.first.id;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<String>(
                      value: _selectedCategoryId,
                      isExpanded: true,
                      items: [
                        for (final category in categories)
                          DropdownMenuItem(value: category.id, child: Text(category.name)),
                      ],
                      onChanged: (value) => setState(() {
                        _selectedCategoryId = value;
                        _selectedExerciseId = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedCategoryId != null) _buildCategoryExerciseBreakdown(_selectedCategoryId!),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryExerciseBreakdown(String categoryId) {
    final exercisesAsync = ref.watch(exercisesByCategoryProvider(categoryId));
    final range = _dateRange();
    final logsAsync = ref.watch(logsInRangeProvider(range));

    return exercisesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const Text('Failed to load exercises'),
      data: (exercises) {
        return logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const Text('Failed to load logs'),
          data: (logs) {
            final exerciseIds = exercises.map((exercise) => exercise.id).toSet();
            final countByExercise = <String, int>{};
            for (final log in logs) {
              if (exerciseIds.contains(log.exerciseId)) {
                countByExercise[log.exerciseId] = (countByExercise[log.exerciseId] ?? 0) + 1;
              }
            }

            if (countByExercise.isEmpty) {
              return const Text('No logged sessions for this category in the selected period.');
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final exercise in exercises.where((exercise) => countByExercise.containsKey(exercise.id)))
                  ListTile(
                    dense: true,
                    title: Text(exercise.name),
                    trailing: Text('${countByExercise[exercise.id]}x'),
                    selected: _selectedExerciseId == exercise.id,
                    onTap: () => setState(() => _selectedExerciseId = exercise.id),
                  ),
                if (_selectedExerciseId != null) ...[
                  const SizedBox(height: 12),
                  _buildExerciseProgressionChart(_selectedExerciseId!, exercises),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildExerciseProgressionChart(String exerciseId, List<Exercise> exercises) {
    Exercise? exercise;
    for (final item in exercises) {
      if (item.id == exerciseId) {
        exercise = item;
        break;
      }
    }
    if (exercise == null) {
      return const SizedBox.shrink();
    }
    final resolvedExercise = exercise;
    final range = (
      start: DateTime.now().subtract(const Duration(days: 90)),
      end: DateTime.now(),
    );

    if (exercise.trackingType == ExerciseTrackingType.cardio) {
      final logsAsync = ref.watch(
        logsForExerciseInRangeProvider((exerciseId: exerciseId, start: range.start, end: range.end)),
      );
      return logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Text('Failed to load progression'),
        data: (logs) {
          final spots = [
            for (final log in logs)
              if (log.steps != null)
                FlSpot(log.date.difference(range.start).inDays.toDouble(), log.steps!.toDouble()),
          ];
          return _progressionChart('${resolvedExercise.name} — steps', spots);
        },
      );
    }

    final setsAsync = ref.watch(
      setsForExerciseInRangeProvider((exerciseId: exerciseId, start: range.start, end: range.end)),
    );
    return setsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const Text('Failed to load progression'),
      data: (sets) {
        final spots = [
          for (final set in sets)
            if (set.weightKg != null)
              FlSpot(set.createdAt.difference(range.start).inDays.toDouble(), set.weightKg!),
        ];
        return _progressionChart('${resolvedExercise.name} — weight (kg)', spots);
      },
    );
  }

  Widget _progressionChart(String title, List<FlSpot> spots) {
    if (spots.isEmpty) {
      return Text('No data yet for $title.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              titlesData: const FlTitlesData(show: false),
              lineBarsData: [
                LineChartBarData(spots: spots, isCurved: true, barWidth: 3, dotData: const FlDotData(show: true)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyWeightSection() {
    final range = (start: DateTime.now().subtract(const Duration(days: 90)), end: DateTime.now());
    final measurementsAsync = ref.watch(bodyMeasurementsInRangeProvider(range));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Body weight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _showAddMeasurementDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Log weight'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            measurementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Text('Failed to load measurements'),
              data: (measurements) {
                if (measurements.isEmpty) {
                  return const Text('No body-weight entries yet.');
                }
                final sorted = [...measurements]..sort((a, b) => a.date.compareTo(b.date));
                final spots = [
                  for (final entry in sorted)
                    FlSpot(entry.date.difference(range.start).inDays.toDouble(), entry.weightKg),
                ];
                return SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
                      titlesData: const FlTitlesData(show: false),
                      lineBarsData: [
                        LineChartBarData(spots: spots, isCurved: true, barWidth: 3, color: Colors.teal),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMeasurementDialog() async {
    // Height rarely changes, so prefill it from the last entry that recorded
    // one (looked up over a wide window) — the user only has to type it once.
    final longRange = (start: DateTime.now().subtract(const Duration(days: 1095)), end: DateTime.now());
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

    final result = await showDialog<_MeasurementDialogResult>(
      context: context,
      builder: (_) => _MeasurementDialogContent(lastHeight: lastHeight),
    );

    if (result == null) return;

    final service = ref.read(bodyMeasurementServiceProvider);
    final now = DateTime.now();
    final createResult = await service.create(
      BodyMeasurement(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
        userId: sportUserId,
        date: dateOnly(now),
        weightKg: result.weight,
        heightCm: result.height,
        bodyFatPercent: result.bodyFat,
        chestCm: result.chest,
        waistCm: result.waist,
        abdominalCm: result.abdominal,
        hipsCm: result.hips,
        thighCm: result.thigh,
        armCm: result.arm,
      ),
    );
    if (!mounted) {
      return;
    }
    if (createResult.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UserErrorMessages.generic), backgroundColor: Colors.red),
      );
    }
    ref.invalidate(bodyMeasurementsInRangeProvider);
  }
}

class _MeasurementDialogResult {
  _MeasurementDialogResult({
    required this.weight,
    required this.height,
    required this.bodyFat,
    required this.chest,
    required this.waist,
    required this.abdominal,
    required this.hips,
    required this.thigh,
    required this.arm,
  });

  final double weight;
  final double? height;
  final double? bodyFat;
  final double? chest;
  final double? waist;
  final double? abdominal;
  final double? hips;
  final double? thigh;
  final double? arm;
}

class _MeasurementDialogContent extends StatefulWidget {
  const _MeasurementDialogContent({required this.lastHeight});

  final double? lastHeight;

  @override
  State<_MeasurementDialogContent> createState() => _MeasurementDialogContentState();
}

class _MeasurementDialogContentState extends State<_MeasurementDialogContent> {
  final formKey = GlobalKey<FormState>();
  final weightController = TextEditingController();
  late final TextEditingController heightController;
  final bodyFatController = TextEditingController();
  final chestController = TextEditingController();
  final waistController = TextEditingController();
  final abdominalController = TextEditingController();
  final hipsController = TextEditingController();
  final thighController = TextEditingController();
  final armController = TextEditingController();

  @override
  void initState() {
    super.initState();
    heightController = TextEditingController(text: widget.lastHeight?.toString() ?? '');
  }

  @override
  void dispose() {
    weightController.dispose();
    heightController.dispose();
    bodyFatController.dispose();
    chestController.dispose();
    waistController.dispose();
    abdominalController.dispose();
    hipsController.dispose();
    thighController.dispose();
    armController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Body Measurements'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                validator: (value) => (value == null || double.tryParse(value) == null) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Height (cm, one-time)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bodyFatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Body fat % (optional)', border: OutlineInputBorder()),
              ),
              const Divider(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Circumference (cm, optional)', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: chestController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Chest', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: waistController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Waist', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: abdominalController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Abdominal', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: hipsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Hips', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: thighController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Leg (thigh)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: armController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Arm', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                _MeasurementDialogResult(
                  weight: double.parse(weightController.text),
                  height: double.tryParse(heightController.text),
                  bodyFat: double.tryParse(bodyFatController.text),
                  chest: double.tryParse(chestController.text),
                  waist: double.tryParse(waistController.text),
                  abdominal: double.tryParse(abdominalController.text),
                  hips: double.tryParse(hipsController.text),
                  thigh: double.tryParse(thighController.text),
                  arm: double.tryParse(armController.text),
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
