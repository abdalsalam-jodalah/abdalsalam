import 'dart:async';
import 'dart:convert';

import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm, Database, DatabaseExecutor, Sqflite;

import '../../core/errors/app_error.dart';
import 'data_integrity_reporter.dart';
import 'sqlite_record_codec.dart';

enum StorageType { sqlite, hive, sharedPreferences }

class StorageGateway {
  static final StorageGateway instance = StorageGateway._();

  static const String _defaultDatabaseName = 'abdalsalam.db';
  static const String _keyValueTable = '_key_value';
  static const String _hivePrefix = 'hive:';
  static final Object _transactionZoneKey = Object();

  final SharedPreferencesStorage _preferencesStorage = SharedPreferencesStorage();
  final Map<String, Future<SqliteStorageImpl<Map<String, dynamic>>>> _sqliteStores =
      <String, Future<SqliteStorageImpl<Map<String, dynamic>>>>{};
  final Set<String> _ensuredTables = <String>{};
  final SqliteRecordCodec _codec = const SqliteRecordCodec();
  final DataIntegrityReporter integrityReporter = DataIntegrityReporter();

  Future<void>? _initialization;
  String _databaseName = _defaultDatabaseName;

  StorageGateway._();

  Future<void> initialize({String databaseName = _defaultDatabaseName}) {
    return _initialization ??= _initialize(databaseName);
  }

