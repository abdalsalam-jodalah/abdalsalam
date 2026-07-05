import 'package:abdalsalam/features/dashboard/providers/dashboard_providers.dart';
import 'package:abdalsalam/features/dashboard/screens/dashboard_screen.dart';
import 'package:abdalsalam/features/religious/providers/prayer_providers.dart';
import 'package:abdalsalam/features/religious/providers/quran_providers.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dashboard renders', (tester) async {
    final appStateManager = logic.AppStateManagerImpl.create(
      config: const logic.AppStateConfig(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStateManagerProvider.overrideWithValue(appStateManager),
          prayerCountProvider.overrideWithValue(3),
          quranPagesTodayProvider.overrideWithValue(5),
          weatherProvider.overrideWith((ref) async => null),
          currencyRatesProvider.overrideWith((ref) async => <String, double>{}),
          usdHistoryProvider.overrideWith((ref) async => []),
          jodHistoryProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Abdalsalam Dashboard'), findsOneWidget);
    expect(find.text('Religious Tracking status'), findsOneWidget);
    expect(find.text('3 / 5 prayers'), findsOneWidget);
  });
}
