import 'package:abdalsalam/shared/infrastructure/crash_log_recorder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final recorder = CrashLogRecorder.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await recorder.clearEntries();
  });

  group('CrashLogRecorder', () {
    test('should persist an error entry with module, message, and error', () async {
      recorder.record(moduleName: 'Finance', message: 'save failed', error: StateError('boom'));

      final entries = await recorder.readEntries();

      expect(entries, hasLength(1));
      expect(entries.single, contains('[ERROR] [Finance] save failed'));
      expect(entries.single, contains('boom'));
    });

    test('should keep only the most recent entries', () async {
      for (var i = 0; i < CrashLogRecorder.maxEntries + 5; i++) {
        recorder.record(moduleName: 'M', message: 'entry $i');
      }

      final entries = await recorder.readEntries();

      expect(entries, hasLength(CrashLogRecorder.maxEntries));
      expect(entries.last, contains('entry ${CrashLogRecorder.maxEntries + 4}'));
    });

    test('should return no entries after clearing', () async {
      recorder.record(moduleName: 'M', message: 'x');

      await recorder.clearEntries();

      expect(await recorder.readEntries(), isEmpty);
    });
  });
}
