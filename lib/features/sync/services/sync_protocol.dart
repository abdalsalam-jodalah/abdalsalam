// lib/features/sync/services/sync_protocol.dart — endpoint names and JSON payloads exchanged between the two syncing devices.

import 'dart:convert';
import 'dart:typed_data';

import '../../../core/json/json_reader.dart';
import '../../../data/models/sync/sync_manifest.dart';
import '../../../data/models/sync/sync_row_bundle.dart';
import '../../../data/models/sync/sync_row_stamp.dart';
import 'sync_errors.dart';

class SyncEndpoints {
  const SyncEndpoints._();

  static const String hello = '/hello';
  static const String diff = '/diff';
  static const String pull = '/pull';
  static const String push = '/push';
  static const String commit = '/commit';
  static const String abort = '/abort';
}

class SyncHelloRequest {
  final String pin;
  final String deviceLabel;
  final int clientTimeMilliseconds;
  final int protocolVersion;

  const SyncHelloRequest({
    required this.pin,
    required this.deviceLabel,
    required this.clientTimeMilliseconds,
    required this.protocolVersion,
  });

  factory SyncHelloRequest.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'SyncHelloRequest');
    return SyncHelloRequest(
      pin: reader.requireString('pin'),
      deviceLabel: reader.readString('deviceLabel'),
      clientTimeMilliseconds: reader.requireInt('clientTimeMilliseconds'),
      protocolVersion: reader.requireInt('protocolVersion'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'pin': pin,
    'deviceLabel': deviceLabel,
    'clientTimeMilliseconds': clientTimeMilliseconds,
    'protocolVersion': protocolVersion,
  };
}

class SyncHelloResponse {
  final String token;
  final String deviceLabel;
  final int serverTimeMilliseconds;
  final List<String> tables;

  const SyncHelloResponse({
    required this.token,
    required this.deviceLabel,
    required this.serverTimeMilliseconds,
    required this.tables,
  });

  factory SyncHelloResponse.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'SyncHelloResponse');
    return SyncHelloResponse(
      token: reader.requireString('token'),
      deviceLabel: reader.readString('deviceLabel'),
      serverTimeMilliseconds: reader.requireInt('serverTimeMilliseconds'),
      tables: reader.readStringList('tables'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'token': token,
    'deviceLabel': deviceLabel,
    'serverTimeMilliseconds': serverTimeMilliseconds,
    'tables': tables,
  };
}

class SyncDiffRequest {
  final String table;
  final Map<String, SyncRowStamp> stamps;

  const SyncDiffRequest({required this.table, required this.stamps});

  factory SyncDiffRequest.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'SyncDiffRequest');
    return SyncDiffRequest(table: reader.requireString('table'), stamps: SyncManifest.stampsFromJson(json['stamps']));
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'table': table, 'stamps': SyncManifest.stampsToJson(stamps)};
}

class SyncDiffResponse {
  final List<String> idsToPush;
  final List<String> idsToPull;
  final int skippedCount;
  final int conflictCount;

  const SyncDiffResponse({
    required this.idsToPush,
    required this.idsToPull,
    required this.skippedCount,
    required this.conflictCount,
  });

  factory SyncDiffResponse.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'SyncDiffResponse');
    return SyncDiffResponse(
      idsToPush: reader.readStringList('idsToPush'),
      idsToPull: reader.readStringList('idsToPull'),
      skippedCount: reader.readInt('skippedCount'),
      conflictCount: reader.readInt('conflictCount'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'idsToPush': idsToPush,
    'idsToPull': idsToPull,
    'skippedCount': skippedCount,
    'conflictCount': conflictCount,
  };
}

class SyncPullRequest {
  final String table;
  final List<String> ids;

  const SyncPullRequest({required this.table, required this.ids});

  factory SyncPullRequest.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'SyncPullRequest');
    return SyncPullRequest(table: reader.requireString('table'), ids: reader.readStringList('ids'));
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'table': table, 'ids': ids};
}

class SyncRowsPayload {
  final String table;
  final SyncRowBundle bundle;

  const SyncRowsPayload({required this.table, required this.bundle});

  factory SyncRowsPayload.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'SyncRowsPayload');
    final rows = json['rows'];
    final attachments = reader.readMap('attachments');
    if (rows is! List) {
      throw SyncBadRequestError('Rows payload is missing its rows');
    }
    return SyncRowsPayload(
      table: reader.requireString('table'),
      bundle: SyncRowBundle(
        rows: <Map<String, dynamic>>[
          for (final row in rows)
            if (row is Map) Map<String, dynamic>.from(row),
        ],
        attachments: <String, Uint8List>{
          for (final entry in attachments.entries) entry.key: base64Decode('${entry.value}'),
        },
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'table': table,
    'rows': bundle.rows,
    'attachments': <String, String>{
      for (final entry in bundle.attachments.entries) entry.key: base64Encode(entry.value),
    },
  };
}

class SyncCommitPayload {
  final List<Map<String, dynamic>> reminders;

  const SyncCommitPayload({required this.reminders});

  factory SyncCommitPayload.fromJson(Map<String, dynamic> json) {
    final reminders = json['reminders'];
    return SyncCommitPayload(
      reminders: <Map<String, dynamic>>[
        if (reminders is List)
          for (final reminder in reminders)
            if (reminder is Map) Map<String, dynamic>.from(reminder),
      ],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'reminders': reminders};
}

class SyncErrorBody {
  final String code;
  final String message;
  final int remainingAttempts;

  const SyncErrorBody({required this.code, required this.message, this.remainingAttempts = 0});

  factory SyncErrorBody.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'SyncErrorBody');
    return SyncErrorBody(
      code: reader.readString('code'),
      message: reader.readString('message'),
      remainingAttempts: reader.readInt('remainingAttempts'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'message': message,
    'remainingAttempts': remainingAttempts,
  };
}
