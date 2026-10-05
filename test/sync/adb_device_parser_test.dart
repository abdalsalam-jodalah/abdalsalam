// test/sync/adb_device_parser_test.dart — verifies `adb devices` output parsing for every device state.

import 'package:abdalsalam/features/sync/services/adb_device.dart';
import 'package:abdalsalam/features/sync/services/adb_device_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = AdbDeviceParser();

  test('should return no devices when only the header is present', () {
    final devices = parser.parse('List of devices attached\n\n');

    expect(devices, isEmpty);
  });

  test('should parse ready, unauthorized and offline devices', () {
    const output =
        'List of devices attached\n'
        'R58M123ABC\tdevice\n'
        'emulator-5554\toffline\n'
        '0123456789\tunauthorized\n';

    final devices = parser.parse(output);

    expect(devices, const [
      AdbDevice(serial: 'R58M123ABC', state: AdbDeviceState.ready),
      AdbDevice(serial: 'emulator-5554', state: AdbDeviceState.offline),
      AdbDevice(serial: '0123456789', state: AdbDeviceState.unauthorized),
    ]);
  });

  test('should ignore daemon start lines and keep detail columns out of the state', () {
    const output =
        '* daemon not running; starting now at tcp:5037\n'
        '* daemon started successfully\n'
        'List of devices attached\n'
        'R58M123ABC          device usb:1-1 product:x model:Pixel transport_id:3\n';

    final devices = parser.parse(output);

    expect(devices, const [AdbDevice(serial: 'R58M123ABC', state: AdbDeviceState.ready)]);
  });

  test('should map unknown states to other', () {
    final devices = parser.parse('List of devices attached\nabc\trecovery\n');

    expect(devices.single.state, AdbDeviceState.other);
  });
}
