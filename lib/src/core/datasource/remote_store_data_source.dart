import 'package:playx_network/playx_network.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/core/model/store_info.dart';
import 'package:playx_version_update/src/core/network/network_client.dart';

class RemoteStoreDataSource {
  static final RemoteStoreDataSource _instance =
      RemoteStoreDataSource._internal();

  factory RemoteStoreDataSource() {
    return _instance;
  }

  RemoteStoreDataSource._internal();

  final PlayxNetworkClient _client = NetworkClient.createClient();

  Future<NetworkResult<StoreInfo>> getPlayStoreInfo(
      {required String packageId,
      required String country,
      required String language}) {
    final url = getGooglePlayUrl(
        packageId: packageId, country: country, language: language);
    return _client.get(url, fromJson: StoreInfo.fromGooglePlay);
  }

  Future<NetworkResult<StoreInfo>> getAppStoreInfo(
      {required String packageId,
      required String country,
      required String language}) {
    final url = getAppStoreInfoUrl(
        packageId: packageId, country: country, language: language);
    return _client.get(url, fromJson: StoreInfo.fromAppStore);
  }
}

String getGooglePlayUrl(
        {required String packageId,
        required String country,
        required String language}) =>
    "https://play.google.com/store/apps/details?id=$packageId&hl=$language&gl=$country";

String getAppStoreInfoUrl(
        {required String packageId,
        required String country,
        required String language}) =>
    "https://itunes.apple.com/lookup?bundleId=$packageId&country=$country&lang=$language";
