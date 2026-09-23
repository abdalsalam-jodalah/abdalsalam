import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/religious/athkar_content.dart';
import '../base_repository_impl.dart';

class AthkarContentRepository extends BaseRepositoryImpl<AthkarContent> {
  AthkarContentRepository(super.storage, super.logger);

  @override
  String get tableName => 'athkar_content';

  @override
  AthkarContent fromJson(Map<String, dynamic> json) {
    return AthkarContent.fromJson(json);
  }

  Future<Result<List<AthkarContent>, AppError>> getByCategory(AthkarCategory category) {
    return query(<String, dynamic>{'category': category.name});
  }

  Future<Result<List<AthkarContent>, AppError>> getCustomOnly() {
    return query(<String, dynamic>{'isCustom': true});
  }

  Future<Result<List<AthkarContent>, AppError>> getBuiltInOnly() {
    return query(<String, dynamic>{'isBuiltIn': true});
  }

  /// Idempotently inserts bundled entries that don't already exist.
  /// Bundled entries must carry deterministic ids (e.g. `builtin-<category>-<index>`)
  /// so re-seeding on app upgrade never duplicates rows.
  Future<Result<void, AppError>> seedFromAsset(List<AthkarContent> bundled) {
    return guardStorage('seedFromAsset', () {
      return storage.runInTransaction(() async {
        final missing = <AthkarContent>[];
        for (final entry in bundled) {
          final existing = await storage.getRecord(table: tableName, id: entry.id);
          if (existing == null) {
            missing.add(entry);
          }
        }
        if (missing.isEmpty) {
          return;
        }
        final created = await createBulk(missing);
        if (created.isFailure) {
          throw created.error!;
        }
      });
    });
  }
}
