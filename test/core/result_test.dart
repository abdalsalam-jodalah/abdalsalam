import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Result<int, AppError> success = Success(2);
  final Result<int, AppError> failure = Failure(NotFoundError('missing'));

  group('Result.map', () {
    test('should transform the value when result is success', () {
      final mapped = success.map((value) => value * 10);

      expect(mapped.data, 20);
    });

    test('should keep the error when result is failure', () {
      final mapped = failure.map((value) => value * 10);

      expect(mapped.error, isA<NotFoundError>());
    });
  });

  group('Result.flatMap', () {
    test('should chain into the next result when result is success', () {
      final chained = success.flatMap<String>((value) => Success('v$value'));

      expect(chained.data, 'v2');
    });

    test('should short-circuit when result is failure', () {
      var isCalled = false;
      final chained = failure.flatMap<String>((value) {
        isCalled = true;
        return Success('v$value');
      });

      expect(isCalled, isFalse);
      expect(chained.isFailure, isTrue);
    });
  });

  group('Result.fold and when', () {
    test('should call onSuccess for success', () {
      expect(success.fold((error) => 'failed', (value) => 'ok $value'), 'ok 2');
    });

    test('should call onFailure for failure', () {
      expect(failure.fold((error) => error.code, (value) => 'ok'), 'NOT_FOUND');
    });
  });

  group('Result.getOrElse and getOrThrow', () {
    test('should return the value when result is success', () {
      expect(success.getOrElse((error) => -1), 2);
      expect(success.getOrThrow(), 2);
    });

    test('should return the fallback when result is failure', () {
      expect(failure.getOrElse((error) => -1), -1);
    });

    test('should throw the typed error when result is failure', () {
      expect(failure.getOrThrow, throwsA(isA<NotFoundError>()));
    });
  });

  group('Result.guard', () {
    test('should wrap a returned value in success', () {
      final result = Result.guard<int, AppError>(
        () => 5,
        onError: (error, stackTrace) => ServiceError('$error'),
      );

      expect(result.data, 5);
    });

    test('should map a thrown exception into failure', () {
      final result = Result.guard<int, AppError>(
        () => throw const FormatException('bad'),
        onError: (error, stackTrace) => CorruptDataError('bad', cause: error),
      );

      expect(result.error, isA<CorruptDataError>());
      expect(result.error?.cause, isA<FormatException>());
    });

    test('should map an async thrown exception into failure', () async {
      final result = await Result.guardAsync<int, AppError>(
        () async => throw StateError('boom'),
        onError: (error, stackTrace) => ServiceError('$error', cause: error, causeStackTrace: stackTrace),
      );

      expect(result.error, isA<ServiceError>());
      expect(result.error?.causeStackTrace, isNotNull);
    });
  });
}
