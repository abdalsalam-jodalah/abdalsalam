// lib/core/constants/adb_constants.dart — executable names, search paths and output tokens used to drive adb.

class AdbConstants {
  const AdbConstants._();

  static const String adbExecutable = 'adb';
  static const String whichExecutable = 'which';
  static const String homeEnvironmentKey = 'HOME';

  static const List<String> absoluteSearchPaths = <String>['/usr/local/bin/adb', '/opt/homebrew/bin/adb'];
  static const String homeRelativeSearchPath = 'Library/Android/sdk/platform-tools/adb';
  static const String pathSeparator = '/';

  static const String devicesCommand = 'devices';
  static const String serialFlag = '-s';
  static const String reverseCommand = 'reverse';
  static const String removeFlag = '--remove';
  static const String tcpPrefix = 'tcp:';

  static const String devicesHeaderPrefix = 'List of devices';
  static const String daemonLinePrefix = '*';
  static const String deviceState = 'device';
  static const String unauthorizedState = 'unauthorized';
  static const String offlineState = 'offline';

  static const Duration commandTimeout = Duration(seconds: 10);
}
