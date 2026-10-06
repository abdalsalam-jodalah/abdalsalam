import 'package:abdalsalam/data/models/weather/weather_model.dart';
import 'package:abdalsalam/features/weather/widgets/weather_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WeatherModel _weather({String icon = '01d', double temperature = 21}) => WeatherModel(
      cityName: 'Nablus',
      temperature: temperature,
      feelsLike: temperature - 1,
      humidity: 40,
      windSpeed: 3.2,
      description: 'Clear sky',
      icon: icon,
      timestamp: DateTime(2026, 1, 1, 12),
      hourlyForecast: [
        HourlyForecast(
          time: DateTime(2026, 1, 1, 15),
          temperature: 15,
          description: 'Rain',
          icon: '10d',
          humidity: 80,
          windSpeed: 6,
        ),
        HourlyForecast(
          time: DateTime(2026, 1, 1, 22),
          temperature: 9,
          description: 'Clear sky',
          icon: '01n',
          humidity: 60,
          windSpeed: 1,
        ),
      ],
    );

Widget _host(WeatherModel weather, {bool initiallyExpanded = false, VoidCallback? onRefresh}) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: WeatherWidget(weather: weather, initiallyExpanded: initiallyExpanded, onRefresh: onRefresh),
          ),
        ),
      ),
    );

void main() {
  testWidgets('shows the city, temperature, description and advice', (tester) async {
    await tester.pumpWidget(_host(_weather()));

    expect(find.text('Nablus'), findsOneWidget);
    expect(find.text('21°C'), findsOneWidget);
    expect(find.text('Clear sky'), findsOneWidget);
    expect(find.text('A good day to be outside'), findsOneWidget);
  });

  testWidgets('hides the details until the card is tapped and hides them again', (tester) async {
    await tester.pumpWidget(_host(_weather()));
    expect(find.text('Humidity'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('weather-hero')));
    await tester.pump();
    expect(find.text('Humidity'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('weather-toggle-details')));
    await tester.pump();
    expect(find.text('Humidity'), findsNothing);
  });

  testWidgets('starts expanded when asked to', (tester) async {
    await tester.pumpWidget(_host(_weather(), initiallyExpanded: true));

    expect(find.text('Humidity'), findsOneWidget);
    expect(find.byKey(const ValueKey('weather-hour-0')), findsOneWidget);
  });

  testWidgets('selecting an hour shows that hour then returns to now', (tester) async {
    await tester.pumpWidget(_host(_weather(), initiallyExpanded: true));

    await tester.tap(find.byKey(const ValueKey('weather-hour-0')));
    await tester.pump();

    expect(find.text('15°C'), findsOneWidget);
    expect(find.text('Rain'), findsWidgets);
    expect(find.text('Rain expected — take an umbrella'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('weather-hour-now')));
    await tester.pump();

    expect(find.text('21°C'), findsOneWidget);
    expect(find.text('A good day to be outside'), findsOneWidget);
  });

  testWidgets('tapping the selected hour again returns to now', (tester) async {
    await tester.pumpWidget(_host(_weather(), initiallyExpanded: true));

    await tester.tap(find.byKey(const ValueKey('weather-hour-1')));
    await tester.pump();
    expect(find.text('9°C'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('weather-hour-1')));
    await tester.pump();
    expect(find.text('21°C'), findsOneWidget);
  });

  testWidgets('reflects the weather status in the advice and icon', (tester) async {
    await tester.pumpWidget(_host(_weather(icon: '11d', temperature: 18)));
    expect(find.text('Thunderstorm — stay indoors if you can'), findsOneWidget);
    expect(find.byIcon(Icons.thunderstorm_rounded), findsOneWidget);

    await tester.pumpWidget(_host(_weather(icon: '13d', temperature: 1)));
    await tester.pump();
    expect(find.byIcon(Icons.ac_unit_rounded), findsOneWidget);

    await tester.pumpWidget(_host(_weather(icon: '01n')));
    await tester.pump();
    expect(find.byIcon(Icons.nightlight_round), findsOneWidget);
    expect(find.text('A calm night'), findsOneWidget);
  });

  testWidgets('calls refresh when the refresh button is pressed', (tester) async {
    var refreshCount = 0;
    await tester.pumpWidget(_host(_weather(), onRefresh: () => refreshCount++));

    await tester.tap(find.byTooltip('Refresh weather'));

    expect(refreshCount, 1);
  });

  testWidgets('does not overflow on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(_weather(), initiallyExpanded: true));

    expect(tester.takeException(), isNull);
  });
}
