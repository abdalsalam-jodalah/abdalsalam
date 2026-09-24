import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/health/doctor_visit.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../providers/health_providers.dart';
import 'doctor_visit_form_screen.dart';

class DoctorVisitsScreen extends ConsumerStatefulWidget {
  static const routeName = '/health/doctor-visits';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [HealthScreen] shell.
  final bool embedded;

  const DoctorVisitsScreen({super.key, this.embedded = false});

  @override
  ConsumerState<DoctorVisitsScreen> createState() => _DoctorVisitsScreenState();
}

class _DoctorVisitsScreenState extends ConsumerState<DoctorVisitsScreen> {
  Future<void> _delete(DoctorVisit visit) async {
    final service = ref.read(doctorVisitServiceProvider);
    final result = await service.deleteWithAttachments(visit.id);
    if (!mounted) return;
    if (result.isFailure) {
      AppFeedback.showError(context, result.error!);
      return;
    }
    ref.invalidate(doctorVisitsProvider);
    ref.invalidate(doctorVisitStatisticsProvider);
  }

  Future<void> _openForm({DoctorVisit? visit}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => DoctorVisitFormScreen(visit: visit)),
    );
    if (!mounted) return;
    if (saved == true) {
      ref.invalidate(doctorVisitsProvider);
      ref.invalidate(doctorVisitStatisticsProvider);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final visitsAsync = ref.watch(doctorVisitsProvider);

    final content = visitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(doctorVisitsProvider),
      ),
      data: (visits) {
        if (visits.isEmpty) {
          return const Center(child: Text('No doctor visits logged yet. Tap + to add one.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.embedded)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Doctor Visits',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ...visits.map((visit) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.medical_services_outlined),
                    title: Text(visit.doctorName),
                    subtitle: Text(
                      '${visit.specialty != null ? '${visit.specialty} • ' : ''}${_formatDate(visit.visitDate)}\n'
                      '${visit.reason}'
                      '${visit.medicationIds.isNotEmpty ? '\n${visit.medicationIds.length} medication(s) prescribed' : ''}',
                    ),
                    isThreeLine: true,
                    onTap: () => _openForm(visit: visit),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(visit),
                    ),
                  ),
                )),
          ],
        );
      },
    );
    final fab = FloatingActionButton(
      onPressed: () => _openForm(),
      child: const Icon(Icons.add),
    );

    if (widget.embedded) {
      return Stack(
        children: [
          content,
          Positioned(right: 16, bottom: 16, child: fab),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Visits')),
      floatingActionButton: fab,
      body: content,
    );
  }
}
