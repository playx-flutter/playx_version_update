import 'package:playx_version_update/src/core/model/options/playx_network_options.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_error.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_result.dart';
import 'package:playx_version_update/src/core/model/store_info.dart';
import 'package:playx_version_update/src/core/network/exceptions/network_exception.dart';
import 'package:playx_version_update/src/core/network/network_client.dart';

import 'store_error_mapper.dart';
import 'store_response_validator.dart';
import 'store_type.dart';
import 'store_urls.dart';

class RemoteStoreDataSource {
  static final RemoteStoreDataSource _instance =
      RemoteStoreDataSource._internal();

  factory RemoteStoreDataSource() => _instance;

  RemoteStoreDataSource._internal() : _client = NetworkClient();

  /// Creates a data source with a custom [client], mainly for testing.
  RemoteStoreDataSource.withClient(NetworkClient client) : _client = client;

  final NetworkClient _client;

  Future<PlayxVersionUpdateResult<StoreInfo>> getPlayStoreInfo({
    required String packageId,
    required String country,
    required String language,
    bool enableLog = false,
    PlayxNetworkOptions? networkOptions,
  }) {
    return _fetch(
      store: StoreType.googlePlay,
      url: getGooglePlayUrl(
        packageId: packageId,
        country: country,
        language: language,
      ),
      // Google Play serves a localized page and may reject unknown clients.
      headers: {'User-Agent': _browserUserAgent, 'Accept-Language': language},
      parse: StoreInfo.fromGooglePlay,
      enableLog: enableLog,
      networkOptions: networkOptions,
    );
  }

  Future<PlayxVersionUpdateResult<StoreInfo>> getAppStoreInfo({
    required String packageId,
    required String country,
    required String language,
    bool enableLog = false,
    PlayxNetworkOptions? networkOptions,
  }) {
    return _fetch(
      store: StoreType.appStore,
      url: getAppStoreInfoUrl(
        packageId: packageId,
        country: country,
        language: language,
      ),
      parse: StoreInfo.fromAppStore,
      enableLog: enableLog,
      networkOptions: networkOptions,
    );
  }

  Future<PlayxVersionUpdateResult<StoreInfo>> _fetch({
    required StoreType store,
    required String url,
    required StoreInfo Function(dynamic body) parse,
    Map<String, String>? headers,
    bool enableLog = false,
    PlayxNetworkOptions? networkOptions,
  }) async {
    try {
      // A custom Dio is used only for this request, the shared client keeps
      // its default configuration.
      final dio = networkOptions?.dio;
      final client = dio == null ? _client : NetworkClient(dio: dio);
      final response = await client.get(
        url,
        headers: headers,
        enableLog: enableLog,
        options: networkOptions,
      );
      StoreResponseValidator.validate(store, response);
      return PlayxVersionUpdateResult.success(parse(response.body));
    } on NetworkException catch (e) {
      return PlayxVersionUpdateResult.error(
        PlayxVersionNetworkError(StoreErrorMapper.refine(store, e)),
      );
    } catch (e) {
      // The store responded, but its body could not be parsed.
      return PlayxVersionUpdateResult.error(
        PlayxVersionNetworkError(InvalidFormatException(cause: e)),
      );
    }
  }

  static const _browserUserAgent =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36';
}
