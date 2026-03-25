import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/calendar/event.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class CalendarRepository extends BaseRepository<Event> {
  Future<Result<List<Event>, AppError>> getUpcoming(DateTime from);
}

class CalendarRepositoryImpl extends BaseRepositoryImpl<Event>
    implements CalendarRepository {
  CalendarRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'events';

  @override
  Event fromJson(Map<String, dynamic> json) => Event.fromJson(json);

  @override
  Future<Result<List<Event>, AppError>> getUpcoming(DateTime from) async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }
    final upcoming = all.data!
        .where((item) => !item.startTime.isBefore(from))
        .toList(growable: false)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return Success(upcoming);
  }
}
