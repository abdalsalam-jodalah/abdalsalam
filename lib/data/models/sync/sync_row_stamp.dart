// lib/data/models/sync/sync_row_stamp.dart — the last-modified marker and tombstone flag of one stored row.

import 'package:equatable/equatable.dart';

class SyncRowStamp extends Equatable {
  static const int _jsonLength = 2;
  static const int _updatedAtIndex = 0;
  static const int _isDeletedIndex = 1;

  final String updatedAt;
  final bool isDeleted;

  const SyncRowStamp({required this.updatedAt, required this.isDeleted});

  factory SyncRowStamp.fromRow(Map<String, dynamic> row) {
    final updatedAt = row['updatedAt'];
    return SyncRowStamp(
      updatedAt: updatedAt is String ? updatedAt : '',
      isDeleted: row['deletedAt'] != null,
    );
  }

  factory SyncRowStamp.fromJson(Object? json) {
    if (json is! List || json.length != _jsonLength) {
      throw FormatException('Invalid row stamp: $json');
    }
    final updatedAt = json[_updatedAtIndex];
    final isDeleted = json[_isDeletedIndex];
    if (updatedAt is! String || isDeleted is! bool) {
      throw FormatException('Invalid row stamp: $json');
    }
    return SyncRowStamp(updatedAt: updatedAt, isDeleted: isDeleted);
  }

  DateTime? get updatedAtTime => DateTime.tryParse(updatedAt);

  List<Object> toJson() => <Object>[updatedAt, isDeleted];

  @override
  List<Object?> get props => [updatedAt, isDeleted];
}
