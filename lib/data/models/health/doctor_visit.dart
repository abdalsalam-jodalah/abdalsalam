import '../../../core/json/json_reader.dart';
import '../base_model.dart';

class DoctorVisit extends BaseModel {
  final String userId;
  final String doctorName;
  final String? specialty;
  final DateTime visitDate;
  final String reason;
  final String? diagnosis;
  final List<String> medicationIds;
  final List<String> attachmentPaths;
  final DateTime? followUpDate;
  final String? notes;

  const DoctorVisit({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.doctorName,
    this.specialty,
    required this.visitDate,
    required this.reason,
    this.diagnosis,
    this.medicationIds = const [],
    this.attachmentPaths = const [],
    this.followUpDate,
    this.notes,
  });

  factory DoctorVisit.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'DoctorVisit');
    final createdAt = reader.requireDate('createdAt');
    return DoctorVisit(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      doctorName: reader.readString('doctorName'),
      specialty: reader.optionalString('specialty'),
      visitDate: reader.readDate('visitDate', fallback: createdAt),
      reason: reader.readString('reason'),
      diagnosis: reader.optionalString('diagnosis'),
      medicationIds: reader.readStringList('medicationIds'),
      attachmentPaths: reader.readStringList('attachmentPaths'),
      followUpDate: reader.optionalDate('followUpDate'),
      notes: reader.optionalString('notes'),
    );
  }

  DoctorVisit copyWith({
    String? userId,
    String? doctorName,
    String? specialty,
    DateTime? visitDate,
    String? reason,
    String? diagnosis,
    List<String>? medicationIds,
    List<String>? attachmentPaths,
    DateTime? followUpDate,
    String? notes,
    DateTime? updatedAt,
  }) =>
      DoctorVisit(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt,
        userId: userId ?? this.userId,
        doctorName: doctorName ?? this.doctorName,
        specialty: specialty ?? this.specialty,
        visitDate: visitDate ?? this.visitDate,
        reason: reason ?? this.reason,
        diagnosis: diagnosis ?? this.diagnosis,
        medicationIds: medicationIds ?? this.medicationIds,
        attachmentPaths: attachmentPaths ?? this.attachmentPaths,
        followUpDate: followUpDate ?? this.followUpDate,
        notes: notes ?? this.notes,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'doctorName': doctorName,
        'specialty': specialty,
        'visitDate': visitDate.toIso8601String(),
        'reason': reason,
        'diagnosis': diagnosis,
        'medicationIds': medicationIds,
        'attachmentPaths': attachmentPaths,
        'followUpDate': followUpDate?.toIso8601String(),
        'notes': notes,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        doctorName,
        specialty,
        visitDate,
        reason,
        diagnosis,
        medicationIds,
        attachmentPaths,
        followUpDate,
        notes,
      ];
}
