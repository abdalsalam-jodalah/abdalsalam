// lib/features/sync/services/adb_status.dart — what the Mac currently knows about adb and the connected phone.

import 'package:equatable/equatable.dart';

enum AdbStatusKind { adbMissing, commandFailed, noDevice, offline, unauthorized, ready }

class AdbStatus extends Equatable {
  final AdbStatusKind kind;
  final String? deviceSerial;
  final String? adbPath;
  final String? detail;

  const AdbStatus._(this.kind, {this.deviceSerial, this.adbPath, this.detail});

  const AdbStatus.adbMissing() : this._(AdbStatusKind.adbMissing);

  const AdbStatus.commandFailed({String? adbPath, String? detail})
    : this._(AdbStatusKind.commandFailed, adbPath: adbPath, detail: detail);

  const AdbStatus.noDevice({required String adbPath}) : this._(AdbStatusKind.noDevice, adbPath: adbPath);

  const AdbStatus.offline({required String adbPath}) : this._(AdbStatusKind.offline, adbPath: adbPath);

  const AdbStatus.unauthorized({required String adbPath}) : this._(AdbStatusKind.unauthorized, adbPath: adbPath);

  const AdbStatus.ready({required String deviceSerial, required String adbPath})
    : this._(AdbStatusKind.ready, deviceSerial: deviceSerial, adbPath: adbPath);

  bool get isReady => kind == AdbStatusKind.ready;

  bool get isAdbAvailable => kind != AdbStatusKind.adbMissing && kind != AdbStatusKind.commandFailed;

  @override
  List<Object?> get props => [kind, deviceSerial, adbPath, detail];
}
