// lib/features/sync/services/sync_server.dart — loopback HTTP server that lets a paired device sync with this one.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../core/constants/sync_constants.dart';
import '../../../core/errors/app_error.dart';
import '../../../data/models/sync/sync_phase.dart';
import '../../../data/models/sync/sync_progress_event.dart';
import '../../../data/models/sync/sync_session_report.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/services/error_handler.dart';
import 'sync_data_store.dart';
import 'sync_error_codec.dart';
import 'sync_errors.dart';
import 'sync_host_session.dart';
import 'sync_pairing_service.dart';
import 'sync_protocol.dart';
import 'sync_safety_backup.dart';

class SyncServer {
  static const String _jsonContentType = 'application/json; charset=utf-8';
  static const String _postMethod = 'POST';

  final SyncDataStore store;
  final SyncPairingService pairing;
  final SyncSafetyBackup safetyBackup;
  final LoggerService logger;
  final String deviceLabel;
  final DateTime Function() _clock;
  final SyncErrorCodec _errorCodec = const SyncErrorCodec();
  final StreamController<SyncProgressEvent> _events = StreamController<SyncProgressEvent>.broadcast();
  final StreamController<SyncSessionReport> _reports = StreamController<SyncSessionReport>.broadcast();

  HttpServer? _httpServer;
  SyncHostSession? _session;

