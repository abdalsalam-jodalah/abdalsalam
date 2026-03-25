import 'package:flutter/material.dart';

class MedicationScheduleCard extends StatelessWidget {
  final String medicationName;
  final String schedule;

  const MedicationScheduleCard({
    super.key,
    required this.medicationName,
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.medication_outlined),
        title: Text(medicationName),
        subtitle: Text(schedule),
      ),
    );
  }
}

class AdherenceRateWidget extends StatelessWidget {
  final double value;

  const AdherenceRateWidget({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Adherence: ${value.toStringAsFixed(1)}%'),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: (value / 100).clamp(0, 1)),
      ],
    );
  }
}

class HealthMetricChart extends StatelessWidget {
  final List<double> points;

  const HealthMetricChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Metric points: ${points.length}'),
      ),
    );
  }
}

class RefillReminderBadge extends StatelessWidget {
  final int daysLeft;

  const RefillReminderBadge({super.key, required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.warning_amber_outlined),
      label: Text('Refill in $daysLeft days'),
    );
  }
}
