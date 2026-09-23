import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../shared/infrastructure/logger_service.dart';
import 'friendly_error_widget.dart';

class GlobalErrorHandlers {
  const GlobalErrorHandlers._();

  static LoggerService get _logger => LoggerService.forModule('GlobalErrors');

  static void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _logger.error(
        'Flutter framework error: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      reportUncaughtError(error, stackTrace, source: 'platform');
      return true;
    };
    ErrorWidget.builder = (details) => FriendlyErrorWidget(details: details);
  }

  static void reportUncaughtError(Object error, StackTrace stackTrace, {required String source}) {
    _logger.error('Uncaught $source error', error: error, stackTrace: stackTrace);
  }
}
