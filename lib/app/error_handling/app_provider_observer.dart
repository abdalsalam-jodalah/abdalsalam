import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/infrastructure/logger_service.dart';

class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    LoggerService.forModule('Providers').error(
      'Provider ${provider.name ?? provider.runtimeType} failed',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
