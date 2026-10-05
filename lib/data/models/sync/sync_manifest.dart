// lib/data/models/sync/sync_manifest.dart — the id-to-stamp map of every syncable table on one device.

import 'package:equatable/equatable.dart';

import 'sync_row_stamp.dart';

class SyncManifest extends Equatable {
  final Map<String, Map<String, SyncRowStamp>> tables;

  const SyncManifest(this.tables);

  factory SyncManifest.fromJson(Map<String, dynamic> json) {
    return SyncManifest(<String, Map<String, SyncRowStamp>>{
      for (final table in json.entries) table.key: stampsFromJson(table.value),
    });
  }

  static Map<String, SyncRowStamp> stampsFromJson(Object? json) {
    if (json is! Map) {
      throw FormatException('Invalid stamps: $json');
    }
    return <String, SyncRowStamp>{
      for (final entry in json.entries) '${entry.key}': SyncRowStamp.fromJson(entry.value),
    };
  }

  static Map<String, dynamic> stampsToJson(Map<String, SyncRowStamp> stamps) {
    return <String, dynamic>{for (final entry in stamps.entries) entry.key: entry.value.toJson()};
  }

  Map<String, SyncRowStamp> stampsOf(String table) => tables[table] ?? const <String, SyncRowStamp>{};

  int get rowCount => tables.values.fold<int>(0, (total, stamps) => total + stamps.length);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{for (final table in tables.entries) table.key: stampsToJson(table.value)};
  }

  @override
  List<Object?> get props => [tables];
}
