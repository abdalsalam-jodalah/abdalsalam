// lib/shared/services/module_export.dart — a finished readable export: zip bytes plus per-module record counts.

import 'dart:typed_data';

import 'module_table_registry.dart';

class ModuleExport {
  final Uint8List bytes;
  final String fileName;
  final Map<DataModule, int> recordCountByModule;

  const ModuleExport({required this.bytes, required this.fileName, required this.recordCountByModule});
}
