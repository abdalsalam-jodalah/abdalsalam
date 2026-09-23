import '../errors/app_error.dart';

sealed class Result<T, E extends AppError> {
  const Result();

  static Future<Result<T, E>> guardAsync<T, E extends AppError>(
    Future<T> Function() body, {
    required E Function(Object error, StackTrace stackTrace) onError,
  }) async {
    try {
      return Success<T, E>(await body());
    } catch (error, stackTrace) {
      return Failure<T, E>(onError(error, stackTrace));
    }
  }

  static Result<T, E> guard<T, E extends AppError>(
    T Function() body, {
    required E Function(Object error, StackTrace stackTrace) onError,
  }) {
    try {
      return Success<T, E>(body());
    } catch (error, stackTrace) {
      return Failure<T, E>(onError(error, stackTrace));
    }
  }

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T? get data {
    if (this case Success<T, E>(value: final value)) {
      return value;
    }
    return null;
  }

  E? get error {
    if (this case Failure<T, E>(error: final value)) {
      return value;
    }
    return null;
  }

  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) {
    return switch (this) {
      Success<T, E>(value: final value) => success(value),
      Failure<T, E>(error: final error) => failure(error),
    };
  }

  R fold<R>(R Function(E error) onFailure, R Function(T value) onSuccess) {
    return when(success: onSuccess, failure: onFailure);
  }

  Result<R, E> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T, E>(value: final value) => Success<R, E>(transform(value)),
      Failure<T, E>(error: final error) => Failure<R, E>(error),
    };
  }

  Result<R, E> flatMap<R>(Result<R, E> Function(T value) transform) {
    return switch (this) {
      Success<T, E>(value: final value) => transform(value),
      Failure<T, E>(error: final error) => Failure<R, E>(error),
    };
  }

  T getOrElse(T Function(E error) fallback) {
    return switch (this) {
      Success<T, E>(value: final value) => value,
      Failure<T, E>(error: final error) => fallback(error),
    };
  }

  T getOrThrow() {
    return switch (this) {
      Success<T, E>(value: final value) => value,
      Failure<T, E>(error: final error) => throw error,
    };
  }
}

final class Success<T, E extends AppError> extends Result<T, E> {
  final T value;

  const Success(this.value);
}

final class Failure<T, E extends AppError> extends Result<T, E> {
  @override
  final E error;

  const Failure(this.error);
}
