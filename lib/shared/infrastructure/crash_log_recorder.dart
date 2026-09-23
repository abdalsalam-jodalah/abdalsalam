import 'dart:convert';

import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';
import 'package:flutter/foundation.dart';

class CrashLogRecorder {
  static final CrashLogRecorder instance = CrashLogRecorder._();

  static const String _storageKey = 'crash_log_entries';
  static const int maxEntries = 200;

  final SharedPreferencesStorage _preferencesStorage = SharedPreferencesStorage();
  Future<void>? _initialization;
  Future<void> _pendingWrite = Future<void>.value();

  CrashLogRecorder._();

  void record({
    required String moduleName,
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final entry = StringBuffer('[${DateTime.now().toIso8601String()}] [ERROR] [$moduleName] $message');
    if (error != null) {
      entry.write('\nError: $error');
    }
    if (stackTrace != null) {
      entry.write('\nStack: $stackTrace');
    }
    _pendingWrite = _pendingWrite.then((_) => _append(entry.toString())).catchError(_reportPersistFailure);
  }

  Future<List<String>> readEntries() async {
    await _pendingWrite;
    return _readStoredEntries();
  }

  Future<void> clearEntries() async {
    await _pendingWrite;
    await _ensureInitialized();
    await _preferencesStorage.delete(_storageKey);
  }

  Future<void> _append(String entry) async {
    final entries = await _readStoredEntries();
    entries.add(entry);
    final trimmed = entries.length > maxEntries ? entries.sublist(entries.length - maxEntries) : entries;
    await _preferencesStorage.set(_storageKey, jsonEncode(trimmed));
  }

  Future<List<String>> _readStoredEntries() async {
    await _ensureInitialized();
    final raw = await _preferencesStorage.get(_storageKey);
    if (raw is! String) {
      return <String>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList();
      }
    } on FormatException catch (error) {
      debugPrint('[CrashLogRecorder] discarding unreadable crash log: $error');
    }
    return <String>[];
  }

  Future<void> _ensureInitialized() {
    return _initialization ??= _preferencesStorage.initialize().catchError((Object error) {
      _initialization = null;
      throw error;
    });
  }

  void _reportPersistFailure(Object error) {
    debugPrint('[CrashLogRecorder] failed to persist crash log entry: $error');
  }
}
