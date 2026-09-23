import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void expectFieldError(Result<void, AppError> result, String field) {
  expect(result.isFailure, isTrue);
  final error = result.error;
  expect(error, isA<ValidationError>());
  expect((error as ValidationError).fieldErrors.keys, contains(field));
}

void expectWriteFailure(Result<Object?, AppError> result) {
  expect(result.isFailure, isTrue);
  expect(result.error, isA<DatabaseError>());
}
