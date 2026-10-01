import 'package:abdalsalam/features/settings/screens/backup_screen.dart';
import 'package:abdalsalam/features/settings/screens/data_management_screen.dart';
import 'package:abdalsalam/features/settings/screens/export_data_screen.dart';
import 'package:abdalsalam/features/settings/screens/restore_screen.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/backup_status.dart';
import 'package:abdalsalam/shared/services/settings_service.dart';
import 'package:abdalsalam/shared/services/module_table_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService() : super(StorageGateway.instance);

  @override
  Future<Map<String, dynamic>> getSettings() async => <String, dynamic>{};
}

void main() {
  final pushedRoutes = <String>[];

  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget host({Map<DataModule, int> counts = const {}}) {
    return ProviderScope(
      overrides: [
        recordCountsByModuleProvider.overrideWith((ref) async => counts),
        settingsServiceProvider.overrideWithValue(_FakeSettingsService()),
        backupStatusProvider.overrideWith((ref) async => const BackupStatus()),
      ],
      child: MaterialApp(
        home: const DataManagementScreen(),
        onGenerateRoute: (settings) {
          pushedRoutes.add(settings.name!);
          return MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('pushed')), settings: settings);
        },
      ),
    );
  }

  setUp(pushedRoutes.clear);

  testWidgets('should show how many records each module holds', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(host(counts: {DataModule.financial: 12, DataModule.religious: 340}));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Financial'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('340'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'System'), findsNothing);
  });

  testWidgets('should open the backup screen', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back up now'));
    await tester.pumpAndSettle();

    expect(pushedRoutes, [BackupScreen.routeName]);
  });

  testWidgets('should open the restore screen', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore from backup'));
    await tester.pumpAndSettle();

    expect(pushedRoutes, [RestoreScreen.routeName]);
  });

  testWidgets('should open the export screen', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export for analysis'));
    await tester.pumpAndSettle();

    expect(pushedRoutes, [ExportDataScreen.routeName]);
  });
}

