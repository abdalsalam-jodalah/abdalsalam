import 'package:abdalsalam/shared/infrastructure/data_integrity_reporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DataIntegrityReporter', () {
    test('should count each corrupt record once', () {
      final reporter = DataIntegrityReporter();

      reporter.reportCorruptRecord(table: 'notes', recordId: '1', reason: 'bad');
      reporter.reportCorruptRecord(table: 'notes', recordId: '1', reason: 'bad');
      reporter.reportCorruptRecord(table: 'todos', recordId: '1', reason: 'bad');

      expect(reporter.corruptRecordCount, 2);
    });

    test('should emit the new count when a record is reported', () async {
      final reporter = DataIntegrityReporter();
      final counts = <int>[];
      final subscription = reporter.corruptRecordCountChanges.listen(counts.add);

      reporter.reportCorruptRecord(table: 'notes', recordId: '1', reason: 'bad');
      reporter.clearReports();
      await Future<void>.delayed(Duration.zero);

      expect(counts, [1, 0]);
      await subscription.cancel();
    });
  });
}
