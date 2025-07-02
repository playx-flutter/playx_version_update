import 'package:playx_network/playx_network.dart';

class NetworkClient {
  static PlayxNetworkClient createClient() {
    final dio = PlayxNetworkClient.createDefaultDioClient(baseUrl: '');
    return PlayxNetworkClient(
        dio: dio,
        settings: PlayxNetworkClientSettings(
          logSettings: PlayxNetworkLoggerSettings(
            printResponseData: false,
          ),
          useIsolateForMappingJson: false,
          useWorkMangerForMappingJsonInIsolate: false,
        ));
  }
}
