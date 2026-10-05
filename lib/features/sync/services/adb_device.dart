// lib/features/sync/services/adb_device.dart — one device row reported by `adb devices`.

import 'package:equatable/equatable.dart';

enum AdbDeviceState { ready, unauthorized, offline, other }

class AdbDevice extends Equatable {
  final String serial;
  final AdbDeviceState state;

  const AdbDevice({required this.serial, required this.state});

  @override
  List<Object?> get props => [serial, state];
}
