import '../../models/sports/body_measurement.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class BodyMeasurementRepository extends BaseRepository<BodyMeasurement> {}

class BodyMeasurementRepositoryImpl extends BaseRepositoryImpl<BodyMeasurement>
    implements BodyMeasurementRepository {
  BodyMeasurementRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'sport_body_measurements';

  @override
  BodyMeasurement fromJson(Map<String, dynamic> json) => BodyMeasurement.fromJson(json);
}
