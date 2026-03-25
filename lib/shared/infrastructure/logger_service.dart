import 'package:flutter/foundation.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';

class LoggerService {
  final Logger _logger;

  LoggerService._(this._logger);

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    LoggerImpl.initialize(
      const LogConfig(
        coreConfig: LoggerCoreConfig(
          environment: LogEnvironment.development,
          environmentLevels: <LogEnvironment, LogLevel>{
            LogEnvironment.development: LogLevel.debug,
            LogEnvironment.profile: LogLevel.info,
            LogEnvironment.release: LogLevel.warning,
          },
          targetsPerEnvironment: <LogEnvironment, Set<LogTarget>>{
            LogEnvironment.development: <LogTarget>{LogTarget.console, LogTarget.memory},
            LogEnvironment.profile: <LogTarget>{LogTarget.console, LogTarget.memory},
            LogEnvironment.release: <LogTarget>{LogTarget.console, LogTarget.memory},
          },
          allowUnregisteredModules: true,
          strictMode: false,
        ),
        moduleConfig: LoggerModuleRegistryConfig(
          globalLevel: LogLevel.debug,
          enableColors: true,
          modules: <String, LogModuleConfig>{},
        ),
      ),
    );

    _initialized = true;
  }

  factory LoggerService.forModule(
    String moduleName, {
    ModuleType moduleType = ModuleType.other,
  }) {
    if (!_initialized) {
      debugPrint('[WARN] LoggerService used before initialize. Falling back.');
      return LoggerService._(_FallbackLogger(moduleName));
    }

    final module = LogModule(moduleName: moduleName, moduleType: moduleType);
    return LoggerService._(LoggerImpl.forModule(module));
  }

  factory LoggerService.global() {
    return LoggerService.forModule('App', moduleType: ModuleType.service);
  }

  void info(String message) {
    _logger.info(() => message);
  }

  void debug(String message) {
    _logger.debug(() => message);
  }

  void warning(String message) {
    _logger.warning(() => message);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.error(() => message, error, stackTrace);
  }

  List<String> exportLogs({int? recentCount}) {
    final output = LoggerImpl.getMemoryOutput();
    if (output == null) {
      return const <String>[];
    }
    if (recentCount == null) {
      return output.getLogs();
    }
    return output.getRecentLogs(recentCount);
  }
}

class _FallbackLogger implements Logger {
  final String moduleName;

  const _FallbackLogger(this.moduleName);

  @override
  LogModule get module => LogModule(moduleName: moduleName, moduleType: ModuleType.other);

  @override
  void trace(String Function() messageBuilder, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[TRACE][$moduleName] ${messageBuilder()}');
  }

  @override
  void debug(String Function() messageBuilder, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[DEBUG][$moduleName] ${messageBuilder()}');
  }

  @override
  void info(String Function() messageBuilder, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[INFO][$moduleName] ${messageBuilder()}');
  }

  @override
  void warning(String Function() messageBuilder, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[WARN][$moduleName] ${messageBuilder()}');
  }

  @override
  void error(String Function() messageBuilder, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[ERROR][$moduleName] ${messageBuilder()}');
    if (error != null) {
      debugPrint('[ERROR][$moduleName] Details: $error');
    }
    if (stackTrace != null) {
      debugPrint('[ERROR][$moduleName] Stack: $stackTrace');
    }
  }

  @override
  void fatal(String Function() messageBuilder, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[FATAL][$moduleName] ${messageBuilder()}');
  }

  @override
  void log(LogLevel level, String Function() messageBuilder, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[${level.displayName}][$moduleName] ${messageBuilder()}');
  }
}
