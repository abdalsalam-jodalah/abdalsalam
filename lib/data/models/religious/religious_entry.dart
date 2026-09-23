import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

enum ReligiousEntryType { prayer, quranReading, badEvent, athkar, nightPrayer }

class ReligiousEntry extends BaseModel {
  static const String _jsonSource = 'ReligiousEntry';
  static const int _defaultCount = 1;

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
    final reader = JsonReader(json, source: _jsonSource);
    final createdAt = reader.requireDate('createdAt');
    return ReligiousEntry(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      type: reader.requireEnum('type', ReligiousEntryType.values),
      loggedAt: reader.readDate('loggedAt', fallback: createdAt),
      title: reader.readString('title'),
      details: reader.optionalString('details'),
      count: reader.readInt('count', fallback: _defaultCount),
      reminderAt: reader.optionalDate('reminderAt'),
      prayerName: reader.optionalString('prayerName'),
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
