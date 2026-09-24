import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/constants/user_error_messages.dart';
import 'package:abdalsalam/features/dashboard/providers/dashboard_providers.dart';
import 'package:abdalsalam/features/dashboard/screens/dashboard_screen.dart';
import 'package:abdalsalam/features/planning/providers/planning_providers.dart';
import 'package:abdalsalam/features/religious/providers/prayer_providers.dart';
import 'package:abdalsalam/features/religious/providers/quran_providers.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final appStateManager = logic.AppStateManagerImpl.create(
    config: const logic.AppStateConfig(),
  );

  List<Override> baseOverrides() => [
        appStateManagerProvider.overrideWithValue(appStateManager),
        prayerCountProvider.overrideWithValue(0),
        quranPagesTodayProvider.overrideWithValue(0),
      ];

  Widget host(List<Override> overrides) => ProviderScope(
        overrides: [...baseOverrides(), ...overrides],
        child: const MaterialApp(home: DashboardScreen()),
      );

  testWidgets('should show the friendly message and a Retry button when weather fails', (tester) async {
    var weatherCallCount = 0;

    await tester.pumpWidget(host([
      weatherProvider.overrideWith((ref) async {
        weatherCallCount++;
        if (weatherCallCount == 1) {
          throw NetworkError('weather api unreachable');
        }
        return null;
      }),
      currencyRatesProvider.overrideWith((ref) async => <String, double>{}),
      usdHistoryProvider.overrideWith((ref) async => []),
      jodHistoryProvider.overrideWith((ref) async => []),
      todaysGoalsProvider.overrideWith((ref) async => []),
    ]));
    await tester.pump();
    await tester.pump();

    expect(find.text(UserErrorMessages.network), findsOneWidget);
    expect(find.textContaining('weather api unreachable'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(weatherCallCount, 2);
    expect(find.text(UserErrorMessages.network), findsNothing);
  });

  testWidgets('should show the friendly message when exchange rates fail', (tester) async {
    await tester.pumpWidget(host([
      weatherProvider.overrideWith((ref) async => null),
      currencyRatesProvider.overrideWith((ref) async => throw DatabaseError('rates table missing')),
      usdHistoryProvider.overrideWith((ref) async => []),
      jodHistoryProvider.overrideWith((ref) async => []),
      todaysGoalsProvider.overrideWith((ref) async => []),
    ]));
    await tester.pump();
    await tester.pump();

    expect(find.text(UserErrorMessages.database), findsOneWidget);
    expect(find.textContaining('rates table missing'), findsNothing);
  });

  testWidgets('should show the friendly message when today\'s goals fail to load', (tester) async {
    await tester.pumpWidget(host([
      weatherProvider.overrideWith((ref) async => null),
      currencyRatesProvider.overrideWith((ref) async => <String, double>{}),
      usdHistoryProvider.overrideWith((ref) async => []),
      jodHistoryProvider.overrideWith((ref) async => []),
      todaysGoalsProvider.overrideWith((ref) async => throw CorruptDataError('goal row unreadable')),
    ]));
    await tester.pump();
    await tester.pump();

    expect(find.text(UserErrorMessages.corruptData), findsOneWidget);
    expect(find.textContaining('goal row unreadable'), findsNothing);
  });
}
