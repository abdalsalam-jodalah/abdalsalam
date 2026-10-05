// test/sync/sync_report_screen_test.dart — widget tests for the sync report: totals, modules, empty state and warnings.

import 'package:abdalsalam/core/constants/sync_ui_text.dart';
import 'package:abdalsalam/features/sync/screens/sync_report_screen.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sync_report_factory.dart';

void main() {
  late int reloadCount;

  Future<void> pumpReport(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appReloadProvider.overrideWithValue(() => reloadCount++)],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => reloadCount = 0);

  testWidgets('should show totals, module breakdown and details for a transferring sync', (tester) async {
    await pumpReport(tester, SyncReportScreen(report: SyncReportFactory.transferred()));

    expect(find.text(SyncUiText.totalsSection), findsOneWidget);
    expect(find.text(SyncUiText.modulesSection), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Financial'), findsOneWidget);
    expect(find.text(SyncUiText.upToDateLabel), findsOneWidget);
    expect(find.text('5 s'), findsOneWidget);
    expect(find.text('/backups/pre-sync.zip'), findsOneWidget);
    expect(find.text(SyncUiText.emptyReportTitle), findsNothing);
    expect(find.text(SyncUiText.clockSkewWarning), findsNothing);
  });

  testWidgets('should expand a module tile to its full counts', (tester) async {
    await pumpReport(tester, SyncReportScreen(report: SyncReportFactory.transferred()));

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    expect(find.text(SyncUiText.conflictsLabel), findsWidgets);
    expect(find.text('2.0 KB'), findsWidgets);
  });

  testWidgets('should show the empty state when nothing needed transferring', (tester) async {
    await pumpReport(tester, SyncReportScreen(report: SyncReportFactory.empty()));

    expect(find.text(SyncUiText.emptyReportTitle), findsOneWidget);
    expect(find.text(SyncUiText.totalsSection), findsNothing);
    expect(find.text(SyncUiText.reloadAppLabel), findsNothing);
  });

  testWidgets('should warn when the device clocks are far apart', (tester) async {
    await pumpReport(
      tester,
      SyncReportScreen(report: SyncReportFactory.transferred(clockSkew: const Duration(minutes: 10))),
    );

    expect(find.text(SyncUiText.clockSkewWarning), findsOneWidget);
  });

  testWidgets('should offer an app reload when the sync changed local data', (tester) async {
    await pumpReport(tester, SyncReportScreen(report: SyncReportFactory.transferred()));

    await tester.ensureVisible(find.text(SyncUiText.reloadAppLabel));
    await tester.tap(find.text(SyncUiText.reloadAppLabel));
    await tester.pump();

    expect(reloadCount, 1);
  });
}
