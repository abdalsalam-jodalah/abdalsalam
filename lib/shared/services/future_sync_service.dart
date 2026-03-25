import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';

class FutureSyncService {
  final ApiClient? apiClient;

  const FutureSyncService({this.apiClient});

  bool get isSyncReady => apiClient != null;

  Map<String, dynamic> buildAiReadyPayload({
    required String module,
    required String userId,
    required List<Map<String, dynamic>> data,
  }) {
    return <String, dynamic>{
      'version': '1.0.0',
      'module': module,
      'userId': userId,
      'generatedAt': DateTime.now().toIso8601String(),
      'recordCount': data.length,
      'data': data,
    };
  }
}
