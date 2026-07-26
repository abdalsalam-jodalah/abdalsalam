import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/health/health_metric.dart';
import 'blood_test_service.dart';
import 'doctor_visit_service.dart';
import 'health_metric_service.dart';
import 'medication_service.dart';

/// Builds a shareable PDF summary of medications, metrics, blood tests, and
/// doctor visits, intended for handing to a physician.
class HealthReportService {
  static const _lookbackWindow = Duration(days: 180);

  final MedicationService medicationService;
  final HealthMetricService healthMetricService;
  final BloodTestService bloodTestService;
  final DoctorVisitService doctorVisitService;

  HealthReportService({
    required this.medicationService,
    required this.healthMetricService,
    required this.bloodTestService,
    required this.doctorVisitService,
  });

  Future<Uint8List> generateReport() async {
    final medications = (await medicationService.getMedicationsSorted()).data ?? [];
    final metrics = (await healthMetricService.getActive()).data ?? [];
    final bloodTests = (await bloodTestService.getActive()).data ?? [];
    final visits = (await doctorVisitService.getActive()).data ?? [];

    final cutoff = DateTime.now().subtract(_lookbackWindow);

    final activeMedications = medications.where((m) => m.isActive).toList();

    final latestMetricByType = <String, HealthMetric>{};
    for (final metric in metrics) {
      final current = latestMetricByType[metric.metricType];
      if (current == null || metric.measuredAt.isAfter(current.measuredAt)) {
        latestMetricByType[metric.metricType] = metric;
      }
    }

    final recentBloodTests = bloodTests
        .where((test) => (test.completedDate ?? test.scheduledDate).isAfter(cutoff))
        .toList()
      ..sort((a, b) =>
          (b.completedDate ?? b.scheduledDate).compareTo(a.completedDate ?? a.scheduledDate));

    final recentVisits = visits.where((visit) => visit.visitDate.isAfter(cutoff)).toList()
      ..sort((a, b) => b.visitDate.compareTo(a.visitDate));

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: 'Health Report'),
          pw.Text('Generated: ${_formatDate(DateTime.now())}'),
          pw.SizedBox(height: 16),
          pw.Header(level: 1, text: 'Active Medications'),
          if (activeMedications.isEmpty)
            pw.Text('None')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Name', 'Dosage', 'Frequency', 'Timing'],
              data: activeMedications
                  .map((m) => [m.name, m.dosage, m.frequency, m.timingLabel])
                  .toList(),
            ),
          pw.SizedBox(height: 16),
          pw.Header(level: 1, text: 'Latest Metrics'),
          if (latestMetricByType.isEmpty)
            pw.Text('None')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Type', 'Value', 'Unit', 'Measured'],
              data: latestMetricByType.values
                  .map((m) => [m.metricType, m.value.toString(), m.unit, _formatDate(m.measuredAt)])
                  .toList(),
            ),
          pw.SizedBox(height: 16),
          pw.Header(level: 1, text: 'Blood Tests (last 6 months)'),
          if (recentBloodTests.isEmpty)
            pw.Text('None')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Test', 'Date', 'Status', 'Results'],
              data: recentBloodTests
                  .map((t) => [
                        t.testType,
                        _formatDate(t.completedDate ?? t.scheduledDate),
                        t.completedDate != null ? 'Completed' : 'Scheduled',
                        t.results.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                      ])
                  .toList(),
            ),
          pw.SizedBox(height: 16),
          pw.Header(level: 1, text: 'Doctor Visits (last 6 months)'),
          if (recentVisits.isEmpty)
            pw.Text('None')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Doctor', 'Date', 'Reason', 'Diagnosis'],
              data: recentVisits
                  .map((v) => [v.doctorName, _formatDate(v.visitDate), v.reason, v.diagnosis ?? '-'])
                  .toList(),
            ),
        ],
      ),
    );

    return document.save();
  }

  Future<void> shareReport() async {
    final bytes = await generateReport();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'health_report_${_formatDate(DateTime.now())}.pdf',
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
