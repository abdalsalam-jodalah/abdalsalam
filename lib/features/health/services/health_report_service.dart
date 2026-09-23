import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/health/blood_test.dart';
import '../../../data/models/health/doctor_visit.dart';
import '../../../data/models/health/health_metric.dart';
import '../../../data/models/health/medication.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/services/error_handler.dart';
import 'blood_test_service.dart';
import 'doctor_visit_service.dart';
import 'health_metric_service.dart';
import 'medication_service.dart';

class HealthReportService {
  static const _lookbackWindow = Duration(days: 180);
  static const _logContext = 'HealthReportService';

  final MedicationService medicationService;
  final HealthMetricService healthMetricService;
  final BloodTestService bloodTestService;
  final DoctorVisitService doctorVisitService;
  final LoggerService logger;

  HealthReportService({
    required this.medicationService,
    required this.healthMetricService,
    required this.bloodTestService,
    required this.doctorVisitService,
    required this.logger,
  });

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  Future<Result<Uint8List, AppError>> generateReport() async {
    try {
      final medicationsResult = await medicationService.getMedicationsSorted();
      if (medicationsResult.isFailure) {
        return Failure(medicationsResult.error!);
      }
      final metricsResult = await healthMetricService.getActive();
      if (metricsResult.isFailure) {
        return Failure(metricsResult.error!);
      }
      final bloodTestsResult = await bloodTestService.getActive();
      if (bloodTestsResult.isFailure) {
        return Failure(bloodTestsResult.error!);
      }
      final visitsResult = await doctorVisitService.getActive();
      if (visitsResult.isFailure) {
        return Failure(visitsResult.error!);
      }

      final bytes = await _buildDocument(
        medications: medicationsResult.data!,
        metrics: metricsResult.data!,
        bloodTests: bloodTestsResult.data!,
        visits: visitsResult.data!,
      );
      return Success(bytes);
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$_logContext.generateReport', stackTrace: st));
    }
  }

  Future<Uint8List> _buildDocument({
    required List<Medication> medications,
    required List<HealthMetric> metrics,
    required List<BloodTest> bloodTests,
    required List<DoctorVisit> visits,
  }) async {
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

  Future<Result<void, AppError>> shareReport() async {
    final reportResult = await generateReport();
    if (reportResult.isFailure) {
      return Failure(reportResult.error!);
    }
    try {
      await Printing.sharePdf(
        bytes: reportResult.data!,
        filename: 'health_report_${_formatDate(DateTime.now())}.pdf',
      );
      return const Success(null);
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$_logContext.shareReport', stackTrace: st));
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
