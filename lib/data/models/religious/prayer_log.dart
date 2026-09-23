import '../../../core/json/json_reader.dart';
import '../../../data/models/base_model.dart';

enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

class PrayerLog extends BaseModel {
  static const String _jsonSource = 'PrayerLog';

  final String userId;
  final PrayerName prayerName;
  final DateTime prayedAt;
  final bool onTime;
  final String? notes;
  final DateTime? scheduledAt;

  const PrayerLog({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.prayerName,
    required this.prayedAt,
    required this.onTime,
    this.notes,
    this.scheduledAt,
  });

  factory PrayerLog.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: _jsonSource);
    final createdAt = reader.requireDate('createdAt');
    return PrayerLog(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      prayerName: reader.requireEnum('prayerName', PrayerName.values),
      prayedAt: reader.readDate('prayedAt', fallback: createdAt),
      onTime: reader.readBool('onTime'),
      notes: reader.optionalString('notes'),
      scheduledAt: reader.optionalDate('scheduledAt'),
    );
  }

  PrayerLog copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? userId,
    PrayerName? prayerName,
    DateTime? prayedAt,
    bool? onTime,
    String? notes,
    DateTime? scheduledAt,
  }) {
    return PrayerLog(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      prayerName: prayerName ?? this.prayerName,
      prayedAt: prayedAt ?? this.prayedAt,
      onTime: onTime ?? this.onTime,
      notes: notes ?? this.notes,
      scheduledAt: scheduledAt ?? this.scheduledAt,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'userId': userId,
      'prayerName': prayerName.name,
      'prayedAt': prayedAt.toIso8601String(),
      'onTime': onTime,
      'notes': notes,
      'scheduledAt': scheduledAt?.toIso8601String(),
    };
  }
}
