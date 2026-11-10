import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update_example/app_ids.dart';

/// Talks to the real stores, so it needs a network connection.
///
/// ```sh
/// flutter test integration_test -d macos   # or an Android / iOS device
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reads the version of a real app from its store', (tester) async {
    final result = await PlayxVersionUpdate.checkVersion(
      options: const PlayxUpdateOptions(appIds: kStoreAppIds),
    );

    final info = result.updateData;
    expect(info, isNotNull, reason: result.updateError?.message);
    expect(info!.newVersion, isNotEmpty);
    expect(info.storeUrl, isNotEmpty);
    // The example app is older than any published app, so there is an update.
    expect(info.canUpdate, isTrue);
  });

  testWidgets('reports an app that is not on the store', (tester) async {
    final result = await PlayxVersionUpdate.checkVersion(
      options: const PlayxUpdateOptions(appIds: kUnknownAppIds),
    );

    final error = result.updateError;
    expect(error, isA<PlayxVersionNetworkError>());
    expect(error!.errorCode, NetworkErrorCode.appNotFound);
  });
}
