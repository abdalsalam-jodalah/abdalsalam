// lib/features/sync/services/adb_reverse_command.dart — builds the adb reverse arguments and the manual command text.

import '../../../core/constants/adb_constants.dart';

class AdbReverseCommand {
  const AdbReverseCommand._();

  static List<String> add(int port, {String? serial}) {
    return <String>[..._target(serial), AdbConstants.reverseCommand, _tcp(port), _tcp(port)];
  }

  static List<String> remove(int port, {String? serial}) {
    return <String>[..._target(serial), AdbConstants.reverseCommand, AdbConstants.removeFlag, _tcp(port)];
  }

  static String manualText(int port) {
    return <String>[AdbConstants.adbExecutable, AdbConstants.reverseCommand, _tcp(port), _tcp(port)].join(' ');
  }

  static List<String> _target(String? serial) {
    return serial == null ? const <String>[] : <String>[AdbConstants.serialFlag, serial];
  }

  static String _tcp(int port) => '${AdbConstants.tcpPrefix}$port';
}
