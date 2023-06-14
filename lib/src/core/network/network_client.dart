import 'package:dio/dio.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_result.dart';
import 'package:playx_version_update/src/core/network/handler/api_handler.dart';

typedef JsonMapper<T> = T Function(dynamic json);

class NetworkClient {
  static final NetworkClient _instance = NetworkClient._internal();

  factory NetworkClient() {
    return _instance;
  }

  NetworkClient._internal();

  final dio = Dio(
    BaseOptions(
      validateStatus: (_) => true,
      followRedirects: true,
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
    ),
  )..interceptors.add(LogInterceptor());

  /// sends a [GET] request to the given [url]
  /// and returns object of Type [T] not list
  Future<PlayxVersionUpdateResult<T>> get<T>(
    String path, {
    required JsonMapper<T>? fromJson,
  }) async {
    try {
      final res = await dio.get(
        path,
      );
      return ApiHandler.handleNetworkResult(
        res,
        fromJson: fromJson,
      );
      // ignore: avoid_catches_without_on_clauses
    } catch (error) {
      return ApiHandler.handleDioException(error);
    }
  }
}
