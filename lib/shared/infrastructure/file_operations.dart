import 'dart:io';

import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';

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

  static Future<String> readFile(String filePath) async {
    return File(filePath).readAsString();
  }

  static Future<void> shareFile(String filePath) async {
    await initialize();
    await _shareService.shareFile(filePath);
  }
}
