import 'dart:convert';

import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';

import '../../core/errors/app_error.dart';

enum StorageType { sqlite, hive, sharedPreferences }

class StorageGateway {
  static final StorageGateway instance = StorageGateway._();

  final SharedPreferencesStorage _preferencesStorage = SharedPreferencesStorage();
  final Map<String, SqliteStorageImpl<Map<String, dynamic>>> _sqliteStores =
      <String, SqliteStorageImpl<Map<String, dynamic>>>{};
  bool _initialized = false;
  String _databaseName = 'abdalsalam.db';

  StorageGateway._();

  Future<void> initialize({String databaseName = 'abdalsalam.db'}) async {
    if (_initialized) {
      return;
    }
    _databaseName = databaseName;
    await _preferencesStorage.initialize();
    _initialized = true;
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
        final store = await _getSqliteStore('_key_value');
        final now = DateTime.now();
        final row = <String, dynamic>{
          'id': key,
          'userId': null,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'deletedAt': null,
          'value': value,
        };
        await store.upsert(row);
      case StorageType.hive:
        await _preferencesStorage.set('hive:$key', jsonEncode(value));
    }
  }

  Future<T?> get<T>(String key, {StorageType storageType = StorageType.sharedPreferences}) async {
    await _ensureInitialized();
    switch (storageType) {
      case StorageType.sharedPreferences:
        final raw = await _preferencesStorage.get(key);
        if (raw is! String) {
          return null;
        }
        return jsonDecode(raw) as T?;
      case StorageType.sqlite:
        final store = await _getSqliteStore('_key_value');
        final row = await store.get(key);
        if (row == null) {
          return null;
        }
        return row['value'] as T?;
      case StorageType.hive:
        final raw = await _preferencesStorage.get('hive:$key');
        if (raw is! String) {
          return null;
        }
        return jsonDecode(raw) as T?;
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
    await _ensureInitialized();
    final store = await _getSqliteStore(table);
    final existing = await store.get(id);
    final createdAt = existing?['createdAt'] ?? DateTime.now().toIso8601String();
    final row = <String, dynamic>{
      ...record,
      'id': id,
      'userId': userId ?? record['userId'],
      'createdAt': createdAt,
      'updatedAt': DateTime.now().toIso8601String(),
      'deletedAt': record['deletedAt'],
    };
    await store.upsert(row);
  }

  Future<Map<String, dynamic>?> getRecord({
    required String table,
    required String id,
    String? userId,
  }) async {
    await _ensureInitialized();
    final store = await _getSqliteStore(table);
    final row = await store.get(id);
    if (row == null) {
      return null;
    }
    if (userId != null && row['userId'] != userId) {
      return null;
    }
    return row;
  }

  Future<List<Map<String, dynamic>>> getAllRecords({
    required String table,
    String? userId,
  }) async {
    await _ensureInitialized();
    final store = await _getSqliteStore(table);
    final rows = await store.getAll();
    return rows.where((row) => userId == null || row['userId'] == userId).toList(growable: false);
  }

  Future<void> deleteRecord({
    required String table,
    required String id,
  }) async {
    await _ensureInitialized();
    final store = await _getSqliteStore(table);
    await store.delete(id);
  }

  Future<void> clearTable(String table) async {
    await _ensureInitialized();
    final store = await _getSqliteStore(table);
    await store.clear();
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

  Future<void> createTableIfNeeded({
    required String table,
    bool createIndexes = true,
  }) async {
    final store = await _getSqliteStore(table);
    final db = store.database;
    if (db == null) {
      throw DatabaseError('Database is not initialized for table $table');
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $table (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        data TEXT NOT NULL
      )
    ''');

    if (createIndexes) {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_${table}_user_id ON $table(user_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_${table}_created_at ON $table(created_at)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_${table}_deleted_at ON $table(deleted_at)');
    }
  }

  Future<void> createIndexIfNeeded({
    required String table,
    required String indexName,
    required String columnName,
  }) async {
    final store = await _getSqliteStore(table);
    final db = store.database;
    if (db == null) {
      throw DatabaseError('Database is not initialized for table $table');
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS $indexName ON $table($columnName)',
    );
  }

  Future<void> vacuum() async {
    for (final store in _sqliteStores.values) {
      final db = store.database;
      if (db != null) {
        await db.execute('VACUUM');
      }
    }
  }

  Future<List<String>> getAllKeys({StorageType storageType = StorageType.sharedPreferences}) async {
    await _ensureInitialized();
    switch (storageType) {
      case StorageType.sharedPreferences:
        return await _preferencesStorage.keys();
      case StorageType.sqlite:
        // Return all table names
        return _sqliteStores.keys.toList();
      case StorageType.hive:
        final allKeys = await _preferencesStorage.keys();
        return allKeys.where((key) => key.startsWith('hive:')).toList();
    }
  }

  Future<void> delete(String key, {StorageType storageType = StorageType.sharedPreferences}) async {
    await _ensureInitialized();
    switch (storageType) {
      case StorageType.sharedPreferences:
        await _preferencesStorage.delete(key);
      case StorageType.sqlite:
        final store = await _getSqliteStore('_key_value');
        await store.delete(key);
      case StorageType.hive:
        await _preferencesStorage.delete('hive:$key');
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  Future<SqliteStorageImpl<Map<String, dynamic>>> _getSqliteStore(String table) async {
    final existing = _sqliteStores[table];
    if (existing != null) {
      return existing;
    }

    final store = SqliteStorageImpl<Map<String, dynamic>>(
      _databaseName,
      table,
      (entity) => <String, dynamic>{
        'id': entity['id'],
        'user_id': entity['userId'],
        'created_at': entity['createdAt'],
        'updated_at': entity['updatedAt'],
        'deleted_at': entity['deletedAt'],
        'data': jsonEncode(entity),
      },
      (map) {
        final raw = map['data'] as String?;
        final decoded = raw == null ? <String, dynamic>{} : jsonDecode(raw) as Map<String, dynamic>;
        return <String, dynamic>{
          ...decoded,
          'id': map['id'] ?? decoded['id'],
          'userId': map['user_id'] ?? decoded['userId'],
          'createdAt': map['created_at'] ?? decoded['createdAt'],
          'updatedAt': map['updated_at'] ?? decoded['updatedAt'],
          'deletedAt': map['deleted_at'] ?? decoded['deletedAt'],
        };
      },
    );

    await store.initializeWithTableSql('''
      CREATE TABLE IF NOT EXISTS $table (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        data TEXT NOT NULL
      )
    ''');

    _sqliteStores[table] = store;
    return store;
  }
}
