import 'package:playx_version_update/src/core/model/result/playx_version_result.dart';
import 'package:playx_version_update/src/core/model/store_info.dart';
import 'package:playx_version_update/src/core/network/network_client.dart';

class RemoteStoreDataSource {
  static final RemoteStoreDataSource _instance =
      RemoteStoreDataSource._internal();

  factory RemoteStoreDataSource() {
    return _instance;
  }

  RemoteStoreDataSource._internal();

  final NetworkClient client = NetworkClient();

  Future<PlayxVersionResult<StoreInfo>> getPlayStoreInfo(
      {required String packageId,
      required String country,
      required String language}) {
    final url = getGooglePlayUrl(
        packageId: packageId, country: country, language: language);
    return client.get(url, fromJson: StoreInfo.fromGooglePlay);
  }

  Future<PlayxVersionResult<StoreInfo>> getAppStoreInfo(
      {required String packageId,
      required String country,
      required String language}) {
    final url = getAppStoreInfoUrl(
        packageId: packageId, country: country, language: language);
    return client.get(url, fromJson: StoreInfo.fromAppStore);
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
