import 'dart:typed_data';

import 'package:abdalsalam/core/constants/user_error_messages.dart';
import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/features/settings/screens/export_data_screen.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/module_export.dart';
import 'package:abdalsalam/shared/services/module_export_service.dart';
import 'package:abdalsalam/shared/services/module_table_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeModuleExportService extends ModuleExportService {
  final Result<ModuleExport, AppError> exportResult;
  final Result<String?, AppError> saveResult;
  Set<DataModule>? requestedModules;
  bool? requestedIncludeDeleted;
  bool wasShared = false;

  _FakeModuleExportService({
    required this.exportResult,
    this.saveResult = const Success('/Download/export.zip'),
  }) : super(StorageGateway.instance, LoggerService.forModule('FakeModuleExportService'));

  @override
  Future<Result<ModuleExport, AppError>> export({required Set<DataModule> modules, bool includeDeleted = false}) async {
    requestedModules = modules;
    requestedIncludeDeleted = includeDeleted;
    return exportResult;
  }

  @override
  Future<Result<String?, AppError>> saveExportAs(ModuleExport export) async => saveResult;

  @override
  Future<Result<void, AppError>> shareExport(ModuleExport export) async {
    wasShared = true;
    return const Success(null);
  }
}

final _sampleExport = ModuleExport(
  bytes: Uint8List(1),
  fileName: 'abdalsalam-export-20261001-0905.zip',
  recordCountByModule: const {},
);

void main() {
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget host(ModuleExportService service) {
    return ProviderScope(
      overrides: [
        moduleExportServiceProvider.overrideWithValue(service),
        recordCountsByModuleProvider.overrideWith((ref) async => {DataModule.financial: 7}),
      ],
      child: const MaterialApp(home: ExportDataScreen()),
    );
  }

  testWidgets('should list modules that can be exported with their record counts, but not security or system', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(host(_FakeModuleExportService(exportResult: Success(_sampleExport))));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(CheckboxListTile, 'Financial'), findsOneWidget);
    expect(find.text('7 records'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'Security'), findsNothing);
    expect(find.widgetWithText(CheckboxListTile, 'System'), findsNothing);
  });

  testWidgets('should export every module without deleted records by default', (tester) async {
    useTallScreen(tester);
    final service = _FakeModuleExportService(exportResult: Success(_sampleExport));
    await tester.pumpWidget(host(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save to device'));
    await tester.pumpAndSettle();

    expect(service.requestedModules, ModuleTableRegistry.readableExportModules.toSet());
    expect(service.requestedIncludeDeleted, isFalse);
    expect(find.text('Export saved: /Download/export.zip'), findsOneWidget);
  });

  testWidgets('should export only the modules left checked and include deleted records when switched on', (tester) async {
    useTallScreen(tester);
    final service = _FakeModuleExportService(exportResult: Success(_sampleExport));
    await tester.pumpWidget(host(service));
    await tester.pumpAndSettle();

    for (final module in ModuleTableRegistry.readableExportModules.where((module) => module != DataModule.financial)) {
      await tester.tap(find.widgetWithText(CheckboxListTile, module.label));
    }
    await tester.tap(find.widgetWithText(SwitchListTile, 'Include deleted records'));
    await tester.pump();
    await tester.tap(find.text('Save to device'));
    await tester.pumpAndSettle();

    expect(service.requestedModules, {DataModule.financial});
    expect(service.requestedIncludeDeleted, isTrue);
  });

  testWidgets('should disable export when nothing is selected', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(host(_FakeModuleExportService(exportResult: Success(_sampleExport))));
    await tester.pumpAndSettle();

    for (final module in ModuleTableRegistry.readableExportModules) {
      await tester.tap(find.widgetWithText(CheckboxListTile, module.label));
    }
    await tester.pump();

    final button = tester.widget<ButtonStyleButton>(find.ancestor(
      of: find.text('Save to device'),
      matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
    ));
    expect(button.onPressed, isNull);
  });

  testWidgets('should hand the export to the share sheet', (tester) async {
    useTallScreen(tester);
    final service = _FakeModuleExportService(exportResult: Success(_sampleExport));
    await tester.pumpWidget(host(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share export'));
    await tester.pumpAndSettle();

    expect(service.wasShared, isTrue);
    expect(find.text('Export shared successfully'), findsOneWidget);
  });

  testWidgets('should say the save was cancelled when the picker is dismissed', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(host(_FakeModuleExportService(
      exportResult: Success(_sampleExport),
      saveResult: const Success(null),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save to device'));
    await tester.pumpAndSettle();

    expect(find.text('Save cancelled'), findsOneWidget);
  });

  testWidgets('should show the friendly message, not the raw error, when building the export fails', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(host(_FakeModuleExportService(
      exportResult: Failure(DatabaseError('SqfliteException: disk full')),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save to device'));
    await tester.pumpAndSettle();

    expect(find.text(UserErrorMessages.database), findsOneWidget);
    expect(find.textContaining('SqfliteException'), findsNothing);
    expect(find.text('Export failed'), findsOneWidget);
  });
}
