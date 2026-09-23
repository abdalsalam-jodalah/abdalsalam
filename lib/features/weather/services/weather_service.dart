import 'package:http/http.dart' as http;

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/weather/weather_model.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../../shared/services/error_handler.dart';
import 'open_meteo_response_parser.dart';

class WeatherService {
  static const String _serviceName = 'WeatherService';
  static const String _cityName = 'Nablus';
  static const String _forecastScheme = 'https';
  static const String _forecastHost = 'api.open-meteo.com';
  static const String _forecastPath = '/v1/forecast';
  static const Map<String, String> _forecastQuery = <String, String>{
    'latitude': '32.2211',
    'longitude': '35.2544',
    'current_weather': 'true',
    'hourly': 'temperature_2m,relative_humidity_2m,weathercode,wind_speed_10m',
    'timezone': 'auto',
  };
  static const String _weatherKey = 'weather_data';
  static const String _lastUpdateKey = 'weather_last_update';
  static const String _preferencesSource = 'preferences';
  static const String _iconUrlPrefix = 'https://openweathermap.org/img/wn/';
  static const String _iconUrlSuffix = '@2x.png';
  static const Duration _cacheExpiry = Duration(hours: 1);
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const int _httpOk = 200;

  final LoggerService _logger;
  final StorageGateway _storage;
  final http.Client _httpClient;
  final DateTime Function() _clock;
  final OpenMeteoResponseParser _parser = const OpenMeteoResponseParser(cityName: _cityName);

  WeatherModel? _cachedWeather;
  DateTime? _lastUpdate;
  Future<void>? _cacheLoad;

  WeatherService(
    this._logger,
    this._storage, {
    http.Client? httpClient,
    DateTime Function()? clock,
  })  : _httpClient = httpClient ?? http.Client(),
        _clock = clock ?? DateTime.now;

  ErrorHandler get _errorHandler => ErrorHandler(_logger);

  Uri get _forecastUri => Uri(
        scheme: _forecastScheme,
        host: _forecastHost,
        path: _forecastPath,
        queryParameters: _forecastQuery,
      );

  Future<Result<WeatherModel, AppError>> getWeatherForNablus() async {
    await _ensureCacheLoaded();
    final cached = _cachedWeather;
    if (cached != null && _isCacheValid()) {
      _logger.info('[$_serviceName] using cached weather data');
      return Success(cached);
    }

    final fetched = await _fetchFromNetwork();
    if (fetched.isSuccess) {
      return fetched;
    }
    return _fallbackToCache(fetched.error!);
  }

  Future<Result<void, AppError>> initialize() async {
    final weather = await getWeatherForNablus();
    return weather.map<void>((_) {});
  }

  Future<Result<WeatherModel, AppError>> refresh() {
    return getWeatherForNablus();
  }

  String getWeatherIconUrl(String icon) {
    return '$_iconUrlPrefix$icon$_iconUrlSuffix';
  }

  Future<Result<WeatherModel, AppError>> _fetchFromNetwork() async {
    try {
      _logger.info('[$_serviceName] fetching weather data for $_cityName (Open-Meteo)');
      final response = await _httpClient.get(_forecastUri).timeout(_requestTimeout);
      if (response.statusCode != _httpOk) {
        final error = NetworkError('Weather API returned status ${response.statusCode}');
        _logger.warning('[$_serviceName] ${error.message}');
        return Failure(error);
      }
      final weather = _parser.parse(response.body);
      _cachedWeather = weather;
      _lastUpdate = _clock();
      await _saveToStorage(weather);
      _logger.info('[$_serviceName] weather data updated for $_cityName (Open-Meteo)');
      return Success(weather);
    } catch (error, stackTrace) {
      return Failure(_errorHandler.mapException(error, context: '$_serviceName.getWeatherForNablus', stackTrace: stackTrace));
    }
  }

  Result<WeatherModel, AppError> _fallbackToCache(AppError fetchError) {
    final cached = _cachedWeather;
    if (cached == null) {
      return Failure(fetchError);
    }
    final cachedAt = _lastUpdate?.toIso8601String() ?? 'an unknown time';
    _logger.warning('[$_serviceName] serving stale weather cached at $cachedAt after ${fetchError.code}');
    return Success(cached.copyWith(isStale: true));
  }

  bool _isCacheValid() {
    final lastUpdate = _lastUpdate;
    if (lastUpdate == null) {
      return false;
    }
    return _clock().difference(lastUpdate) < _cacheExpiry;
  }

  Future<void> _ensureCacheLoaded() {
    return _cacheLoad ??= _loadFromStorage();
  }

  Future<void> _saveToStorage(WeatherModel weather) async {
    try {
      await _storage.save(key: _weatherKey, value: weather.toJson());
      await _storage.save(key: _lastUpdateKey, value: _lastUpdate?.toIso8601String());
    } catch (error, stackTrace) {
      _errorHandler.mapException(error, context: '$_serviceName.saveToStorage', stackTrace: stackTrace);
      _logger.warning('[$_serviceName] fresh weather is served but was not cached to storage');
    }
  }

  Future<void> _loadFromStorage() async {
    _cachedWeather = await _readStored(_weatherKey, (value) {
      if (value is! Map<String, dynamic>) {
        throw CorruptDataError('Stored weather is not an object', source: _preferencesSource, field: _weatherKey);
      }
      return WeatherModel.fromJson(value);
    });
    _lastUpdate = await _readStored(_lastUpdateKey, (value) {
      final parsed = value is String ? DateTime.tryParse(value) : null;
      if (parsed == null) {
        throw CorruptDataError('Stored weather update time is invalid', source: _preferencesSource, field: _lastUpdateKey);
      }
      return parsed;
    });
    if (_cachedWeather != null) {
      _logger.info('[$_serviceName] loaded cached weather from storage');
    }
  }

  Future<T?> _readStored<T>(String key, T Function(Object value) decode) async {
    try {
      final value = await _storage.get<Object>(key);
      return value == null ? null : decode(value);
    } on CorruptDataError catch (error, stackTrace) {
      _storage.integrityReporter.reportCorruptRecord(
        table: _preferencesSource,
        recordId: key,
        reason: error,
        stackTrace: stackTrace,
      );
      return null;
    } catch (error, stackTrace) {
      _errorHandler.mapException(error, context: '$_serviceName.loadFromStorage', stackTrace: stackTrace);
      return null;
    }
  }
}

extension WeatherModelExtension on WeatherModel {
  WeatherModel copyWith({
    String? cityName,
    double? temperature,
    double? feelsLike,
    int? humidity,
    double? windSpeed,
    String? description,
    String? icon,
    DateTime? timestamp,
    List<HourlyForecast>? hourlyForecast,
    bool? isStale,
  }) {
    return WeatherModel(
      cityName: cityName ?? this.cityName,
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      timestamp: timestamp ?? this.timestamp,
      hourlyForecast: hourlyForecast ?? this.hourlyForecast,
      isStale: isStale ?? this.isStale,
    );
  }
}
