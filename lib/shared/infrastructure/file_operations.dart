import 'dart:io';
import 'dart:typed_data';

import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';
import 'package:file_picker/file_picker.dart';

class FileOperations {
  static final FileService _fileService = FileServiceImpl(appName: 'abdalsalam');
  static final ShareService _shareService = ShareServiceImpl();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await _fileService.initialize();
    await _shareService.initialize();
    _initialized = true;
  }

  static Future<File> saveFile(String content, String fileName) async {
    await initialize();
    final path = await _fileService.getDownloadsPath();
    final file = File('$path/$fileName');
    await file.create(recursive: true);
    await file.writeAsString(content);
    return file;
  }

  static Future<File> saveBytes(List<int> bytes, String fileName) async {
    await initialize();
    final path = await _fileService.getDownloadsPath();
    final file = File('$path/$fileName');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<String?> saveBytesAs({
    required Uint8List bytes,
    required String fileName,
    required String dialogTitle,
  }) {
    return FilePicker.platform.saveFile(dialogTitle: dialogTitle, fileName: fileName, bytes: bytes);
  }

  static Future<void> keepNewestFiles({required String namePrefix, required int count}) async {
    await initialize();
    final directory = Directory(await _fileService.getDownloadsPath());
    if (!await directory.exists()) {
      return;
    }
    final matching = <({File file, DateTime modified})>[];
    await for (final entity in directory.list()) {
      if (entity is File && entity.uri.pathSegments.last.startsWith(namePrefix)) {
        matching.add((file: entity, modified: await entity.lastModified()));
      }
    }
    matching.sort((a, b) => b.modified.compareTo(a.modified));
    for (final stale in matching.skip(count)) {
      await stale.file.delete();
    }
  }

  static Future<String> readFile(String filePath) async {
    return File(filePath).readAsString();
  }

  static Future<Uint8List> readBytes(String filePath) async {
    return File(filePath).readAsBytes();
  }

  static Future<void> shareFile(String filePath) async {
    await initialize();
    await _shareService.shareFile(filePath);
  }
}
