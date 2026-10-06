import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/services/notification_diagnostic_check.dart';
import '../../../shared/services/notification_diagnostics_report.dart';

Future<void> showNotificationDiagnosticsDialog(BuildContext context, WidgetRef ref) {
  final service = ref.read(notificationDiagnosticsServiceProvider);
  return showDialog<void>(
    context: context,
    builder: (_) => NotificationDiagnosticsDialog(report: service.run()),
  );
}

class NotificationDiagnosticsDialog extends StatelessWidget {
  static const String title = 'Notification test';
  static const String _runningMessage = 'Running checks…';
  static const String _closeLabel = 'Close';
  static const String _healthyFooter =
      'All checks passed. A test notification should arrive in about a minute. If it does not, check that the app '
      'is not restricted in the battery settings.';
  static const String _unhealthyFooter = 'Some checks failed. The details above say what to fix.';

  final Future<NotificationDiagnosticsReport> report;

  const NotificationDiagnosticsDialog({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<NotificationDiagnosticsReport>(
          future: report,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('The test could not run: ${snapshot.error}');
            }
            final result = snapshot.data;
            if (result == null) {
              return const _RunningIndicator();
            }
            return _ReportBody(report: result);
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(_closeLabel))],
    );
  }
}

class _RunningIndicator extends StatelessWidget {
  const _RunningIndicator();

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return Row(
      children: [
        const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: spacing.md),
        const Text(NotificationDiagnosticsDialog._runningMessage),
      ],
    );
  }
}

class _ReportBody extends StatelessWidget {
  final NotificationDiagnosticsReport report;

  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final check in report.checks) _CheckRow(check: check),
          SizedBox(height: spacing.md),
          Text(
            report.isHealthy
                ? NotificationDiagnosticsDialog._healthyFooter
                : NotificationDiagnosticsDialog._unhealthyFooter,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final NotificationDiagnosticCheck check;

  const _CheckRow({required this.check});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        check.isPassed ? Icons.check_circle_rounded : Icons.error_rounded,
        color: check.isPassed ? colorScheme.primary : colorScheme.error,
      ),
      title: Text(check.title),
      subtitle: Text(check.detail),
    );
  }
}