  Future<void> _initialize(String databaseName) async {
    try {
      _databaseName = databaseName;
      await _preferencesStorage.initialize();
    } catch (error, stackTrace) {
      _initialization = null;
      throw StorageUnavailableError(
        'Preferences storage failed to initialize',
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }

  Future<void> save({
    required String key,
    required dynamic value,
    StorageType storageType = StorageType.sharedPreferences,
  }) async {
    await _ensureInitialized();
    switch (storageType) {
      case StorageType.sharedPreferences:
        await _preferencesStorage.set(key, jsonEncode(value));
      case StorageType.sqlite:
        await upsertRecord(
          table: _keyValueTable,
          id: key,
          record: <String, dynamic>{'value': value},
        );
      case StorageType.hive:
        await _preferencesStorage.set('$_hivePrefix$key', jsonEncode(value));
    }
  }

  Future<T?> get<T>(String key, {StorageType storageType = StorageType.sharedPreferences}) async {
    await _ensureInitialized();
    switch (storageType) {
      case StorageType.sharedPreferences:
        return _decodePreference<T>(key, await _preferencesStorage.get(key));
      case StorageType.sqlite:
        final record = await getRecord(table: _keyValueTable, id: key);
        if (record == null) {
          return null;
        }
        return _castStoredValue<T>(key, record['value']);
      case StorageType.hive:
        return _decodePreference<T>(key, await _preferencesStorage.get('$_hivePrefix$key'));
    }
  }

  Future<void> saveForUser({
    required String userId,
    required String key,
    required dynamic value,
    StorageType storageType = StorageType.sharedPreferences,
  }) async {
    await save(key: '$userId$key', value: value, storageType: storageType);
  }

  Future<T?> getForUser<T>({
    required String userId,
    required String key,
    StorageType storageType = StorageType.sharedPreferences,
  }) async {
    return get<T>('$userId$key', storageType: storageType);
  }

  Future<void> upsertRecord({
    required String table,
    required String id,
    required Map<String, dynamic> record,
    String? userId,
  }) async {
    final executor = await _executorFor(table);
    final now = DateTime.now().toIso8601String();
    final createdAt = record['createdAt'] ?? await _existingCreatedAt(executor, table, id) ?? now;
    final row = <String, dynamic>{
      ...record,
      'id': id,
      'userId': userId ?? record['userId'],
      'createdAt': createdAt,
      'updatedAt': now,
      'deletedAt': record['deletedAt'],
    };
    await executor.insert(table, _codec.encode(row), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getRecord({
    required String table,
    required String id,
    String? userId,
  }) async {
    final executor = await _executorFor(table);
    final rows = await executor.query(
      table,
      where: '${SqliteRecordCodec.idColumn} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final record = _codec.decode(rows.first, table: table);
    if (userId != null && record['userId'] != userId) {
      return null;
    }
    return record;
  }

  Future<List<Map<String, dynamic>>> getAllRecords({
    required String table,
    String? userId,
  }) async {
    final executor = await _executorFor(table);
    final rows = userId == null
        ? await executor.query(table)
        : await executor.query(
            table,
            where: '${SqliteRecordCodec.userIdColumn} = ?',
            whereArgs: <Object?>[userId],
          );
    final records = <Map<String, dynamic>>[];
    for (final row in rows) {
      try {
        records.add(_codec.decode(row, table: table));
      } on CorruptDataError catch (error, stackTrace) {
        integrityReporter.reportCorruptRecord(
          table: table,
          recordId: '${row[SqliteRecordCodec.idColumn]}',
          reason: error,
          stackTrace: stackTrace,
        );
      }
    }
    return records;
  }

  Future<int> countRecords({required String table}) async {
    final executor = await _executorFor(table);
    final result = await executor.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteRecord({
    required String table,
    required String id,
  }) async {
    final executor = await _executorFor(table);
    await executor.delete(
      table,
      where: '${SqliteRecordCodec.idColumn} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> clearTable(String table) async {
    final executor = await _executorFor(table);
    await executor.delete(table);
  }

  Future<List<Map<String, dynamic>>> query({
    required String table,
    Map<String, dynamic> filters = const <String, dynamic>{},
    String? userId,
  }) async {
    final rows = await getAllRecords(table: table, userId: userId);
    if (filters.isEmpty) {
      return rows;
    }
    return rows.where((row) {
      for (final entry in filters.entries) {
        if (row[entry.key] != entry.value) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  Future<R> runInTransaction<R>(Future<R> Function() action) async {
    if (Zone.current[_transactionZoneKey] != null) {
      return action();
    }
    final database = await _databaseFor(_keyValueTable);
    try {
      return await database.transaction<R>(
        (transaction) => runZoned(action, zoneValues: <Object, Object>{_transactionZoneKey: transaction}),
      );
    } catch (_) {
      _ensuredTables.clear();
      rethrow;
    }
  }

  Future<void> createTableIfNeeded({
    required String table,
    bool createIndexes = true,
  }) async {
    final executor = await _executorFor(table);
    if (createIndexes) {
      await executor.execute(
        'CREATE INDEX IF NOT EXISTS idx_${table}_user_id ON $table(${SqliteRecordCodec.userIdColumn})',
      );
      await executor.execute(
        'CREATE INDEX IF NOT EXISTS idx_${table}_created_at ON $table(${SqliteRecordCodec.createdAtColumn})',
      );
      await executor.execute(
        'CREATE INDEX IF NOT EXISTS idx_${table}_deleted_at ON $table(${SqliteRecordCodec.deletedAtColumn})',
      );
    }
  }

  Future<void> createIndexIfNeeded({
    required String table,
    required String indexName,
    required String columnName,
  }) async {
    final executor = await _executorFor(table);
    await executor.execute('CREATE INDEX IF NOT EXISTS $indexName ON $table($columnName)');
  }

  Future<void> vacuum() async {
    final database = await _databaseFor(_keyValueTable);
    await database.execute('VACUUM');
  }

  Future<List<String>> getAllKeys({StorageType storageType = StorageType.sharedPreferences}) async {
    await _ensureInitialized();
    switch (storageType) {
      case StorageType.sharedPreferences:
        return await _preferencesStorage.keys();
      case StorageType.sqlite:
        return _sqliteStores.keys.toList();
      case StorageType.hive:
        final allKeys = await _preferencesStorage.keys();
        return allKeys.where((key) => key.startsWith(_hivePrefix)).toList();
    }
  }

  Future<void> delete(String key, {StorageType storageType = StorageType.sharedPreferences}) async {
    await _ensureInitialized();
    switch (storageType) {
      case StorageType.sharedPreferences:
        await _preferencesStorage.delete(key);
      case StorageType.sqlite:
        await deleteRecord(table: _keyValueTable, id: key);
      case StorageType.hive:
        await _preferencesStorage.delete('$_hivePrefix$key');
    }
  }

  T? _decodePreference<T>(String key, Object? raw) {
    if (raw is! String) {
      return null;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error, stackTrace) {
      throw CorruptDataError(
        'Stored value for "$key" is not valid JSON',
        source: 'preferences',
        field: key,
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
    return _castStoredValue<T>(key, decoded);
  }

  T? _castStoredValue<T>(String key, Object? value) {
    if (value == null) {
      return null;
    }
    if (value is T) {
      return value as T;
    }
    throw CorruptDataError(
      'Stored value for "$key" is ${value.runtimeType}, expected $T',
      source: 'preferences',
      field: key,
    );
  }

  Future<String?> _existingCreatedAt(DatabaseExecutor executor, String table, String id) async {
    final rows = await executor.query(
      table,
      columns: <String>[SqliteRecordCodec.createdAtColumn],
      where: '${SqliteRecordCodec.idColumn} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final createdAt = rows.first[SqliteRecordCodec.createdAtColumn];
    return createdAt is String ? createdAt : null;
  }

  Future<void> _ensureInitialized() => initialize();

  Future<DatabaseExecutor> _executorFor(String table) async {
    final database = await _databaseFor(table);
    final transaction = Zone.current[_transactionZoneKey];
    final executor = transaction is DatabaseExecutor ? transaction : database;
    if (!_ensuredTables.contains(table)) {
      await executor.execute(_codec.createTableSql(table));
      _ensuredTables.add(table);
    }
    return executor;
  }

  Future<Database> _databaseFor(String table) async {
    await _ensureInitialized();
    final store = await (_sqliteStores[table] ??= _openStore(table));
    final database = store.database;
    if (database == null) {
      throw StorageUnavailableError('Database is not open for table $table');
    }
    return database;
  }

  Future<SqliteStorageImpl<Map<String, dynamic>>> _openStore(String table) async {
    final store = SqliteStorageImpl<Map<String, dynamic>>(
      _databaseName,
      table,
      _codec.encode,
      (row) => _codec.decode(row, table: table),
    );
    try {
      await store.initializeWithTableSql(_codec.createTableSql(table));
      return store;
    } catch (error, stackTrace) {
      _sqliteStores.remove(table);
      throw StorageUnavailableError(
        'Database failed to open for table $table',
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }
}
