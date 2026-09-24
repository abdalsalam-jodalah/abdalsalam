import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_error.dart';
import '../core/theme/appearance.dart';
import 'app_providers.dart';

final initialAppearanceProvider = Provider<Appearance>((ref) => Appearance.defaults);

final appearanceProvider = NotifierProvider<AppearanceController, Appearance>(AppearanceController.new);

class AppearanceController extends Notifier<Appearance> {
  @override
  Appearance build() => ref.read(initialAppearanceProvider);

  Future<AppError?> update(Appearance next) async {
    if (next == state) {
      return null;
    }
    final previous = state;
    state = next;
    try {
      await ref.read(settingsServiceProvider).updateSettings(next.toSettings());
      ref.invalidate(appSettingsProvider);
      return null;
    } catch (error, stackTrace) {
      state = previous;
      return ref.read(errorHandlerProvider).mapException(
            error,
            context: 'AppearanceController.update',
            stackTrace: stackTrace,
          );
    }
  }

  Future<AppError?> reset() => update(Appearance.defaults);
}
