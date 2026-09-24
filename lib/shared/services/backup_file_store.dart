import '../infrastructure/file_operations.dart';

class BackupFileStore {
  const BackupFileStore();

  Future<String> save({required String content, required String fileName}) async {
    final file = await FileOperations.saveFile(content, fileName);
    return file.path;
  }

  Future<String> read(String filePath) => FileOperations.readFile(filePath);

  Future<void> share(String filePath) => FileOperations.shareFile(filePath);
}
