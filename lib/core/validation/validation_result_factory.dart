import '../errors/app_error.dart';
import '../result/result.dart';

class ValidationResultFactory {
  static const String failureMessage = 'Validation failed';

  const ValidationResultFactory._();

  static Result<void, AppError> fromFieldErrors(Map<String, String> fieldErrors) {
    if (fieldErrors.isEmpty) {
      return const Success(null);
    }
    return Failure(ValidationError(failureMessage, fieldErrors: fieldErrors));
  }
}
