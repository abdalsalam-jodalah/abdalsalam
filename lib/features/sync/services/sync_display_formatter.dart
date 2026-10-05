// lib/features/sync/services/sync_display_formatter.dart — turns sync numbers, phases and module keys into display text.

import '../../../core/constants/sync_constants.dart';
import '../../../core/constants/sync_ui_text.dart';
import '../../../data/models/sync/sync_phase.dart';
import '../../../shared/services/module_table_registry.dart';

class SyncDisplayFormatter {
  static const int _bytesPerStep = 1024;
  static const int _millisecondsPerSecond = 1000;
  static const int _secondsPerMinute = 60;
  static const int _singleDecimalThreshold = 10;

  const SyncDisplayFormatter._();

  static String bytes(int value) {
    const units = <String>[
      SyncUiText.byteUnitBytes,
      SyncUiText.byteUnitKilobytes,
      SyncUiText.byteUnitMegabytes,
      SyncUiText.byteUnitGigabytes,
    ];
    var scaled = value.toDouble();
    var unitIndex = 0;
    while (scaled >= _bytesPerStep && unitIndex < units.length - 1) {
      scaled /= _bytesPerStep;
      unitIndex++;
    }
    final text = unitIndex == 0 || scaled >= _singleDecimalThreshold
        ? scaled.toStringAsFixed(0)
        : scaled.toStringAsFixed(1);
    return '$text ${units[unitIndex]}';
  }

  static String duration(Duration value) {
    if (value.inMilliseconds < _millisecondsPerSecond) {
      return '${value.inMilliseconds} ${SyncUiText.millisecondsUnit}';
    }
    final totalSeconds = value.inSeconds;
    if (totalSeconds < _secondsPerMinute) {
      return '$totalSeconds ${SyncUiText.secondsUnit}';
    }
    final minutes = totalSeconds ~/ _secondsPerMinute;
    final seconds = totalSeconds % _secondsPerMinute;
    return '$minutes ${SyncUiText.minutesUnit} $seconds ${SyncUiText.secondsUnit}';
  }

  static String clockOffset(Duration value) => '${value.inSeconds} ${SyncUiText.secondsUnit}';

  static String moduleLabel(String moduleKey) {
    if (moduleKey == SyncConstants.unknownModuleKey) {
      return SyncUiText.otherModuleLabel;
    }
    for (final module in DataModule.values) {
      if (module.name == moduleKey) {
        return module.label;
      }
    }
    return moduleKey;
  }

  static String phase(SyncPhase value) {
    return switch (value) {
      SyncPhase.idle => SyncUiText.phaseIdle,
      SyncPhase.waiting => SyncUiText.phaseWaiting,
      SyncPhase.connecting => SyncUiText.phaseConnecting,
      SyncPhase.comparing => SyncUiText.phaseComparing,
      SyncPhase.sending => SyncUiText.phaseSending,
      SyncPhase.receiving => SyncUiText.phaseReceiving,
      SyncPhase.backingUp => SyncUiText.phaseBackingUp,
      SyncPhase.applying => SyncUiText.phaseApplying,
      SyncPhase.finalizing => SyncUiText.phaseFinalizing,
      SyncPhase.completed => SyncUiText.phaseCompleted,
      SyncPhase.failed => SyncUiText.phaseFailed,
    };
  }
}
