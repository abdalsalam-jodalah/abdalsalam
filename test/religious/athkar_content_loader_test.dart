import 'dart:convert';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/religious/athkar_content.dart';
import 'package:abdalsalam/features/religious/services/athkar_content_loader.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'religious_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LoggerService logger;

  setUpAll(() async {
    await LoggerService.initialize();
    logger = LoggerService.forModule('AthkarContentLoaderTest');
  });

  AthkarContentLoader loaderFor(String? content) {
    return AthkarContentLoader(logger, bundle: FakeAssetBundle(content));
  }

  group('AthkarContentLoader', () {
    test('should load the bundled athkar asset', () async {
      final loader = AthkarContentLoader(logger);

      final contents = await loader.loadBundled();
      final windows = await loader.loadTimeWindows();

      expect(contents.isSuccess, isTrue);
      expect(contents.data, isNotEmpty);
      expect(contents.data!.every((content) => content.isBuiltIn), isTrue);
      expect(windows.data!.keys, containsAll(<String>['morning', 'evening']));
    });

    test('should skip malformed entries and unknown categories while keeping stable ids', () async {
      final loader = loaderFor(jsonEncode(<String, dynamic>{
        'categories': <dynamic>[
          <String, dynamic>{
            'id': 'morning',
            'entries': <dynamic>[
              <String, dynamic>{'arabicText': '', 'targetCount': 1},
              <String, dynamic>{'arabicText': 'valid', 'targetCount': '3'},
              'not-an-object',
              <String, dynamic>{'arabicText': 'no count'},
            ],
          },
          <String, dynamic>{
            'id': 'unknownCategory',
            'entries': <dynamic>[
              <String, dynamic>{'arabicText': 'ignored', 'targetCount': 1},
            ],
          },
          <String, dynamic>{'id': 'evening', 'entries': 'broken'},
        ],
      }));

      final result = await loader.loadBundled();

      expect(result.isSuccess, isTrue);
      final content = result.data!.single;
      expect(content.id, 'builtin-morning-1');
      expect(content.category, AthkarCategory.morning);
      expect(content.targetCount, 3);
      expect(content.sortOrder, 1);
    });

    test('should return a corrupt data failure for invalid JSON', () async {
      final loader = loaderFor('{not json');

      final result = await loader.loadBundled();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<CorruptDataError>());
    });

    test('should return a failure when the categories list is missing', () async {
      final loader = loaderFor(jsonEncode(<String, dynamic>{'version': 1}));

      final result = await loader.loadTimeWindows();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<CorruptDataError>());
    });

    test('should return a failure when the asset cannot be loaded', () async {
      final loader = loaderFor(null);

      final result = await loader.loadBundled();

      expect(result.isFailure, isTrue);
    });

    test('should only return complete time windows', () async {
      final loader = loaderFor(jsonEncode(<String, dynamic>{
        'categories': <dynamic>[
          <String, dynamic>{'id': 'morning', 'timeWindowStart': '04:00', 'timeWindowEnd': '09:00'},
          <String, dynamic>{'id': 'evening', 'timeWindowStart': '16:00'},
        ],
      }));

      final result = await loader.loadTimeWindows();

      expect(result.data!.keys, <String>['morning']);
      expect(result.data!['morning']!.start, '04:00');
    });
  });
}
