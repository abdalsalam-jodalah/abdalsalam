import 'package:abdalsalam/data/models/weather/weather_model.dart';
import 'package:abdalsalam/features/weather/widgets/weather_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WeatherModel weatherOf({required bool isStale}) => WeatherModel(
        cityName: 'Nablus',
        temperature: 21,
        feelsLike: 20,
        humidity: 40,
        windSpeed: 3.2,
        description: 'clear sky',
        icon: '01d',
        timestamp: DateTime(2026, 1, 1),
        isStale: isStale,
      );

  Widget host(WeatherModel weather) => MaterialApp(
        home: Scaffold(body: WeatherWidget(weather: weather)),
      );

  testWidgets('should show the offline hint when the weather data is stale', (tester) async {
    await tester.pumpWidget(host(weatherOf(isStale: true)));
    await tester.pump();

    expect(find.text('Offline — showing saved weather'), findsOneWidget);
  });

  testWidgets('should hide the offline hint when the weather data is fresh', (tester) async {
    await tester.pumpWidget(host(weatherOf(isStale: false)));
    await tester.pump();

    expect(find.text('Offline — showing saved weather'), findsNothing);
  });
}
