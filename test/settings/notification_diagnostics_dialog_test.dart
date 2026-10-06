import 'package:abdalsalam/features/settings/widgets/notification_diagnostics_dialog.dart';
import 'package:abdalsalam/shared/services/notification_diagnostic_check.dart';
import 'package:abdalsalam/shared/services/notification_diagnostics_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Future<NotificationDiagnosticsReport> report) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: NotificationDiagnosticsDialog(report: report))));
}

void main() {
  testWidgets('shows each check with its detail and the healthy footer', (tester) async {
    await _pump(
      tester,
      Future.value(
        const NotificationDiagnosticsReport([
          NotificationDiagnosticCheck(title: 'Schedule a notification', isPassed: true, detail: 'Scheduled'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Schedule a notification'), findsOneWidget);
    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.textContaining('All checks passed'), findsOneWidget);
  });

  testWidgets('shows the failure detail and the unhealthy footer', (tester) async {
    await _pump(
      tester,
      Future.value(
        const NotificationDiagnosticsReport([
          NotificationDiagnosticCheck(title: 'Show a notification now', isPassed: false, detail: 'Missing type parameter'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Missing type parameter'), findsOneWidget);
    expect(find.textContaining('Some checks failed'), findsOneWidget);
  });
}
