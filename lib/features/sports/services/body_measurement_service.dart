import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/sports/body_measurement.dart';
import '../../../data/repositories/sports/body_measurement_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class BodyMeasurementService extends BaseServiceImpl<BodyMeasurement> {
  static const String userIdField = 'userId';
  static const String weightKgField = 'weightKg';
  static const String heightCmField = 'heightCm';
  static const String bodyFatPercentField = 'bodyFatPercent';
  static const String chestCmField = 'chestCm';
  static const String waistCmField = 'waistCm';
  static const String abdominalCmField = 'abdominalCm';
  static const String hipsCmField = 'hipsCm';
  static const String thighCmField = 'thighCm';
  static const String armCmField = 'armCm';
  static const double _minBodyFatPercent = 0;
  static const double _maxBodyFatPercent = 100;

  BodyMeasurementService(BodyMeasurementRepository super.repository, super.logger);

  @override
  String get serviceName => 'BodyMeasurementService';

  @override
  String get version => '1.0.0';

  @override
  BodyMeasurement fromJson(Map<String, dynamic> json) => BodyMeasurement.fromJson(json);

  @override
  Result<void, AppError> validate(BodyMeasurement entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(weightKgField, ValidationUtils.positiveNumber(value: entity.weightKg, fieldName: weightKgField)),
        MapEntry(heightCmField, ValidationUtils.positiveNumber(value: entity.heightCm, fieldName: heightCmField)),
        MapEntry(
          bodyFatPercentField,
          ValidationUtils.numericRange(
            value: entity.bodyFatPercent,
            fieldName: bodyFatPercentField,
            min: _minBodyFatPercent,
            max: _maxBodyFatPercent,
          ),
        ),
        MapEntry(chestCmField, ValidationUtils.positiveNumber(value: entity.chestCm, fieldName: chestCmField)),
        MapEntry(waistCmField, ValidationUtils.positiveNumber(value: entity.waistCm, fieldName: waistCmField)),
        MapEntry(
          abdominalCmField,
          ValidationUtils.positiveNumber(value: entity.abdominalCm, fieldName: abdominalCmField),
        ),
        MapEntry(hipsCmField, ValidationUtils.positiveNumber(value: entity.hipsCm, fieldName: hipsCmField)),
        MapEntry(thighCmField, ValidationUtils.positiveNumber(value: entity.thighCm, fieldName: thighCmField)),
        MapEntry(armCmField, ValidationUtils.positiveNumber(value: entity.armCm, fieldName: armCmField)),
      ]),
    );
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final active = await getActive();
    if (active.isFailure) {
      return Failure(active.error!);
    }
    return Success(<String, dynamic>{
      'totalMeasurements': active.data!.length,
    });
  }
}
