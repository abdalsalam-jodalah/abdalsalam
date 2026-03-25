import 'dart:async';

import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';

import '../infrastructure/logger_service.dart';

class AppLifecycleLogger {
  final AppStateManager appStateManager;
  final LoggerService logger;

  StreamSubscription<AppStateInfo>? _stateSubscription;

  AppLifecycleLogger({required this.appStateManager, required this.logger});

  void start() {
    logger.info('[Lifecycle] startup');
    _stateSubscription = appStateManager.stateStream.listen((state) {
      logger.info('[Lifecycle] ${state.lifecycle.name} online=${state.isOnline}');
    });
  }

  Future<void> stop() async {
    logger.info('[Lifecycle] terminate');
    await _stateSubscription?.cancel();
  }
}
