import 'package:abdalsalam/features/settings/screens/backup_screen.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam/shared/widgets/backup_reminder_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pushedRoutes = <String>[];

  Widget host(int? daysOverdue) {
    final navigatorKey = GlobalKey<NavigatorState>();
    return ProviderScope(
      overrides: [backupReminderDaysProvider.overrideWith((ref) async => daysOverdue)],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        onGenerateRoute: (settings) {
          pushedRoutes.add(settings.name!);
          return MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('pushed')), settings: settings);
        },
        builder: (context, child) => Column(
          children: [
            BackupReminderBanner(navigatorKey: navigatorKey),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        ),
        home: const Scaffold(body: Text('home')),
      ),
    );
  }

  setUp(pushedRoutes.clear);

  testWidgets('should stay hidden when no backup is due', (tester) async {
    await tester.pumpWidget(host(null));
    await tester.pumpAndSettle();

    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('should say how many days have passed when a backup is overdue', (tester) async {
    await tester.pumpWidget(host(9));
    await tester.pumpAndSettle();

    expect(find.text(BackupReminderBanner.messageFor(9)), findsOneWidget);
    expect(find.textContaining('9 days'), findsOneWidget);
  });

  testWidgets('should use the singular for one day', (tester) async {
    await tester.pumpWidget(host(1));
    await tester.pumpAndSettle();

    expect(find.textContaining('for 1 day.'), findsOneWidget);
  });

  testWidgets('should open the backup screen from the banner', (tester) async {
    await tester.pumpWidget(host(9));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back up'));
    await tester.pumpAndSettle();

    expect(pushedRoutes, contains(BackupScreen.routeName));
  });

  testWidgets('should hide when dismissed', (tester) async {
    await tester.pumpWidget(host(9));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Back up'), findsNothing);
  });
}
