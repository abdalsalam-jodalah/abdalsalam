import 'dart:async';
import 'dart:io';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/services/error_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ErrorHandler handler;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    handler = ErrorHandler(LoggerService.forModule('ErrorHandlerTest'));
  });

  group('ErrorHandler.mapException', () {
    test('should return an AppError unchanged', () {
      final original = NotFoundError('missing');

      expect(handler.mapException(original, context: 'test'), same(original));
    });

    test('should map FormatException to CorruptDataError and keep the cause', () {
      const cause = FormatException('bad json');

      final mapped = handler.mapException(cause, context: 'test');

      expect(mapped, isA<CorruptDataError>());
      expect(mapped.cause, same(cause));
    });

    test('should map network exceptions to NetworkError', () {
      expect(handler.mapException(TimeoutException('slow'), context: 'test'), isA<NetworkError>());
      expect(handler.mapException(const SocketException('down'), context: 'test'), isA<NetworkError>());
      expect(handler.mapException(http.ClientException('down'), context: 'test'), isA<NetworkError>());
    });

    test('should map an unknown exception to ServiceError with its stack trace', () {
      final stackTrace = StackTrace.current;

      final mapped = handler.mapException(StateError('boom'), context: 'test', stackTrace: stackTrace);

      expect(mapped, isA<ServiceError>());
      expect(mapped.causeStackTrace, same(stackTrace));
    });

    test('should not match on message text', () {
      final mapped = handler.mapException(Exception('invalid network database'), context: 'test');

      expect(mapped, isA<ServiceError>());
    });
  });
}
