import 'package:playx_version_update/src/core/model/result/playx_version_update_error.dart';

class Success<T> extends PlayxVersionUpdateResult<T> {
  final T data;

  const Success(this.data);
}

class Error<T> extends PlayxVersionUpdateResult<T> {
  final PlayxVersionUpdateError error;

  const Error(this.error);
}

/// Generic Wrapper class for the PlayxVersionResult of any type.
sealed class PlayxVersionUpdateResult<T> {
  const PlayxVersionUpdateResult();

  const factory PlayxVersionUpdateResult.success(T data) = Success;

  const factory PlayxVersionUpdateResult.error(PlayxVersionUpdateError error) =   Error;

  PlayxVersionUpdateResult<T> when({
    required Function(T success) success,
    required Function(PlayxVersionUpdateError error) error,
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

  PlayxVersionUpdateResult<S> map<S>({
    required PlayxVersionUpdateResult<S> Function(Success<T> data) success,
    required PlayxVersionUpdateResult<S> Function(Error<T> error) error,
  }) {
    switch (this) {
      case Success _:
        return success(this as Success<T>);
      case Error _:
        return error(this as Error<T>);
    }
  }

  Future<PlayxVersionUpdateResult<S>> mapAsync<S>({
    required Future<PlayxVersionUpdateResult<S>> Function(Success<T> data)
        success,
    required Future<PlayxVersionUpdateResult<S>> Function(Error<T> error) error,
  }) async {
    switch (this) {
      case Success _:
        return success(this as Success<T>);
      case Error _:
        return error(this as Error<T>);
    }
  }
}
