import 'dart:convert';

import 'package:abdalsalam/data/models/religious/athkar_content.dart';
import 'package:abdalsalam/data/repositories/religious/athkar_content_repository.dart';
import 'package:abdalsalam/data/repositories/religious/athkar_log_repository.dart';
import 'package:abdalsalam/features/religious/services/athkar_content_loader.dart';
import 'package:abdalsalam/features/religious/services/athkar_service.dart';
import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'religious_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final storage = StorageGateway.instance;
  late LoggerService logger;

  String assetWith(List<Map<String, dynamic>> categories) {
    return jsonEncode(<String, dynamic>{'categories': categories});
  }

  AthkarService buildService(String? assetContent) {
    return AthkarService(
      AthkarContentRepository(storage, logger),
      AthkarLogRepository(storage, logger),
      logger,
      reminders: FakeReminderService(),
      settings: SettingsService(storage),
      loader: AthkarContentLoader(logger, bundle: FakeAssetBundle(assetContent)),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_athkar_service_test.db');
    await DatabaseSchemaInitializer.initialize(storage);
    await storage.clearTable('athkar_content');
    await storage.clearTable('athkar_logs');
    logger = LoggerService.forModule('AthkarServiceTest');
  });

  group('AthkarService', () {
    test('should seed bundled content and return it merged', () async {
      final service = buildService(assetWith(<Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'morning',
          'entries': <dynamic>[
            <String, dynamic>{'arabicText': 'first', 'targetCount': 1},
          ],
        },
      ]));

      final result = await service.getMerged();

      expect(result.isSuccess, isTrue);
      expect(result.data!.map((content) => content.id), <String>['builtin-morning-0']);
    });

    test('should return failure instead of throwing when bundled content cannot load', () async {
      final service = buildService(null);

      final merged = await service.getMerged(category: AthkarCategory.morning);
      final dueNow = await service.getCategoriesForNow();

      expect(merged.isFailure, isTrue);
      expect(dueNow.isFailure, isTrue);
    });

    test('should ignore invalid stored time windows when finding due categories', () async {
      final service = buildService(assetWith(<Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'morning',
          'timeWindowStart': '00:00',
          'timeWindowEnd': '23:59',
          'entries': <dynamic>[],
        },
        <String, dynamic>{
          'id': 'evening',
          'timeWindowStart': '25:00',
          'timeWindowEnd': 'late',
          'entries': <dynamic>[],
        },
      ]));

      final result = await service.getCategoriesForNow();

      expect(result.isSuccess, isTrue);
      expect(result.data, <AthkarCategory>[AthkarCategory.morning]);
    });
  });

  group('TimeOfDayMinutes.tryParse', () {
    test('should parse a valid HH:mm value', () {
      final parsed = TimeOfDayMinutes.tryParse('09:45');

      expect(parsed!.minutes, 9 * 60 + 45);
      expect(parsed.hour, 9);
      expect(parsed.minute, 45);
    });

    test('should return null for malformed or out-of-range values', () {
      final inputs = <String>['', '0945', 'ab:cd', '24:00', '12:60', '-1:30', '1:2:3'];

      final parsed = inputs.map(TimeOfDayMinutes.tryParse);

      expect(parsed, everyElement(isNull));
    });
  });
}
