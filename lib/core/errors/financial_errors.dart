class FinancialError extends Error {
  final String message;
  final String? code;

  FinancialError(this.message, {this.code});

  @override
  String toString() => 'FinancialError: $message${code != null ? ' ($code)' : ''}';
}

class DatabaseError extends FinancialError {
  DatabaseError(super.message) : super(code: 'DATABASE_ERROR');
}

class NotFoundError extends FinancialError {
  NotFoundError(super.message) : super(code: 'NOT_FOUND');
}

class ValidationError extends FinancialError {
  ValidationError(super.message) : super(code: 'VALIDATION_ERROR');
}
