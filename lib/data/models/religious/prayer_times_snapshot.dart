import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

class PrayerTimesSnapshot extends BaseModel {
  static const String _jsonSource = 'PrayerTimesSnapshot';

  final String dateKey;
  final DateTime forDate;
  final DateTime fetchedAt;
  final String sourceUrl;
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const PrayerTimesSnapshot({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.dateKey,
    required this.forDate,
    required this.fetchedAt,
    required this.sourceUrl,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory PrayerTimesSnapshot.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: _jsonSource);
    final createdAt = reader.requireDate('createdAt');
    return PrayerTimesSnapshot(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      dateKey: reader.requireString('dateKey'),
      forDate: reader.requireDate('forDate'),
      fetchedAt: reader.readDate('fetchedAt', fallback: createdAt),
      sourceUrl: reader.readString('sourceUrl'),
      fajr: reader.requireDate('fajr'),
      dhuhr: reader.requireDate('dhuhr'),
      asr: reader.requireDate('asr'),
      maghrib: reader.requireDate('maghrib'),
      isha: reader.requireDate('isha'),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'dateKey': dateKey,
      'forDate': forDate.toIso8601String(),
      'fetchedAt': fetchedAt.toIso8601String(),
      'sourceUrl': sourceUrl,
      'fajr': fajr.toIso8601String(),
      'dhuhr': dhuhr.toIso8601String(),
      'asr': asr.toIso8601String(),
      'maghrib': maghrib.toIso8601String(),
      'isha': isha.toIso8601String(),
    };
  }
}
