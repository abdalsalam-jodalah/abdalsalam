import 'dart:convert';

import '../../core/errors/app_error.dart';

class SqliteRecordCodec {
  static const String idColumn = 'id';
  static const String userIdColumn = 'user_id';
  static const String createdAtColumn = 'created_at';
  static const String updatedAtColumn = 'updated_at';
  static const String deletedAtColumn = 'deleted_at';
  static const String dataColumn = 'data';

  const SqliteRecordCodec();

  String createTableSql(String table) {
    return '''
      CREATE TABLE IF NOT EXISTS $table (
        $idColumn TEXT PRIMARY KEY,
        $userIdColumn TEXT,
        $createdAtColumn TEXT,
        $updatedAtColumn TEXT,
        $deletedAtColumn TEXT,
        $dataColumn TEXT NOT NULL
      )
    ''';
  }

  Map<String, dynamic> encode(Map<String, dynamic> record) {
    return <String, dynamic>{
      idColumn: record['id'],
      userIdColumn: record['userId'],
      createdAtColumn: record['createdAt'],
      updatedAtColumn: record['updatedAt'],
      deletedAtColumn: record['deletedAt'],
      dataColumn: jsonEncode(record),
    };
  }

  Map<String, dynamic> decode(Map<String, Object?> row, {required String table}) {
    final raw = row[dataColumn];
    final Object? decoded;
    try {
      decoded = raw is String ? jsonDecode(raw) : null;
    } on FormatException catch (error, stackTrace) {
      throw CorruptDataError(
        '$table: record ${row[idColumn]} has invalid JSON',
        source: table,
        field: dataColumn,
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw CorruptDataError(
        '$table: record ${row[idColumn]} is not a JSON object',
        source: table,
        field: dataColumn,
      );
    }
    return <String, dynamic>{
      ...decoded,
      'id': row[idColumn] ?? decoded['id'],
      'userId': row[userIdColumn] ?? decoded['userId'],
      'createdAt': row[createdAtColumn] ?? decoded['createdAt'],
      'updatedAt': row[updatedAtColumn] ?? decoded['updatedAt'],
      'deletedAt': row[deletedAtColumn] ?? decoded['deletedAt'],
    };
  }
}
