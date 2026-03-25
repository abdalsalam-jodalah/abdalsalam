import 'package:flutter/material.dart';

import '../widgets/health_widgets.dart';
import 'blood_tests_screen.dart';
import 'health_metrics_screen.dart';
import 'medication_form_screen.dart';
import 'medication_list_screen.dart';

class HealthHomeScreen extends StatelessWidget {
  static const routeName = '/health/home';

  const HealthHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(MedicationFormScreen.routeName),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Medication'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(MedicationListScreen.routeName),
                  icon: const Icon(Icons.medication_outlined),
                  label: const Text('Medication List'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Today Schedule', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const MedicationScheduleCard(medicationName: 'Vitamin D', schedule: '08:00 AM • Daily'),
          const MedicationScheduleCard(medicationName: 'Omega 3', schedule: '08:00 PM • Daily'),
          const SizedBox(height: 12),
          Text('Adherence', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: AdherenceRateWidget(value: 92.0),
            ),
          ),
          const SizedBox(height: 12),
          Text('Metrics Trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const HealthMetricChart(points: [78, 77.9, 77.8, 77.7, 77.8]),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Open Metrics'),
                onPressed: () => Navigator.of(context).pushNamed(HealthMetricsScreen.routeName),
              ),
              ActionChip(
                label: const Text('Blood Tests'),
                onPressed: () => Navigator.of(context).pushNamed(BloodTestsScreen.routeName),
              ),
              const RefillReminderBadge(daysLeft: 3),
            ],
          ),
        ],
      ),
    );
  }
}
