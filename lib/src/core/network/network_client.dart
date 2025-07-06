import 'package:playx_network/playx_network.dart';

import 'exceptions/network_exceptions_messages.dart';

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
          exceptionMessages: NetworkExceptionsMessages(),
        ));
  }
}
