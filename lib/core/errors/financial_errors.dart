import 'app_error.dart';
import 'app_error_code.dart';

class FinancialError extends AppError {
  FinancialError(
    super.message, {
    super.code = AppErrorCode.financial,
    super.cause,
    super.causeStackTrace,
  });
}
