import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fimber/fimber.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_result.dart';
import 'package:playx_version_update/src/core/network/network_client.dart';

import '../../model/result/playx_version_update_error.dart';

// ignore: avoid_classes_with_only_static_members
/// This class is responsible for handling the network response and extract error from it.
/// and return the result whether it was successful or not.
abstract class ApiHandler {
  static Future<PlayxVersionUpdateResult<T>> handleNetworkResult<T>(
    Response response, {
    JsonMapper<T>? fromJson,
  }) async {
    try {
      final correctCodes = [
        200,
        201,
      ];
      Fimber.d('check version handleNetworkResult  ');

      if (response.statusCode == HttpStatus.badRequest ||
          !correctCodes.contains(response.statusCode)) {
        final PlayxVersionUpdateError error = _handleResponse(response);

        return PlayxVersionUpdateResult.error(error);
      } else {
        final data = response.data;

        if (data == null) {
          Fimber.d('check version handleNetworkResult data == null ');

          return const PlayxVersionUpdateResult.error(NotFoundError());
        }
        try {
          final result = fromJson?.call(data);
          return PlayxVersionUpdateResult.success(result as T);
          // ignore: avoid_catches_without_on_clauses
        } catch (e) {
          Fimber.d('check version handleNetworkResult error :$e ');

          return const PlayxVersionUpdateResult.error(
            NotFoundError(),
          );
        }
        // ignore: avoid_catches_without_on_clauses
      }
    } catch (e) {
      return PlayxVersionUpdateResult.error(
        DefaultFailureError(errorMsg: e.toString()),
      );
    }
  }

  static PlayxVersionUpdateResult<T> handleDioException<T>(dynamic error) {
    return PlayxVersionUpdateResult.error(_getDioException(error));
  }

  static PlayxVersionUpdateError _handleResponse(Response? response) {
    final int statusCode = response?.statusCode ?? 0;
    switch (statusCode) {
      case 404:
        return const NotFoundError();
      case 408:
        return const RequestTimeoutException();
      case 500:
        return const InternalServerErrorException();
      case 503:
        return const ServiceUnavailableException();
      default:
        return DefaultFailureError(
            errorMsg: 'network error with status code $statusCode');
    }
  }

  static PlayxVersionUpdateError _getDioException(dynamic error) {
    if (error is Exception) {
      try {
        PlayxVersionUpdateError networkExceptions = const DefaultFailureError();

        if (error is DioException) {
          networkExceptions = switch (error.type) {
            DioExceptionType.cancel => PlayxRequestCanceledError(),
            DioExceptionType.connectionTimeout =>
              const RequestTimeoutException(),
            DioExceptionType.unknown => error.error is SocketException
                ? const NoInternetConnectionException()
                : const DefaultFailureError(),
            DioExceptionType.receiveTimeout => const SendTimeoutException(),
            DioExceptionType.badResponse => _handleResponse(error.response),
            DioExceptionType.sendTimeout => const SendTimeoutException(),
            DioExceptionType.badCertificate => const DefaultFailureError(
                errorMsg: 'network error bad certificate'),
            DioExceptionType.connectionError =>
              const NoInternetConnectionException(),
          };
        } else if (error is SocketException) {
          networkExceptions = const NoInternetConnectionException();
        } else {
          networkExceptions = const DefaultFailureError();
        }
        return networkExceptions;
      } on FormatException catch (_) {
        return const NotFoundError();
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {
        return const DefaultFailureError();
      }
    } else {
      if (error.toString().contains("is not a subtype of")) {
        return const NotFoundError();
      } else {
        return const DefaultFailureError();
      }
    }
  }
}
