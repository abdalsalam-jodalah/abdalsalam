import '../../models/base_model.dart';

class PrayerTimesSnapshot extends BaseModel {
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
    return PrayerTimesSnapshot(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      dateKey: json['dateKey'] as String,
      forDate: DateTime.parse(json['forDate'] as String),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      sourceUrl: json['sourceUrl'] as String,
      fajr: DateTime.parse(json['fajr'] as String),
      dhuhr: DateTime.parse(json['dhuhr'] as String),
      asr: DateTime.parse(json['asr'] as String),
      maghrib: DateTime.parse(json['maghrib'] as String),
      isha: DateTime.parse(json['isha'] as String),
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
