import 'dart:async';

import 'package:flutter/foundation.dart';

class SidebarAutoCloseTimer {
  static const String settingKey = 'sidebarAutoCloseSeconds';
  static const int defaultSeconds = 10;

  final VoidCallback onTimeout;
  Duration? _timeout = const Duration(seconds: defaultSeconds);
  bool _isRunning = false;
  Timer? _timer;

  SidebarAutoCloseTimer({required this.onTimeout});

  static Duration? durationFromSetting(Object? value) {
    final seconds = value is num ? value.toInt() : defaultSeconds;
    return seconds > 0 ? Duration(seconds: seconds) : null;
  }

  void configure(Duration? timeout) {
    _timeout = timeout;
    if (_isRunning) {
      _schedule();
    }
  }

  void start() {
    _isRunning = true;
    _schedule();
  }

  void touch() {
    if (_isRunning) {
      _schedule();
    }
  }

  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();

  void _schedule() {
    _timer?.cancel();
    final timeout = _timeout;
    if (timeout == null) {
      _timer = null;
      return;
    }
    _timer = Timer(timeout, () {
      _timer = null;
      onTimeout();
    });
  }
}
