import 'package:abdalsalam/core/constants/user_error_messages.dart';
import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/shared/services/user_error_message_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = UserErrorMessageMapper();

  group('UserErrorMessageMapper', () {
    test('should show the first field error for a validation error', () {
      final error = ValidationError('invalid', fieldErrors: {'amount': 'Amount is required'});

      expect(mapper.toUserMessage(error), 'Amount is required');
    });

    test('should never expose the raw technical message', () {
      final error = DatabaseError('SqfliteException(no such table: accounts)');

      final message = mapper.toUserMessage(error);

      expect(message, UserErrorMessages.database);
      expect(message, isNot(contains('Sqflite')));
    });

    test('should map each error type to its friendly message', () {
      expect(mapper.toUserMessage(NotFoundError('x')), UserErrorMessages.notFound);
      expect(mapper.toUserMessage(CorruptDataError('x')), UserErrorMessages.corruptData);
      expect(mapper.toUserMessage(NetworkError('x')), UserErrorMessages.network);
      expect(mapper.toUserMessage(ImportError('x')), UserErrorMessages.import);
      expect(mapper.toUserMessage(ExportError('x')), UserErrorMessages.export);
    });

    test('should fall back to the generic message for non-AppError values', () {
      expect(mapper.toUserMessage(StateError('boom')), UserErrorMessages.generic);
    });
  });
}
