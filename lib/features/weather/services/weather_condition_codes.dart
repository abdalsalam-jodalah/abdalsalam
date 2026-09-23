class WeatherConditionCodes {
  static const String unknownDescription = 'Unknown';
  static const String defaultIcon = '01d';

  static const Map<int, String> _descriptions = <int, String>{
    0: 'Clear sky',
    1: 'Partly cloudy',
    2: 'Partly cloudy',
    3: 'Partly cloudy',
    45: 'Fog',
    48: 'Fog',
    51: 'Drizzle',
    53: 'Drizzle',
    55: 'Drizzle',
    61: 'Rain',
    63: 'Rain',
    65: 'Rain',
    71: 'Snow',
    73: 'Snow',
    75: 'Snow',
    80: 'Rain showers',
    81: 'Rain showers',
    82: 'Rain showers',
    95: 'Thunderstorm',
  };

  static const Map<int, String> _icons = <int, String>{
    0: '01d',
    1: '02d',
    2: '02d',
    3: '02d',
    45: '50d',
    48: '50d',
    51: '09d',
    53: '09d',
    55: '09d',
    61: '10d',
    63: '10d',
    65: '10d',
    71: '13d',
    73: '13d',
    75: '13d',
    80: '09d',
    81: '09d',
    82: '09d',
    95: '11d',
  };

  const WeatherConditionCodes._();

  static String describe(int? code) => _descriptions[code] ?? unknownDescription;

  static String iconFor(int? code) => _icons[code] ?? defaultIcon;
}
