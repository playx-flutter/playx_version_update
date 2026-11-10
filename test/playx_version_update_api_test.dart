import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/platform/playx_version_update_platform_interface.dart';

/// Records the calls made to the platform and returns configured results.
class _FakePlatform extends PlayxVersionUpdatePlatform {
  final calls = <String>[];
  bool flexibleWaiting = false;
  PlayxVersionUpdateResult<bool> startResult =
      const PlayxVersionUpdateResult.success(true);
  final downloads = StreamController<PlayxDownloadInfo?>.broadcast();

  @override
  Future<PlayxVersionUpdateResult<PlayxAppUpdateAvailability>>
  getUpdateAvailability() async {
    calls.add('availability');
    return const PlayxVersionUpdateResult.success(
      PlayxAppUpdateAvailability.available,
    );
  }

  @override
  Future<PlayxVersionUpdateResult<int>> getUpdateStalenessDays() async {
    calls.add('staleness');
    return const PlayxVersionUpdateResult.success(3);
  }

  @override
  Future<PlayxVersionUpdateResult<int>> getUpdatePriority() async {
    calls.add('priority');
    return const PlayxVersionUpdateResult.success(4);
  }

  @override
  Future<PlayxVersionUpdateResult<bool>> isUpdateAllowed(
    PlayxAppUpdateType type,
  ) async {
    calls.add('allowed:${type.name}');
    return const PlayxVersionUpdateResult.success(true);
  }

  @override
  Future<PlayxVersionUpdateResult<bool>> startImmediateUpdate() async {
    calls.add('immediate');
    return startResult;
  }

  @override
  Future<PlayxVersionUpdateResult<bool>> startFlexibleUpdate() async {
    calls.add('flexible');
    return startResult;
  }

  @override
  Stream<PlayxDownloadInfo?> getDownloadInfo() => downloads.stream;

  @override
  Future<PlayxVersionUpdateResult<bool>> completeFlexibleUpdate() async {
    calls.add('complete');
    return const PlayxVersionUpdateResult.success(true);
  }

  @override
  Future<PlayxVersionUpdateResult<bool>>
  isFlexibleUpdateNeedToBeInstalled() async {
    calls.add('needsInstall');
    return PlayxVersionUpdateResult.success(flexibleWaiting);
  }

  @override
  Future<PlayxVersionUpdateResult<bool>> refreshInAppUpdate() async {
    calls.add('refresh');
    return const PlayxVersionUpdateResult.success(true);
  }
}

const _launcherChannel = MethodChannel('plugins.flutter.io/url_launcher');

const _newVersion = PlayxStaticVersionSource(
  version: PlayxPlatformVersion(
    android: '2.0.0',
    ios: '2.0.0',
    macos: '2.0.0',
    windows: '2.0.0',
  ),
  releaseNotes: PlayxPlatformValue(android: 'Android notes', ios: 'iOS notes'),
  storeUrls: PlayxPlatformValue(
    android: 'https://play.google.com/store/apps/details?id=a.b',
    ios: 'https://apps.apple.com/app/id1',
    macos: 'https://apps.apple.com/app/id2?mt=12',
  ),
);

