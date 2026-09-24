import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';

class BackupCodec {
  const BackupCodec();

  String encode(Map<String, dynamic> backup) => base64Encode(utf8.encode(jsonEncode(backup)));

  Result<Map<String, dynamic>, AppError> decode(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return Failure(ImportError('Backup is empty'));
    }
    final jsonText = trimmed.startsWith('{') ? trimmed : _decodeBase64(trimmed);
    if (jsonText == null) {
      return Failure(ImportError('Backup is neither JSON nor base64-encoded JSON'));
    }
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is Map<String, dynamic>) {
        return Success(decoded);
      }
      return Failure(ImportError('Backup root is not a JSON object'));
    } on FormatException catch (error, stackTrace) {
      return Failure(ImportError('Backup is not valid JSON', cause: error, causeStackTrace: stackTrace));
    }
  }

  String checksum(Object? section) => sha256.convert(utf8.encode(jsonEncode(section))).toString();

  String? _decodeBase64(String content) {
    try {
      return utf8.decode(base64Decode(content.replaceAll(RegExp(r'\s'), '')));
    } on FormatException {
      return null;
    }
  }
}