  SyncServer({
    required this.store,
    required this.pairing,
    required this.safetyBackup,
    required this.logger,
    required this.deviceLabel,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  bool get isRunning => _httpServer != null;

  int? get port => _httpServer?.port;

  String? get pin => pairing.pin;

  Stream<SyncProgressEvent> get events => _events.stream;

  Stream<SyncSessionReport> get completedReports => _reports.stream;

  Future<int> start({int port = SyncConstants.defaultPort}) async {
    final running = _httpServer;
    if (running != null) {
      return running.port;
    }
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _httpServer = server;
    pairing.startPairing();
    unawaited(server.forEach(_handle));
    _events.add(const SyncProgressEvent(phase: SyncPhase.waiting));
    logger.info('[SyncServer] listening on ${server.address.address}:${server.port}');
    return server.port;
  }

  Future<void> stop() async {
    final server = _httpServer;
    _httpServer = null;
    _session = null;
    pairing.stopPairing();
    await server?.close(force: true);
    _events.add(const SyncProgressEvent(phase: SyncPhase.idle));
    logger.info('[SyncServer] stopped');
  }

  Future<void> dispose() async {
    await stop();
    await _events.close();
    await _reports.close();
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      if (request.method != _postMethod) {
        throw SyncBadRequestError('Only POST is supported');
      }
      final body = await _readBody(request);
      if (body == null) {
        await _respondError(request, _errorCodec.payloadTooLarge());
        return;
      }
      final decoded = body.isEmpty ? <String, dynamic>{} : jsonDecode(utf8.decode(body));
      if (decoded is! Map<String, dynamic>) {
        throw SyncBadRequestError('Request body must be a JSON object');
      }
      final path = request.uri.path;
      if (path == SyncEndpoints.hello) {
        await _respondJson(request, _hello(SyncHelloRequest.fromJson(decoded)).toJson());
        return;
      }
      _authorize(request);
      await _route(request, path, decoded, body.length);
    } catch (error, stackTrace) {
      if (error is! AppError && error is! FormatException) {
        _errorHandler.mapException(error, context: 'SyncServer.handle', stackTrace: stackTrace);
      }
      await _respondError(request, _errorCodec.encode(error));
    }
  }

  Future<void> _route(HttpRequest request, String path, Map<String, dynamic> json, int requestBytes) async {
    final session = _session;
    if (session == null) {
      throw SyncUnauthorizedError();
    }
    switch (path) {
      case SyncEndpoints.diff:
        final response = await session.diff(SyncDiffRequest.fromJson(json));
        await _respondJson(request, response.toJson());
      case SyncEndpoints.pull:
        final payload = await session.pull(SyncPullRequest.fromJson(json));
        final bytes = _encode(payload.toJson());
        session.recordPullSent(payload, bytes.length);
        await _respondBytes(request, bytes);
      case SyncEndpoints.push:
        session.stagePush(SyncRowsPayload.fromJson(json), requestBytes);
        await _respondJson(request, const <String, dynamic>{});
      case SyncEndpoints.commit:
        await _commit(request, session, SyncCommitPayload.fromJson(json));
      case SyncEndpoints.abort:
        _endSession();
        await _respondJson(request, const <String, dynamic>{});
      default:
        throw SyncBadRequestError('Unknown endpoint');
    }
  }

  SyncHelloResponse _hello(SyncHelloRequest hello) {
    if (hello.protocolVersion != SyncConstants.protocolVersion) {
      throw SyncVersionMismatchError();
    }
    final verified = pairing.verifyPin(hello.pin);
    if (verified.isFailure) {
      throw verified.error!;
    }
    final now = _clock();
    _session = SyncHostSession(
      store: store,
      safetyBackup: safetyBackup,
      remoteDeviceLabel: hello.deviceLabel,
      clockSkew: Duration(milliseconds: hello.clientTimeMilliseconds - now.millisecondsSinceEpoch),
      startedAt: now,
      clock: _clock,
      emit: _events.add,
    );
    _events.add(const SyncProgressEvent(phase: SyncPhase.connecting));
    return SyncHelloResponse(
      token: verified.data!,
      deviceLabel: deviceLabel,
      serverTimeMilliseconds: now.millisecondsSinceEpoch,
      tables: store.syncableTables,
    );
  }

  Future<void> _commit(HttpRequest request, SyncHostSession session, SyncCommitPayload payload) async {
    try {
      final outcome = await session.commit(payload);
      _endSession();
      _reports.add(outcome.report);
      await _respondJson(request, outcome.response.toJson());
    } catch (_) {
      _endSession();
      _events.add(const SyncProgressEvent(phase: SyncPhase.failed));
      rethrow;
    }
  }

  void _endSession() {
    _session = null;
    pairing.endSession();
  }

  void _authorize(HttpRequest request) {
    final header = request.headers.value(SyncConstants.authorizationHeader);
    final token = header != null && header.startsWith(SyncConstants.bearerPrefix)
        ? header.substring(SyncConstants.bearerPrefix.length)
        : null;
    if (!pairing.isValidToken(token)) {
      throw SyncUnauthorizedError();
    }
  }

  Future<Uint8List?> _readBody(HttpRequest request) async {
    if (request.contentLength > SyncConstants.maxRequestBodyBytes) {
      return null;
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in request) {
      builder.add(chunk);
      if (builder.length > SyncConstants.maxRequestBodyBytes) {
        return null;
      }
    }
    return builder.takeBytes();
  }

  Uint8List _encode(Map<String, dynamic> json) => Uint8List.fromList(utf8.encode(jsonEncode(json)));

  Future<void> _respondJson(HttpRequest request, Map<String, dynamic> json) => _respondBytes(request, _encode(json));

  Future<void> _respondBytes(HttpRequest request, Uint8List bytes, {int statusCode = HttpStatus.ok}) async {
    final response = request.response;
    response.statusCode = statusCode;
    response.headers.set(HttpHeaders.contentTypeHeader, _jsonContentType);
    response.contentLength = bytes.length;
    response.add(bytes);
    await response.close();
  }

  Future<void> _respondError(HttpRequest request, SyncErrorResponse error) async {
    try {
      await _respondBytes(request, _encode(error.body.toJson()), statusCode: error.statusCode);
    } on HttpException catch (failure, stackTrace) {
      _errorHandler.mapException(failure, context: 'SyncServer.respondError', stackTrace: stackTrace);
    }
  }
}
