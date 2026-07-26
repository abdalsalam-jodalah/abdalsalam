import 'package:abdalsalam/features/health/screens/health_home_screen.dart';
import 'package:abdalsalam/features/health/screens/health_screen.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await StorageGateway.instance.initialize(databaseName: 'test_abdalsalam.db');
    await DatabaseSchemaInitializer.initialize(StorageGateway.instance);
    for (final table in ['medications', 'medication_logs', 'blood_tests', 'health_metrics', 'doctor_visits']) {
      await StorageGateway.instance.clearTable(table);
    }
  });

  testWidgets('health home dashboard renders with no data', (tester) async {
    final appStateManager = logic.AppStateManagerImpl.create(
      config: const logic.AppStateConfig(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStateManagerProvider.overrideWithValue(appStateManager),
        ],
        child: const MaterialApp(home: HealthHomeScreen()),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
    }

    expect(find.text('Health Home'), findsOneWidget);
    expect(find.text('No medications scheduled today.'), findsOneWidget);
    expect(find.text('No metrics logged yet.'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();

    expect(find.text('No recent activity yet.'), findsOneWidget);
  });

  testWidgets('health hub has a bottom nav bar and switches tabs', (tester) async {
    final appStateManager = logic.AppStateManagerImpl.create(
      config: const logic.AppStateConfig(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStateManagerProvider.overrideWithValue(appStateManager),
        ],
        child: const MaterialApp(home: HealthScreen()),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
    }

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);

    await tester.tap(find.text('Medications'));
    await tester.pump();
    expect(find.text('Daily Checklist'), findsOneWidget);

    await tester.tap(find.text('Blood Tests'));
    await tester.pump();
    expect(find.text('No blood tests logged yet. Tap + to add one.'), findsOneWidget);
  });
}
