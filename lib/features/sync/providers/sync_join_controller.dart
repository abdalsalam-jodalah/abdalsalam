// lib/features/sync/providers/sync_join_controller.dart — runs the phone-side sync: validates the PIN, joins the Mac, tracks progress.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/sync_constants.dart';
import '../../../core/constants/sync_ui_text.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/sync/sync_progress_event.dart';
import '../../../data/models/sync/sync_session_report.dart';
import '../services/sync_errors.dart';
import 'sync_join_state.dart';
import 'sync_providers.dart';

class SyncJoinController extends Notifier<SyncJoinState> {
  static final RegExp _pinPattern = RegExp(
    r'^\d{'
    '${SyncConstants.pinLength}'
    r'}$',
  );

  StreamSubscription<SyncProgressEvent>? _progressSubscription;

  @override
  SyncJoinState build() {
    final session = ref.watch(syncSessionServiceProvider);
    _progressSubscription = session.progress.listen(_onProgress);
    ref.onDispose(() => unawaited(_progressSubscription?.cancel()));
    return const SyncJoinState();
  }

  Future<Result<SyncSessionReport, AppError>> join(String pin) async {
    if (state.isJoining) {
      return Failure(SyncSessionBusyError());
    }
    final trimmedPin = pin.trim();
    if (!_pinPattern.hasMatch(trimmedPin)) {
      return Failure(
        ValidationError(
          SyncUiText.invalidPinMessage,
          fieldErrors: const <String, String>{SyncUiText.pinFieldKey: SyncUiText.invalidPinMessage},
        ),
      );
    }
    state = state.copyWith(isJoining: true, clearProgress: true);
    final outcome = await ref.read(syncSessionServiceProvider).joinHost(pin: trimmedPin);
    state = state.copyWith(isJoining: false, lastReport: outcome.data);
    return outcome;
  }

  void _onProgress(SyncProgressEvent event) {
    if (state.isJoining) {
      state = state.copyWith(progress: event);
    }
  }
}
