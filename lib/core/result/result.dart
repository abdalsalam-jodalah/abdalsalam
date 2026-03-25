sealed class Result<T, E extends Error> {
  const Result();

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
    if (this case Success<T, E>(value: final value)) {
      return success(value);
    }
    return failure((this as Failure<T, E>).error);
  }
}

final class Success<T, E extends Error> extends Result<T, E> {
  final T value;

  const Success(this.value);
}

final class Failure<T, E extends Error> extends Result<T, E> {
  @override
  final E error;

  const Failure(this.error);
}
