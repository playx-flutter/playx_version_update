import '../../../../playx_version_update.dart';

sealed class PlayxVersionUpdateResult<T> {
  const PlayxVersionUpdateResult();

  const factory PlayxVersionUpdateResult.success(T data) =
      PlayxVersionUpdateSuccessResult;
  const factory PlayxVersionUpdateResult.error(PlayxVersionUpdateError error) =
      PlayxVersionUpdateErrorResult;

  /// Check if the result is a success.
  bool get isSuccess => this is PlayxVersionUpdateSuccessResult<T>;

  /// Check if the result is an error.
  bool get isError => this is PlayxVersionUpdateErrorResult<T>;


  T? get updateData =>
      switch (this) {
        PlayxVersionUpdateSuccessResult<T> result => result.data,
        PlayxVersionUpdateErrorResult<T> _ => null,
      };


  PlayxVersionUpdateError? get updateError =>
      switch (this) {
        PlayxVersionUpdateSuccessResult<T> _ => null,
        PlayxVersionUpdateErrorResult<T> result => result.error,
      };

  /// Executes the appropriate callback based on the result type.
  R when<R>({
    required R Function(T data) success,
    required R Function(PlayxVersionUpdateError error) error,
  }) =>
      switch (this) {
        PlayxVersionUpdateSuccessResult<T> result => success(result.data),
        PlayxVersionUpdateErrorResult<T> result => error(result.error),
      };

  /// Maps the success data or propagates the error while transforming the type.
  PlayxVersionUpdateResult<S> map<S>({
    required PlayxVersionUpdateResult<S> Function(T data) success,
    required PlayxVersionUpdateResult<S> Function(PlayxVersionUpdateError error)
        error,
  }) =>
      switch (this) {
        PlayxVersionUpdateSuccessResult<T> result => success(result.data),
        PlayxVersionUpdateErrorResult<T> result => error(result.error),
      };

  /// Asynchronous version of `map`, allowing transformations with `Future`.
  Future<PlayxVersionUpdateResult<S>> mapAsync<S>({
    required Future<PlayxVersionUpdateResult<S>> Function(T data) success,
    required Future<PlayxVersionUpdateResult<S>> Function(
            PlayxVersionUpdateError error)
        error,
  }) async =>
      switch (this) {
        PlayxVersionUpdateSuccessResult<T> result => await success(result.data),
        PlayxVersionUpdateErrorResult<T> result => await error(result.error),
      };
}

/// Represents a successful result with associated data.
class PlayxVersionUpdateSuccessResult<T> extends PlayxVersionUpdateResult<T> {
  final T data;
  const PlayxVersionUpdateSuccessResult(this.data);

  /// Creates a copy of this result with a modified data value.
  PlayxVersionUpdateSuccessResult<T> copyWith({T? data}) =>
      PlayxVersionUpdateSuccessResult(data ?? this.data);
}

/// Represents an error result with an associated error.
class PlayxVersionUpdateErrorResult<T> extends PlayxVersionUpdateResult<T> {
  final PlayxVersionUpdateError error;
  const PlayxVersionUpdateErrorResult(this.error);

  /// Creates a copy of this result with a modified error value.
  PlayxVersionUpdateErrorResult<T> copyWith({PlayxVersionUpdateError? error}) =>
      PlayxVersionUpdateErrorResult(error ?? this.error);
}
