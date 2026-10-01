import 'dart:typed_data';

import '../infrastructure/file_operations.dart';

class BackupFileStore {
  static const String _saveAsDialogTitle = 'Save backup';

  const BackupFileStore();

  Future<String> save({required String content, required String fileName}) async {
    final file = await FileOperations.saveFile(content, fileName);
    return file.path;
  }

  Future<String> saveBytes({required Uint8List bytes, required String fileName}) async {
    final file = await FileOperations.saveBytes(bytes, fileName);
    return file.path;
  }

  Future<String?> saveBytesAs({required Uint8List bytes, required String fileName}) {
    return FileOperations.saveBytesAs(bytes: bytes, fileName: fileName, dialogTitle: _saveAsDialogTitle);
  }

  Future<void> keepNewest({required String prefix, required int count}) {
    return FileOperations.keepNewestFiles(namePrefix: prefix, count: count);
  }

  Future<String> read(String filePath) => FileOperations.readFile(filePath);

  Future<Uint8List> readBytes(String filePath) => FileOperations.readBytes(filePath);

  Future<void> share(String filePath) => FileOperations.shareFile(filePath);
}
