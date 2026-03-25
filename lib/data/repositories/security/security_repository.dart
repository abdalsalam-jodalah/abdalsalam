import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/security/credential.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class SecurityRepository extends BaseRepository<Credential> {
  Future<Result<List<Credential>, AppError>> getFavorites();
}

class SecurityRepositoryImpl extends BaseRepositoryImpl<Credential>
    implements SecurityRepository {
  SecurityRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'credentials';

  @override
  Credential fromJson(Map<String, dynamic> json) => Credential.fromJson(json);

  @override
  Future<Result<List<Credential>, AppError>> getFavorites() async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }
    return Success(
      all.data!.where((item) => item.favorite).toList(growable: false),
    );
  }
}
