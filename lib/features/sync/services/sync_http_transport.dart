// lib/features/sync/services/sync_http_transport.dart — posts JSON to the paired host over the loopback link and decodes replies.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/constants/sync_constants.dart';
import 'sync_error_codec.dart';
import 'sync_protocol.dart';

class SyncHttpResponse {
  final Map<String, dynamic> json;
  final int requestBytes;
  final int responseBytes;

  const SyncHttpResponse({required this.json, required this.requestBytes, required this.responseBytes});
}

class SyncHttpTransport {
  static const String _jsonContentType = 'application/json; charset=utf-8';

  final String host;
  final int port;
  final HttpClient _client;
  final SyncErrorCodec _errorCodec = const SyncErrorCodec();

  String? token;

  SyncHttpTransport({required this.host, required this.port, HttpClient? client})
    : _client = client ?? (HttpClient()..connectionTimeout = SyncConstants.connectTimeout);

  Future<SyncHttpResponse> post(String path, Map<String, dynamic> body) async {
    final requestBytes = utf8.encode(jsonEncode(body));
    final request = await _client.post(host, port, path);
    request.headers.set(HttpHeaders.contentTypeHeader, _jsonContentType);
    final sessionToken = token;
    if (sessionToken != null) {
      request.headers.set(SyncConstants.authorizationHeader, '${SyncConstants.bearerPrefix}$sessionToken');
    }
    request.contentLength = requestBytes.length;
    request.add(requestBytes);
    final response = await request.close().timeout(SyncConstants.requestTimeout);
    final responseBytes = await response.fold<List<int>>(<int>[], (all, chunk) => all..addAll(chunk));
    final decoded = jsonDecode(utf8.decode(responseBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The other device sent an unreadable reply');
    }
    if (response.statusCode != HttpStatus.ok) {
      throw _errorCodec.decode(SyncErrorBody.fromJson(decoded));
    }
    return SyncHttpResponse(json: decoded, requestBytes: requestBytes.length, responseBytes: responseBytes.length);
  }

  void close() => _client.close(force: true);
}
