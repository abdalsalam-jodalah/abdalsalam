import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/base_model.dart';
import 'package:abdalsalam/data/repositories/base_repository.dart';

const String fakeWriteFailureMessage = 'fake write failure';

mixin FailingWrites<T extends BaseModel> on BaseRepository<T> {
  @override
  Future<Result<T, AppError>> create(T entity) async => Failure(DatabaseError(fakeWriteFailureMessage));

  @override
  Future<Result<void, AppError>> update(T entity) async => Failure(DatabaseError(fakeWriteFailureMessage));

  @override
  Future<Result<void, AppError>> updateBulk(List<T> entities) async =>
      Failure(DatabaseError(fakeWriteFailureMessage));

  @override
  Future<Result<void, AppError>> softDelete(String id) async => Failure(DatabaseError(fakeWriteFailureMessage));
}
