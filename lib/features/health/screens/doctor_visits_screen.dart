import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/health/doctor_visit.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/page_header.dart';
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

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule('health');
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
          children: [
            if (widget.embedded) const PageHeader(title: 'Doctor Visits'),
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spacing.lg,
                widget.embedded ? 0 : tokens.spacing.lg,
                tokens.spacing.lg,
                tokens.spacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final visit in visits) ...[
                    EntityTile(
                      icon: Icons.medical_services_outlined,
                      accentColor: accent,
                      title: visit.doctorName,
                      subtitle: '${visit.specialty != null ? '${visit.specialty} • ' : ''}${AppDateFormatter.date(visit.visitDate)}\n'
                          '${visit.reason}'
                          '${visit.medicationIds.isNotEmpty ? '\n${visit.medicationIds.length} medication(s) prescribed' : ''}',
                      subtitleMaxLines: 3,
                      onTap: () => _openForm(visit: visit),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(visit),
                      ),
                    ),
                    SizedBox(height: tokens.spacing.sm),
                  ],
                ],
              ),
            ),
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
          Positioned(right: tokens.spacing.lg, bottom: tokens.spacing.lg, child: fab),
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
