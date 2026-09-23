import '../../shared/infrastructure/crash_log_recorder.dart';

class StartupErrorDetails {
  static const int _recentCrashEntryCount = 20;

  const StartupErrorDetails();

  Future<String> build(Object startupError, StackTrace? stackTrace) async {
    final crashEntries = await CrashLogRecorder.instance.readEntries();
    final recentEntries = crashEntries.length > _recentCrashEntryCount
        ? crashEntries.sublist(crashEntries.length - _recentCrashEntryCount)
        : crashEntries;
    final details = StringBuffer()
      ..writeln('Startup failure: $startupError')
      ..writeln(stackTrace ?? '')
      ..writeln('--- Recent saved errors ---')
      ..writeAll(recentEntries, '\n');
    return details.toString();
  }
}
