import '../../models/base_model.dart';

enum ReligiousEntryType { prayer, quranReading, badEvent, athkar, nightPrayer }

class ReligiousEntry extends BaseModel {
  final String userId;
  final ReligiousEntryType type;
  final DateTime loggedAt;
  final String title;
  final String? details;
  final int count;
  final DateTime? reminderAt;
  final String? prayerName;

  const ReligiousEntry({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.type,
    required this.loggedAt,
    required this.title,
    this.details,
    required this.count,
    this.reminderAt,
    this.prayerName,
  });

  factory ReligiousEntry.fromJson(Map<String, dynamic> json) {
    return ReligiousEntry(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      type: ReligiousEntryType.values.byName(json['type'] as String),
      loggedAt: DateTime.parse(json['loggedAt'] as String),
      title: json['title'] as String,
      details: json['details'] as String?,
      count: (json['count'] as num?)?.toInt() ?? 1,
      reminderAt: json['reminderAt'] == null
          ? null
          : DateTime.parse(json['reminderAt'] as String),
      prayerName: json['prayerName'] as String?,
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
      'type': type.name,
      'loggedAt': loggedAt.toIso8601String(),
      'title': title,
      'details': details,
      'count': count,
      'reminderAt': reminderAt?.toIso8601String(),
      'prayerName': prayerName,
    };
  }
}
