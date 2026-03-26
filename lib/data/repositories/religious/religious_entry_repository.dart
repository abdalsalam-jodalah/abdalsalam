import '../../models/religious/religious_entry.dart';
import '../base_repository_impl.dart';

class ReligiousEntryRepository extends BaseRepositoryImpl<ReligiousEntry> {
  ReligiousEntryRepository(super.storage, super.logger);

  @override
  String get tableName => 'religious_entries';

  @override
  ReligiousEntry fromJson(Map<String, dynamic> json) {
    return ReligiousEntry.fromJson(json);
  }
}
