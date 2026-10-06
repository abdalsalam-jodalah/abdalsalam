import 'package:abdalsalam/features/dashboard/services/daily_quote_selector.dart';
import 'package:abdalsalam/features/dashboard/widgets/dashboard_quote_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _today = DateTime(2026, 10, 6, 9);

Widget _host({bool prefersArabic = false}) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: DashboardQuoteCard(prefersArabic: prefersArabic, clock: () => _today)),
        ),
      ),
    );

String _textOf(WidgetTester tester, String key) {
  return tester.widget<Text>(find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(Text))).data!;
}

void main() {
  testWidgets('shows the quote of the day in Arabic and English with its source', (tester) async {
    await tester.pumpWidget(_host());
    final expected = DailyQuoteSelector.forDate(_today);

    expect(find.text('Quote of the day'), findsOneWidget);
    expect(_textOf(tester, 'quote-arabic'), expected.arabic);
    expect(_textOf(tester, 'quote-english'), expected.english);
    expect(_textOf(tester, 'quote-source'), '— ${expected.sourceEnglish}');
  });

  testWidgets('shows the English quote first by default and the Arabic first when preferred', (tester) async {
    await tester.pumpWidget(_host());
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('quote-english'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('quote-arabic'))).dy),
    );

    await tester.pumpWidget(_host(prefersArabic: true));
    await tester.pump();

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('quote-arabic'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('quote-english'))).dy),
    );
    expect(_textOf(tester, 'quote-source'), '— ${DailyQuoteSelector.forDate(_today).sourceArabic}');
  });

  testWidgets('renders the Arabic text right to left and the English text left to right', (tester) async {
    await tester.pumpWidget(_host());

    expect(
      tester.widget<Directionality>(find.descendant(of: find.byKey(const ValueKey('quote-arabic')), matching: find.byType(Directionality)).first).textDirection,
      TextDirection.rtl,
    );
    expect(
      tester.widget<Directionality>(find.descendant(of: find.byKey(const ValueKey('quote-english')), matching: find.byType(Directionality)).first).textDirection,
      TextDirection.ltr,
    );
  });

  testWidgets('swaps the language order when the translate button is pressed', (tester) async {
    await tester.pumpWidget(_host());

    await tester.tap(find.byKey(const ValueKey('quote-translate')));
    await tester.pump();

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('quote-arabic'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('quote-english'))).dy),
    );
  });

  testWidgets('shows a different quote when next is pressed', (tester) async {
    await tester.pumpWidget(_host());
    final first = _textOf(tester, 'quote-english');

    await tester.tap(find.byKey(const ValueKey('quote-next')));
    await tester.pump();

    expect(_textOf(tester, 'quote-english'), isNot(first));
    expect(_textOf(tester, 'quote-english'), DailyQuoteSelector.forDate(_today, shift: 1).english);
  });

  testWidgets('labels the quote with its category', (tester) async {
    await tester.pumpWidget(_host());
    final category = DailyQuoteSelector.forDate(_today).category.label;

    expect(find.text(' · $category'), findsOneWidget);
  });

  testWidgets('does not overflow with the longest quote on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(prefersArabic: true));
    for (var index = 0; index < 60; index++) {
      await tester.tap(find.byKey(const ValueKey('quote-next')));
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
  });
}
