import 'package:flutter/foundation.dart';

class LoggerService {
  const LoggerService();

  void info(String message) {
    debugPrint('[INFO] $message');
  }

  void warning(String message) {
    debugPrint('[WARN] $message');
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('[ERROR] $message');
    if (error != null) {
      debugPrint('[ERROR] Details: $error');
    }
    if (stackTrace != null) {
      debugPrint('[ERROR] Stack: $stackTrace');
    }
  }
}
