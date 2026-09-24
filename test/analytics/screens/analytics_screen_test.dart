import 'package:abdalsalam/features/analytics/screens/analytics_screen.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam/shared/services/achievement_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp(AchievementService achievementService) {
    return ProviderScope(
      overrides: [
        achievementServiceProvider.overrideWithValue(achievementService),
      ],
      child: const MaterialApp(home: AnalyticsScreen()),
    );
  }

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1200, 4000);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  testWidgets('renders achievement milestones from the achievement service', (tester) async {
    await tester.pumpWidget(buildApp(AchievementService()));
    await tester.pumpAndSettle();

    expect(find.text('30-Day Prayer Streak'), findsOneWidget);
    expect(find.text('100 Workouts Logged'), findsOneWidget);
    expect(find.text('90% Todo Completion'), findsOneWidget);
    expect(find.text('0/30'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('reflects the achievement service current progress', (tester) async {
    final achievementService = AchievementService()..increment('30_day_prayer_streak', by: 12);

    await tester.pumpWidget(buildApp(achievementService));
    await tester.pumpAndSettle();

    expect(find.text('12/30'), findsOneWidget);
  });
}
