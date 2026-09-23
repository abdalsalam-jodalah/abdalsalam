import '../../core/errors/app_error.dart';
import '../infrastructure/storage_gateway.dart';

class DailyRunMarker {
  static const String _preferencesSource = 'preferences';
  static const int _twoDigitWidth = 2;
  static const String _datePadding = '0';

  final StorageGateway storage;
  final String storageKey;

  const DailyRunMarker({required this.storage, required this.storageKey});

  Future<bool> hasRunOn(DateTime date) async {
    return await _readLastRunDateKey() == _dateKey(date);
  }

  Future<void> markRunOn(DateTime date) {
    return storage.save(key: storageKey, value: _dateKey(date));
  }

  Future<String?> _readLastRunDateKey() async {
    try {
      return await storage.get<String>(storageKey);
    } on CorruptDataError catch (error, stackTrace) {
      storage.integrityReporter.reportCorruptRecord(
        table: _preferencesSource,
        recordId: storageKey,
        reason: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(_twoDigitWidth, _datePadding);
    final day = date.day.toString().padLeft(_twoDigitWidth, _datePadding);
    return '${date.year}-$month-$day';
  }
}
