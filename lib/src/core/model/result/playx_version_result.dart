import 'package:playx_version_update/src/core/model/result/playx_version_error.dart';

class Success<T> extends PlayxVersionResult<T> {
  final T data;

  const Success(this.data);
}

class Error<T> extends PlayxVersionResult<T> {
  final PlayxVersionError error;

  const Error(this.error);
}

/// Generic Wrapper class for the PlayxVersionResult of any type.
sealed class PlayxVersionResult<T> {
  const PlayxVersionResult();

  const factory PlayxVersionResult.success(T data) = Success;

  const factory PlayxVersionResult.error(PlayxVersionError error) = Error;

  PlayxVersionResult<T> when({
    required Function(T success) success,
    required Function(PlayxVersionError error) error,
  }) {
    switch (this) {
      case Success _:
        final data = (this as Success<T>).data;
        success(data);
        return Success(data);
      case Error _:
        final exception = (this as Error<T>).error;
        error(exception);
        return Error(exception);
    }
  }

  PlayxVersionResult<S> map<S>({
    required PlayxVersionResult<S> Function(Success<T> data) success,
    required PlayxVersionResult<S> Function(Error<T> error) error,
  }) {
    switch (this) {
      case Success _:
        return success(this as Success<T>);
      case Error _:
        return error(this as Error<T>);
    }
  }

  Future<PlayxVersionResult<S>> mapAsync<S>({
    required Future<PlayxVersionResult<S>> Function(Success<T> data) success,
    required Future<PlayxVersionResult<S>> Function(Error<T> error) error,
  }) async {
    switch (this) {
      case Success _:
        return success(this as Success<T>);
      case Error _:
        return error(this as Error<T>);
    }
  }
}
