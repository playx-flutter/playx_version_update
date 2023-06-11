import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fimber/fimber.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_error.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_result.dart';
import 'package:playx_version_update/src/core/network/network_client.dart';

// ignore: avoid_classes_with_only_static_members
/// This class is responsible for handling the network response and extract error from it.
/// and return the result whether it was successful or not.
abstract class ApiHandler {
  static Future<PlayxVersionResult<T>> handleNetworkResult<T>(
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
        final PlayxVersionError error = _handleResponse(response);

        return PlayxVersionResult.error(error);
      } else {
        final data = response.data;

        if (data == null) {
          Fimber.d('check version handleNetworkResult data == null ');

          return const PlayxVersionResult.error(NotFoundError());
        }
        try {
          final result = fromJson?.call(data);
          return PlayxVersionResult.success(result as T);
          // ignore: avoid_catches_without_on_clauses
        } catch (e) {
          Fimber.d('check version handleNetworkResult error :$e ');

          return const PlayxVersionResult.error(
            NotFoundError(),
          );
        }
        // ignore: avoid_catches_without_on_clauses
      }
    } catch (e) {
      return const PlayxVersionResult.error(
        UnknownError(),
      );
    }
  }

  static PlayxVersionResult<T> handleDioException<T>(dynamic error) {
    return PlayxVersionResult.error(_getDioException(error));
  }

  static PlayxVersionError _handleResponse(Response? response) {
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
        return const UnknownError();
    }
  }

  static PlayxVersionError _getDioException(dynamic error) {
    if (error is Exception) {
      try {
        PlayxVersionError networkExceptions = const UnknownError();

        if (error is DioException) {
          networkExceptions = switch (error.type) {
            DioExceptionType.cancel => const RequestCanceledException(),
            DioExceptionType.connectionTimeout =>
              const RequestTimeoutException(),
            DioExceptionType.unknown => error.error is SocketException
                ? const NoInternetConnectionException()
                : const UnknownError(),
            DioExceptionType.receiveTimeout => const SendTimeoutException(),
            DioExceptionType.badResponse => _handleResponse(error.response),
            DioExceptionType.sendTimeout => const SendTimeoutException(),
            DioExceptionType.badCertificate => const UnknownError(),
            DioExceptionType.connectionError =>
              const NoInternetConnectionException(),
          };
        } else if (error is SocketException) {
          networkExceptions = const NoInternetConnectionException();
        } else {
          networkExceptions = const UnknownError();
        }
        return networkExceptions;
      } on FormatException catch (_) {
        return const NotFoundError();
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {
        return const UnknownError();
      }
    } else {
      if (error.toString().contains("is not a subtype of")) {
        return const NotFoundError();
      } else {
        return const UnknownError();
      }
    }
  }
}
