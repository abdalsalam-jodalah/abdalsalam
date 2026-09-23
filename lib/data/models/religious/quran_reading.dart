import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

class QuranReading extends BaseModel {
  static const String _jsonSource = 'QuranReading';

  final String userId;
  final int surahNumber;
  final int ayahFrom;
  final int ayahTo;
  final DateTime readAt;
  final int durationMinutes;
  final bool memorized;
  final int pagesRead;
  final String? place;

  const QuranReading({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.surahNumber,
    required this.ayahFrom,
    required this.ayahTo,
    required this.readAt,
    required this.durationMinutes,
    required this.memorized,
    required this.pagesRead,
    this.place,
  });

  factory QuranReading.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: _jsonSource);
    final createdAt = reader.requireDate('createdAt');
    return QuranReading(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      surahNumber: reader.requireInt('surahNumber'),
      ayahFrom: reader.requireInt('ayahFrom'),
      ayahTo: reader.requireInt('ayahTo'),
      readAt: reader.readDate('readAt', fallback: createdAt),
      durationMinutes: reader.readInt('durationMinutes'),
      memorized: reader.readBool('memorized'),
      pagesRead: reader.readInt('pagesRead'),
      place: reader.optionalString('place'),
    );
  }

  QuranReading copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? userId,
    int? surahNumber,
    int? ayahFrom,
    int? ayahTo,
    DateTime? readAt,
    int? durationMinutes,
    bool? memorized,
    int? pagesRead,
    String? place,
  }) {
    return QuranReading(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahFrom: ayahFrom ?? this.ayahFrom,
      ayahTo: ayahTo ?? this.ayahTo,
      readAt: readAt ?? this.readAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      memorized: memorized ?? this.memorized,
      pagesRead: pagesRead ?? this.pagesRead,
      place: place ?? this.place,
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
      'surahNumber': surahNumber,
      'ayahFrom': ayahFrom,
      'ayahTo': ayahTo,
      'readAt': readAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'memorized': memorized,
      'pagesRead': pagesRead,
      'place': place,
    };
  }
}
