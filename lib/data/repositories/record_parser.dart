import '../../core/errors/app_error.dart';
import '../../shared/infrastructure/data_integrity_reporter.dart';

class RecordParser<T extends Object> {
  final String table;
  final T Function(Map<String, dynamic> json) fromJson;
  final DataIntegrityReporter integrityReporter;

  const RecordParser({
    required this.table,
    required this.fromJson,
    required this.integrityReporter,
  });

  List<T> parseAll(Iterable<Map<String, dynamic>> rows) {
    final items = <T>[];
    for (final row in rows) {
      final item = _tryParse(row);
      if (item != null) {
        items.add(item);
      }
    }
    return items;
  }

  T parseOne(Map<String, dynamic> row) {
    final item = _tryParse(row);
    if (item == null) {
      throw CorruptDataError('$table: record ${row['id']} could not be read', source: table);
    }
    return item;
  }

  T? _tryParse(Map<String, dynamic> row) {
    try {
      return fromJson(row);
    } catch (error, stackTrace) {
      integrityReporter.reportCorruptRecord(
        table: table,
        recordId: '${row['id']}',
        reason: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
