import 'package:abdalsalam/data/models/financial/exchange_rate_model.dart';
import 'package:abdalsalam/features/financial/widgets/currency_rates_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<ExchangeRateModel> _history(double from, double to) {
  final start = DateTime(2026, 1, 1);
  return [
    for (var day = 0; day < 5; day++)
      ExchangeRateModel(
        id: 'h$from-$day',
        fromCurrency: 'ILS',
        toCurrency: 'X',
        rate: from + (to - from) * day / 4,
        date: start.add(Duration(days: day)),
        createdAt: start,
        updatedAt: start,
      ),
  ];
}

Widget _host({Map<String, double>? rates, bool withHistory = true}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CurrencyRatesWidget(
            currentRates: rates ?? const {'USD': 0.25, 'JOD': 0.2},
            usdHistory: withHistory ? _history(0.25, 0.2) : const [],
            jodHistory: withHistory ? _history(0.2, 0.2) : const [],
          ),
        ),
      ),
    );

void main() {
  testWidgets('shows foreign currency first as ILS and the ILS inverse underneath', (tester) async {
    await tester.pumpWidget(_host());

    expect(find.text('1 USD = 4.000 ILS'), findsOneWidget);
    expect(find.text('1 ILS = 0.2500 USD'), findsOneWidget);
    expect(find.text('1 JOD = 5.000 ILS'), findsOneWidget);
    expect(find.text('1 ILS = 0.2000 JOD'), findsOneWidget);
  });

  testWidgets('shows a dash instead of dividing by zero when a rate is missing', (tester) async {
    await tester.pumpWidget(_host(rates: const {'USD': 0.25}, withHistory: false));

    expect(find.text('1 JOD = —'), findsOneWidget);
    expect(find.text('1 ILS = —'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the 30 day trend in ILS per unit', (tester) async {
    await tester.pumpWidget(_host());

    expect(find.text('+25.0%'), findsOneWidget);
    expect(find.text('+0.0%'), findsOneWidget);
  });

  testWidgets('keeps at least one currency selected on the chart', (tester) async {
    await tester.pumpWidget(_host());

    await tester.tap(find.byKey(const ValueKey('rate-headline-USD')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('rate-headline-JOD')));
    await tester.pump();

    expect(find.byKey(const ValueKey('rates-chart-[JOD]')), findsOneWidget);
  });

  testWidgets('does not overflow on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host());

    expect(tester.takeException(), isNull);
  });
}
