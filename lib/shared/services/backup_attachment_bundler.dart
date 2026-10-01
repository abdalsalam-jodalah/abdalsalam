// lib/shared/services/backup_attachment_bundler.dart — moves attachment files in and out of a backup and rewrites record paths to match.

import 'dart:typed_data';

import 'attachment_storage_service.dart';
import 'backup_keys.dart';

typedef BackupRows = Map<String, List<Map<String, dynamic>>>;

class AttachmentBinding {
  final String table;
  final String field;
  final bool isList;
  final AttachmentStorageService storage;

  const AttachmentBinding({
    required this.table,
    required this.field,
    required this.storage,
    this.isList = false,
  });
}

class AttachmentBundle {
  final BackupRows rows;
  final Map<String, Uint8List> files;
  final int missingCount;

  const AttachmentBundle({required this.rows, required this.files, required this.missingCount});
}

class AttachmentRestoreOutcome {
  final BackupRows rows;
  final int restoredCount;
  final int missingCount;

  const AttachmentRestoreOutcome({required this.rows, required this.restoredCount, required this.missingCount});
}

class BackupAttachmentBundler {
  final List<AttachmentBinding> bindings;

  const BackupAttachmentBundler(this.bindings);

  Future<AttachmentBundle> bundle(BackupRows rows) async {
    final result = <String, List<Map<String, dynamic>>>{...rows};
    final files = <String, Uint8List>{};
    final entryBySourcePath = <String, String>{};
    final sourceByEntry = <String, String>{};
    var missingCount = 0;

    Future<String> entryFor(AttachmentBinding binding, String sourcePath) async {
      final known = entryBySourcePath[sourcePath];
      if (known != null) {
        return known;
      }
      Uint8List? bytes;
      try {
        bytes = await binding.storage.readAttachmentBytes(sourcePath);
      } catch (_) {
        bytes = null;
      }
      if (bytes == null) {
        missingCount++;
        return sourcePath;
      }
      final entry = _uniqueEntryName(binding.table, sourcePath, sourceByEntry);
      sourceByEntry[entry] = sourcePath;
      entryBySourcePath[sourcePath] = entry;
      files[entry] = bytes;
      return entry;
    }

    for (final binding in bindings) {
      final tableRows = result[binding.table];
      if (tableRows == null) {
        continue;
      }
      result[binding.table] = await _rewriteRows(tableRows, binding, (path) => entryFor(binding, path));
    }
    return AttachmentBundle(rows: result, files: files, missingCount: missingCount);
  }

  Future<AttachmentRestoreOutcome> restore(BackupRows rows, Map<String, Uint8List> files) async {
    final result = <String, List<Map<String, dynamic>>>{...rows};
    final restoredPathByEntry = <String, String>{};
    var missingCount = 0;

    Future<String> pathFor(AttachmentBinding binding, String entry) async {
      if (!entry.startsWith(BackupKeys.archiveAttachmentsPrefix)) {
        return entry;
      }
      final known = restoredPathByEntry[entry];
      if (known != null) {
        return known;
      }
      final bytes = files[entry];
      final fileName = entry.split('/').last;
      if (bytes == null || fileName.isEmpty) {
        missingCount++;
        return entry;
      }
      final saved = await binding.storage.saveAttachmentBytes(fileName: fileName, bytes: bytes);
      if (saved.isFailure) {
        missingCount++;
        return entry;
      }
      restoredPathByEntry[entry] = saved.data!;
      return saved.data!;
    }

    for (final binding in bindings) {
      final tableRows = result[binding.table];
      if (tableRows == null) {
        continue;
      }
      result[binding.table] = await _rewriteRows(tableRows, binding, (entry) => pathFor(binding, entry));
    }
    return AttachmentRestoreOutcome(rows: result, restoredCount: restoredPathByEntry.length, missingCount: missingCount);
  }

  Future<List<Map<String, dynamic>>> _rewriteRows(
    List<Map<String, dynamic>> rows,
    AttachmentBinding binding,
    Future<String> Function(String path) rewritePath,
  ) async {
    final rewritten = <Map<String, dynamic>>[];
    for (final row in rows) {
      final value = row[binding.field];
      if (binding.isList && value is List) {
        final paths = <Object?>[];
        for (final item in value) {
          paths.add(item is String && item.isNotEmpty ? await rewritePath(item) : item);
        }
        rewritten.add(<String, dynamic>{...row, binding.field: paths});
      } else if (!binding.isList && value is String && value.isNotEmpty) {
        rewritten.add(<String, dynamic>{...row, binding.field: await rewritePath(value)});
      } else {
        rewritten.add(row);
      }
    }
    return rewritten;
  }

  String _uniqueEntryName(String table, String sourcePath, Map<String, String> sourceByEntry) {
    final baseName = sourcePath.split('/').last;
    var candidate = '${BackupKeys.archiveAttachmentsPrefix}$table/$baseName';
    var suffix = 1;
    while (sourceByEntry.containsKey(candidate)) {
      candidate = '${BackupKeys.archiveAttachmentsPrefix}$table/${suffix++}-$baseName';
    }
    return candidate;
  }
}
