// lib/features/sync/services/adb_device_parser.dart — turns `adb devices` output into typed devices.

import '../../../core/constants/adb_constants.dart';
import 'adb_device.dart';

class AdbDeviceParser {
  static final RegExp _columnSeparator = RegExp(r'\s+');
  static const int _minimumColumns = 2;

  const AdbDeviceParser();

  List<AdbDevice> parse(String output) {
    final devices = <AdbDevice>[];
    for (final rawLine in output.split('\n')) {
      final line = rawLine.trim();
      if (_isIgnorable(line)) {
        continue;
      }
      final columns = line.split(_columnSeparator);
      if (columns.length < _minimumColumns) {
        continue;
      }
      devices.add(AdbDevice(serial: columns.first, state: _stateOf(columns[1])));
    }
    return devices;
  }

  bool _isIgnorable(String line) {
    return line.isEmpty ||
        line.startsWith(AdbConstants.devicesHeaderPrefix) ||
        line.startsWith(AdbConstants.daemonLinePrefix);
  }

  AdbDeviceState _stateOf(String token) {
    return switch (token) {
      AdbConstants.deviceState => AdbDeviceState.ready,
      AdbConstants.unauthorizedState => AdbDeviceState.unauthorized,
      AdbConstants.offlineState => AdbDeviceState.offline,
      _ => AdbDeviceState.other,
    };
  }
}
