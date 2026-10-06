import 'package:abdalsalam/features/dashboard/widgets/dashboard_age_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, DateTime Function() clock) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: DashboardAgeCard(clock: clock))));
}

void main() {
  testWidgets('shows the age breakdown and the totals', (tester) async {
    await _pump(tester, () => DateTime(2002, 10, 3, 18, 30));

    expect(find.text('My age'), findsOneWidget);
    expect(find.text('Total days'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('3,030'), findsOneWidget);
  });

  testWidgets('shows years, days, hours and minutes since the last birthday', (tester) async {
    await _pump(tester, () => DateTime(2026, 10, 6, 18, 45));

    expect(find.text('24'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
    for (final label in ['Years', 'Days', 'Hours', 'Minutes']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('refreshes when the timer ticks', (tester) async {
    var now = DateTime(2026, 10, 6, 18, 45);
    await _pump(tester, () => now);
    expect(find.text('45'), findsOneWidget);

    now = DateTime(2026, 10, 6, 18, 46);
    await tester.pump(const Duration(seconds: 10));

    expect(find.text('46'), findsOneWidget);
  });
}