PlayxUpdateOptions _options({
  PlayxVersionSource source = _newVersion,
  bool? forceUpdate,
  String? minVersion,
}) => PlayxUpdateOptions(
  versionSource: source,
  forceUpdate: forceUpdate,
  minVersion: minVersion,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late _FakePlatform fake;
  late PlayxVersionUpdatePlatform original;
  late List<MethodCall> launches;

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Example',
      packageName: 'a.b',
      version: '1.0.0',
      buildNumber: '7',
      buildSignature: '',
    );
    original = PlayxVersionUpdatePlatform.instance;
    fake = _FakePlatform();
    PlayxVersionUpdatePlatform.instance = fake;
    PlayxPlatform.debugSetCurrent(PlayxPlatform.android);

    launches = [];
    messenger.setMockMethodCallHandler(_launcherChannel, (call) async {
      launches.add(call);
      return true;
    });
  });

  tearDown(() {
    PlayxVersionUpdatePlatform.instance = original;
    PlayxPlatform.debugResetCurrent();
    messenger.setMockMethodCallHandler(_launcherChannel, null);
  });

  group('app info', () {
    test('reads the version and the build number', () async {
      expect(await PlayxVersionUpdate.getAppVersion(), '1.0.0');
      expect(await PlayxVersionUpdate.getAppBuildNumber(), '7');
    });
  });

  group('checkVersion', () {
    test('uses the version source and compares with the app version', () async {
      final info = (await PlayxVersionUpdate.checkVersion(
        options: _options(),
      )).updateData!;

      expect(info.localVersion, '1.0.0');
      expect(info.newVersion, '2.0.0');
      expect(info.canUpdate, isTrue);
      expect(info.forceUpdate, isFalse);
      expect(info.releaseNotes, 'Android notes');
    });

    test('localVersion in the options overrides the installed version', () async {
      final info = (await PlayxVersionUpdate.checkVersion(
        options: const PlayxUpdateOptions(
          localVersion: '1.9.0',
          versionSource: _newVersion,
        ),
      )).updateData!;

      expect(info.localVersion, '1.9.0');
      expect(info.canUpdate, isTrue);

      final current = (await PlayxVersionUpdate.checkVersion(
        options: const PlayxUpdateOptions(
          localVersion: '2.0.0',
          versionSource: _newVersion,
        ),
      )).updateData!;
      expect(current.canUpdate, isFalse);
    });

    test('an empty localVersion is ignored', () async {
      final info = (await PlayxVersionUpdate.checkVersion(
        options: const PlayxUpdateOptions(
          localVersion: '',
          versionSource: _newVersion,
        ),
      )).updateData!;
      expect(info.localVersion, '1.0.0');
    });

    test('forces the update below the minimum version', () async {
      final info = (await PlayxVersionUpdate.checkVersion(
        options: _options(minVersion: '1.5.0'),
      )).updateData!;
      expect(info.forceUpdate, isTrue);
    });

    test('forceUpdate in the options wins over the minimum version', () async {
      final info = (await PlayxVersionUpdate.checkVersion(
        options: _options(minVersion: '1.5.0', forceUpdate: false),
      )).updateData!;
      expect(info.forceUpdate, isFalse);
    });

    test('cannot update when the app is already current', () async {
      PackageInfo.setMockInitialValues(
        appName: 'Example',
        packageName: 'a.b',
        version: '2.0.0',
        buildNumber: '7',
        buildSignature: '',
      );
      final info = (await PlayxVersionUpdate.checkVersion(
        options: _options(),
      )).updateData!;
      expect(info.canUpdate, isFalse);
    });

    test('is not supported on the web or without a store', () async {
      PlayxPlatform.debugSetCurrent(null);
      expect(
        (await PlayxVersionUpdate.checkVersion(
          options: _options(),
        )).updateError,
        isA<NotSupportedException>(),
      );

      PlayxPlatform.debugSetCurrent(PlayxPlatform.windows);
      expect(
        (await PlayxVersionUpdate.checkVersion()).updateError,
        isA<NotSupportedException>(),
      );
    });

    test('works on a platform without a store with a custom source', () async {
      PlayxPlatform.debugSetCurrent(PlayxPlatform.windows);
      final info = (await PlayxVersionUpdate.checkVersion(
        options: _options(),
      )).updateData!;
      expect(info.newVersion, '2.0.0');
    });
  });

  group('showUpdateDialog', () {
    late BuildContext context;

    Future<void> pumpHost(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (c) {
                context = c;
                return const Text('home');
              },
            ),
          ),
        ),
      );
    }

    testWidgets('shows the dialog when an update is available', (tester) async {
      await pumpHost(tester);

      final result = await PlayxVersionUpdate.showUpdateDialog(
        context: context,
        options: _options(),
      );
      await tester.pumpAndSettle();

      expect(result.updateData, isTrue);
      expect(find.byType(PlayxUpdateDialog), findsOneWidget);
      expect(find.byType(PlayxUpdatePage), findsNothing);
    });

    testWidgets('returns an error when the app cannot be updated', (
      tester,
    ) async {
      await pumpHost(tester);
      PackageInfo.setMockInitialValues(
        appName: 'Example',
        packageName: 'a.b',
        version: '3.0.0',
        buildNumber: '1',
        buildSignature: '',
      );

      final result = await PlayxVersionUpdate.showUpdateDialog(
        context: context,
        options: _options(),
      );
      await tester.pumpAndSettle();

      final error = result.updateError;
      expect(error, isA<PlayxVersionCantUpdateError>());
      expect((error as PlayxVersionCantUpdateError).currentVersion, '3.0.0');
      expect(find.byType(PlayxUpdateDialog), findsNothing);
    });

    testWidgets('a throwing onSuppressed does not break showUpdateDialog', (
      tester,
    ) async {
      await pumpHost(tester);
      final reminder = PlayxUpdateReminderOptions(
        storage: PlayxInMemoryUpdateStorage(),
      );
      await PlayxUpdateReminder(reminder).snooze(
        const PlayxVersionUpdateInfo(
          localVersion: '1.0.0',
          newVersion: '2.0.0',
          canUpdate: true,
          forceUpdate: false,
          storeUrl: '',
        ),
      );

      final result = await PlayxVersionUpdate.showUpdateDialog(
        context: context,
        options: _options(),
        uiOptions: PlayxUpdateUIOptions(
          events: PlayxUpdateEvents(
            onSuppressed: (_, _) => throw StateError('analytics'),
          ),
        ),
        reminderOptions: reminder,
      );

      expect(result.updateData, isFalse);
      expect(tester.takeException(), isA<StateError>());
    });

    testWidgets('returns the error of a failing check', (tester) async {
      await pumpHost(tester);

      final result = await PlayxVersionUpdate.showUpdateDialog(
        context: context,
        options: _options(
          source: PlayxCallbackVersionSource((_) async => throw 'boom'),
        ),
      );

      expect(result.updateError, isA<DefaultFailureError>());
    });

    testWidgets('shows a page for a forced update by default', (tester) async {
      await pumpHost(tester);

      final result = await PlayxVersionUpdate.showUpdateDialog(
        context: context,
        options: _options(forceUpdate: true),
      );
      await tester.pumpAndSettle();

      expect(result.updateData, isTrue);
      expect(find.byType(PlayxUpdatePage), findsOneWidget);
      expect(find.byType(PlayxUpdateDialog), findsNothing);
      // A forced page replaces every route below it.
      expect(find.text('home'), findsNothing);
    });

    testWidgets('keeps a forced dialog with the dialog display type', (
      tester,
    ) async {
      await pumpHost(tester);

      await PlayxVersionUpdate.showUpdateDialog(
        context: context,
        options: _options(forceUpdate: true),
        uiOptions: const PlayxUpdateUIOptions(
          displayType: PlayxUpdateDisplayType.dialog,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlayxUpdateDialog), findsOneWidget);
    });

    testWidgets('can always show a page, pushed on top of the home', (
      tester,
    ) async {
      await pumpHost(tester);

      await PlayxVersionUpdate.showUpdateDialog(
        context: context,
        options: _options(),
        uiOptions: const PlayxUpdateUIOptions(
          displayType: PlayxUpdateDisplayType.page,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlayxUpdatePage), findsOneWidget);
      expect(find.text('home'), findsNothing, reason: 'covered by the page');
      Navigator.of(tester.element(find.byType(PlayxUpdatePage))).pop();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('is not supported where no dialog can be shown', (
      tester,
    ) async {
      await pumpHost(tester);
      PlayxPlatform.debugSetCurrent(PlayxPlatform.windows);

      final result = await PlayxVersionUpdate.showUpdateDialog(
        context: context,
        options: _options(),
      );

      expect(result.updateError, isA<NotSupportedException>());
      expect(find.byType(PlayxUpdateDialog), findsNothing);
    });

    testWidgets('does not show a snoozed version again', (tester) async {
      await pumpHost(tester);
      final suppressed = <PlayxPromptSuppressedReason>[];
      final reminder = PlayxUpdateReminderOptions(
        storage: PlayxInMemoryUpdateStorage(),
      );
      final uiOptions = PlayxUpdateUIOptions(
        events: PlayxUpdateEvents(onSuppressed: (_, r) => suppressed.add(r)),
      );

      final first = await PlayxVersionUpdate.showUpdateDialog(
        context: context,
        options: _options(),
        uiOptions: uiOptions,
        reminderOptions: reminder,
      );
      await tester.pumpAndSettle();
      expect(first.updateData, isTrue);

      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      final second = await PlayxVersionUpdate.showUpdateDialog(
        context: context,
        options: _options(),
        uiOptions: uiOptions,
        reminderOptions: reminder,
      );
      await tester.pumpAndSettle();

      expect(second.updateData, isFalse);
      expect(suppressed, [PlayxPromptSuppressedReason.snoozed]);
      expect(find.byType(PlayxUpdateDialog), findsNothing);
    });
  });

  group('showInAppUpdateDialog', () {
    late BuildContext context;

    Future<void> pumpHost(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
    }

    testWidgets('starts a flexible update on Android and reports events', (
      tester,
    ) async {
      await pumpHost(tester);
      final events = <String>[];

      final result = await PlayxVersionUpdate.showInAppUpdateDialog(
        context: context,
        type: PlayxAppUpdateType.flexible,
        events: PlayxUpdateEvents(
          onInAppUpdateStarted: (type) => events.add('started:${type.name}'),
          onInAppUpdateResult: (type, r) =>
              events.add('result:${type.name}:${r.updateData}'),
        ),
      );

      expect(result.updateData, isTrue);
      expect(fake.calls, ['needsInstall', 'flexible']);
      expect(events, ['started:flexible', 'result:flexible:true']);
    });

    testWidgets('starts an immediate update on Android', (tester) async {
      await pumpHost(tester);

      await PlayxVersionUpdate.showInAppUpdateDialog(
        context: context,
        type: PlayxAppUpdateType.immediate,
      );

      expect(fake.calls, ['needsInstall', 'immediate']);
    });

    testWidgets('completes a downloaded flexible update first', (tester) async {
      await pumpHost(tester);
      fake.flexibleWaiting = true;

      await PlayxVersionUpdate.showInAppUpdateDialog(
        context: context,
        type: PlayxAppUpdateType.flexible,
      );

      expect(fake.calls, ['needsInstall', 'complete']);
    });

    testWidgets('returns the error of the update flow', (tester) async {
      await pumpHost(tester);
      fake.startResult = PlayxVersionUpdateResult.error(
        PlayxInAppUpdateCanceledError(),
      );

      final result = await PlayxVersionUpdate.showInAppUpdateDialog(
        context: context,
        type: PlayxAppUpdateType.immediate,
      );

      expect(result.updateError, isA<PlayxInAppUpdateCanceledError>());
    });

    testWidgets('shows the dialog instead on iOS', (tester) async {
      await pumpHost(tester);
      PlayxPlatform.debugSetCurrent(PlayxPlatform.ios);

      final result = await PlayxVersionUpdate.showInAppUpdateDialog(
        context: context,
        type: PlayxAppUpdateType.flexible,
        iosOptions: _options(),
      );
      await tester.pumpAndSettle();

      expect(result.updateData, isTrue);
      expect(fake.calls, isEmpty, reason: 'no Google Play on iOS');
      expect(find.byType(PlayxUpdateDialog), findsOneWidget);
    });

    testWidgets('can skip a prompt the user snoozed on iOS', (tester) async {
      await pumpHost(tester);
      PlayxPlatform.debugSetCurrent(PlayxPlatform.ios);
      final reminder = PlayxUpdateReminderOptions(
        storage: PlayxInMemoryUpdateStorage(),
      );

      await PlayxVersionUpdate.showInAppUpdateDialog(
        context: context,
        type: PlayxAppUpdateType.flexible,
        iosOptions: _options(),
        iosReminderOptions: reminder,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      final again = await PlayxVersionUpdate.showInAppUpdateDialog(
        context: context,
        type: PlayxAppUpdateType.flexible,
        iosOptions: _options(),
        iosReminderOptions: reminder,
      );

      expect(again.updateData, isFalse);
    });
  });

  group('in-app update wrappers', () {
    test('delegate to the platform', () async {
      expect(
        (await PlayxVersionUpdate.getUpdateAvailability()).updateData,
        PlayxAppUpdateAvailability.available,
      );
      expect((await PlayxVersionUpdate.getUpdateStalenessDays()).updateData, 3);
      expect((await PlayxVersionUpdate.getUpdatePriority()).updateData, 4);
      expect(
        (await PlayxVersionUpdate.isUpdateAllowed(
          type: PlayxAppUpdateType.immediate,
        )).updateData,
        isTrue,
      );
      await PlayxVersionUpdate.startImmediateUpdate();
      await PlayxVersionUpdate.startFlexibleUpdate();
      await PlayxVersionUpdate.completeFlexibleUpdate();
      expect(
        (await PlayxVersionUpdate.isFlexibleUpdateNeedToBeInstalled())
            .updateData,
        isFalse,
      );
      await PlayxVersionUpdate.refreshInAppUpdate();

      expect(fake.calls, [
        'availability',
        'staleness',
        'priority',
        'allowed:immediate',
        'immediate',
        'flexible',
        'complete',
        'needsInstall',
        'refresh',
      ]);
    });

    test('download updates come from the platform stream', () async {
      final events = <PlayxDownloadInfo?>[];
      final subscription = PlayxVersionUpdate.listenToFlexibleDownloadUpdate()
          .listen(events.add);

      fake.downloads.add(
        PlayxDownloadInfo(
          status: PlayxDownloadStatus.downloading,
          bytesDownloaded: 1,
          totalBytesToDownload: 2,
          installErrorCode: 0,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(events.single!.status, PlayxDownloadStatus.downloading);
    });
  });

  group('openStore', () {
    test('opens the given url, with the store app first on Android', () async {
      final result = await PlayxVersionUpdate.openStore(
        storeUrl: 'https://play.google.com/store/apps/details?id=a.b',
      );

      expect(result.updateData, isTrue);
      expect(launches.single.arguments['url'], 'market://details?id=a.b');
    });

    test('can skip the deep link', () async {
      await PlayxVersionUpdate.openStore(
        storeUrl: 'https://play.google.com/store/apps/details?id=a.b',
        preferStoreApp: false,
      );
      expect(
        launches.single.arguments['url'],
        'https://play.google.com/store/apps/details?id=a.b',
      );
    });

    test('works out the url from the options without one', () async {
      final result = await PlayxVersionUpdate.openStore(
        options: const PlayxUpdateOptions(
          storeUrls: PlayxPlatformValue(android: 'https://my.link/store'),
        ),
      );

      expect(result.updateData, isTrue);
      expect(launches.single.arguments['url'], 'https://my.link/store');
    });

    test('derives the Google Play url on Android from the app id', () async {
      await PlayxVersionUpdate.openStore(preferStoreApp: false);
      expect(
        launches.single.arguments['url'],
        'https://play.google.com/store/apps/details?id=a.b&hl=en&gl=us',
      );
    });

    test('an empty url is resolved like no url', () async {
      await PlayxVersionUpdate.openStore(
        storeUrl: '',
        preferStoreApp: false,
        options: const PlayxUpdateOptions(
          storeUrls: PlayxPlatformValue(android: 'https://my.link/store'),
        ),
      );
      expect(launches.single.arguments['url'], 'https://my.link/store');
    });

    test('fails when nothing can be opened', () async {
      messenger.setMockMethodCallHandler(_launcherChannel, (_) async => false);
      final result = await PlayxVersionUpdate.openStore(
        storeUrl: 'https://example.com',
      );
      expect(result.updateError, isA<DefaultFailureError>());
    });

    test('fails when the platform has no store url', () async {
      PlayxPlatform.debugSetCurrent(PlayxPlatform.windows);
      final result = await PlayxVersionUpdate.openStore();
      expect(result.updateError, isA<NotSupportedException>());
    });
  });
}
