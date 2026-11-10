import 'package:flutter/material.dart';
import 'package:playx_version_update/playx_version_update.dart';

import 'ui.dart';

/// Demonstrates the newer features of the package:
///
/// - custom version sources (static, callback, fallback)
/// - update events for analytics
/// - "Later" snoozing and "Skip this version"
/// - opening the store (deep links, a custom launcher, without a check)
/// - network settings, logging and error codes
///
/// Every demo uses a version source with fixed values, so it works offline
/// and always has an update to show. Only the network demo talks to the stores.
class FeaturesPage extends StatefulWidget {
  const FeaturesPage({super.key});

  @override
  State<FeaturesPage> createState() => _FeaturesPageState();
}

class _FeaturesPageState extends State<FeaturesPage> {
  final List<String> _log = [];

  /// Remembers snoozed and skipped versions. The default storage is in memory
  /// (forgotten on restart); implement `PlayxUpdateStorage` to persist it.
  final PlayxUpdateReminderOptions _reminder = PlayxUpdateReminderOptions(
    storage: PlayxInMemoryUpdateStorage(),
    snoozeDuration: const Duration(minutes: 1),
    allowSkipVersion: true,
  );

  /// Fixed values per platform: a new version for everyone, but a different
  /// minimum version per platform (see "Per-platform versions").
  static const _staticSource = PlayxStaticVersionSource(
    version: PlayxPlatformVersion(
      android: '99.0.0',
      ios: '99.0.0',
      macos: '99.0.0',
      windows: '99.0.0',
      linux: '99.0.0',
    ),
    minVersion: PlayxPlatformVersion(android: '0.0.1', ios: '99.0.0'),
    releaseNotes: PlayxPlatformValue(
      android: '• Android notes\n• Bug fixes',
      ios: '• iOS notes\n• Bug fixes',
      macos: '• macOS notes\n• Bug fixes',
    ),
    storeUrls: PlayxPlatformValue(
      // Any scheme works. `market://` and `itms-apps://` also work.
      android:
          'https://play.google.com/store/apps/details?id=com.google.android.apps.bard',
      ios: 'https://apps.apple.com/app/shortcuts/id915249334',
      macos: 'https://apps.apple.com/app/xcode/id497799835?mt=12',
    ),
  );

  void _add(String line) {
    if (!mounted) return;
    setState(() => _log.insert(0, line));
  }

  PlayxUpdateEvents get _events => PlayxUpdateEvents(
    onShown: (info) => _add('shown: ${info.newVersion}'),
    onUpdateTapped: (info) => _add('update tapped'),
    onStoreOpenResult: (info, opened) =>
        _add('store opened: $opened (${info.storeUrl})'),
    onDismissed: (info, reason) => _add('dismissed (${reason.name})'),
    onVersionSkipped: (info) => _add('skipped ${info.newVersion}'),
    onSuppressed: (info, reason) =>
        _add('not shown: ${reason.name} (${info.newVersion})'),
  );

  /// Events + "Later" snoozing + "Skip this version".
  Future<void> _showDialogWithReminder() async {
    final result = await PlayxVersionUpdate.showUpdateDialog(
      context: context,
      options: const PlayxUpdateOptions(versionSource: _staticSource),
      uiOptions: PlayxUpdateUIOptions(
        showReleaseNotes: true,
        dismissButtonText: 'Later',
        events: _events,
      ),
      reminderOptions: _reminder,
    );
    result.when(
      success: (shown) => _add('showUpdateDialog -> shown: $shown'),
      error: (error) => _add('error: ${error.errorCode} ${error.message}'),
    );
  }

  Future<void> _resetReminder() async {
    await PlayxUpdateReminder(_reminder).reset();
    _add('reminder reset: the prompt shows again');
  }

  /// A custom launcher: you open the store, the package reports the result.
  Future<void> _showDialogWithStoreLauncher() async {
    final result = await PlayxVersionUpdate.showUpdateDialog(
      context: context,
      options: const PlayxUpdateOptions(versionSource: _staticSource),
      uiOptions: PlayxUpdateUIOptions(
        events: _events,
        storeLauncher: (info) async {
          _add('custom launcher for ${info.storeUrl}');
          // Skip the deep link and open the web page.
          final opened = await PlayxVersionUpdate.openStore(
            storeUrl: info.storeUrl,
            preferStoreApp: false,
          );
          return opened.updateData ?? false;
        },
      ),
    );
    result.when(
      success: (shown) => _add('showUpdateDialog -> shown: $shown'),
      error: (error) => _add('error: ${error.errorCode} ${error.message}'),
    );
  }

  /// Opens the store with no version check. With no `storeUrl`, it is worked
  /// out from the options: `storeUrls`, else the Google Play url on Android.
  Future<void> _openStoreWithoutCheck() async {
    final result = await PlayxVersionUpdate.openStore(
      options: const PlayxUpdateOptions(
        appIds: PlayxPlatformValue(
          android: 'com.google.android.apps.bard',
          ios: 'com.apple.shortcuts',
        ),
        storeUrls: PlayxPlatformValue(
          ios: 'https://apps.apple.com/app/shortcuts/id915249334',
          macos: 'https://apps.apple.com/app/xcode/id497799835?mt=12',
        ),
      ),
    );
    result.when(
      success: (opened) => _add('openStore -> opened: $opened'),
      error: (error) => _add('openStore error: ${error.message}'),
    );
  }

  /// The same versions, but each platform has its own minimum version, so the
  /// force-update decision differs: iOS is forced, Android is not.
  Future<void> _checkPerPlatformVersions() async {
    final result = await PlayxVersionUpdate.checkVersion(
      options: const PlayxUpdateOptions(versionSource: _staticSource),
    );
    result.when(
      success: (info) => _add(
        'new ${info.newVersion} (min ${info.minVersion}) | '
        'can update: ${info.canUpdate} | force: ${info.forceUpdate}',
      ),
      error: (error) => _add('error: ${error.errorCode} ${error.message}'),
    );
  }

  /// A source that fails, then the store as a fallback. Replace the first one
  /// with your backend or Firebase Remote Config.
  Future<void> _checkWithFallbackSource() async {
    final result = await PlayxVersionUpdate.checkVersion(
      options: PlayxUpdateOptions(
        androidPackageName: 'com.google.android.apps.bard',
        iosBundleId: 'com.apple.shortcuts',
        versionSource: PlayxFallbackVersionSource([
          PlayxCallbackVersionSource((request) async {
            _add('backend for ${request.platform.name}...');
            throw Exception('backend is down');
          }),
          PlayxStoreVersionSource(),
        ]),
      ),
    );
    result.when(
      success: (info) => _add('fallback to the store: ${info.newVersion}'),
      error: (error) => _add('error: ${error.errorCode} ${error.message}'),
    );
  }

  /// Network settings, logging and stable error codes.
  Future<void> _checkWithNetworkOptions({required bool unknownApp}) async {
    final result = await PlayxVersionUpdate.checkVersion(
      options: PlayxUpdateOptions(
        enableNetworkLogging: true, // see the debug console
        androidPackageName: unknownApp
            ? 'com.example.not.published'
            : 'com.google.android.apps.bard',
        iosBundleId: unknownApp
            ? 'com.example.not.published'
            : 'com.apple.shortcuts',
        appIds: PlayxPlatformValue(
          macos: unknownApp
              ? 'com.example.not.published'
              : 'com.apple.dt.Xcode',
        ),
        networkOptions: const PlayxNetworkOptions(
          maxRetries: 2,
          connectTimeout: Duration(seconds: 10),
          headers: {'X-Example': 'playx'},
        ),
      ),
    );
    result.when(
      success: (info) => _add('store version: ${info.newVersion}'),
      error: (error) {
        if (error is PlayxVersionNetworkError) {
          final retry = error.error.isRetryable ? ' (retryable)' : '';
          _add('${error.errorCode}$retry: ${error.message}');
        } else {
          _add('error: ${error.errorCode} ${error.message}');
        }
      },
    );
  }

  /// The latest events first, pinned below the demos so it stays visible.
  Widget _eventLog(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          color: theme.colorScheme.surfaceContainerHighest,
          child: SizedBox(
            height: 168,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                  child: Row(
                    children: [
                      Text('Event log', style: theme.textTheme.titleSmall),
                      const Spacer(),
                      TextButton(
                        onPressed: _log.isEmpty
                            ? null
                            : () => setState(_log.clear),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _log.isEmpty
                      ? Center(
                          child: Text(
                            'Events and results appear here.',
                            style: theme.textTheme.bodySmall,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          itemCount: _log.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 4),
                          itemBuilder: (_, i) =>
                              Text(_log[i], style: theme.textTheme.bodySmall),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More features')),
      body: Column(
        children: [
          Expanded(
            child: ExampleBody(
              children: [
                ExampleSection(
                  title: 'Dialog',
                  children: [
                    ActionTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Events + Later + Skip',
                      subtitle:
                          'Dismiss to snooze for a minute, or skip this version',
                      onTap: _showDialogWithReminder,
                    ),
                    ActionTile(
                      icon: Icons.restart_alt,
                      title: 'Reset Later / Skip',
                      subtitle: 'Forget snoozed and skipped versions',
                      onTap: _resetReminder,
                    ),
                    ActionTile(
                      icon: Icons.open_in_new,
                      title: 'Custom store launcher',
                      subtitle:
                          'storeLauncher opens the store, result reported',
                      onTap: _showDialogWithStoreLauncher,
                    ),
                  ],
                ),
                ExampleSection(
                  title: 'Store',
                  children: [
                    ActionTile(
                      icon: Icons.storefront_outlined,
                      title: 'Open the store (no check)',
                      subtitle:
                          'openStore without a url: storeUrls or Play url',
                      onTap: _openStoreWithoutCheck,
                    ),
                  ],
                ),
                ExampleSection(
                  title: 'Version sources',
                  children: [
                    ActionTile(
                      icon: Icons.devices_outlined,
                      title: 'Per-platform versions',
                      subtitle: 'A different minimum version for each platform',
                      onTap: _checkPerPlatformVersions,
                    ),
                    ActionTile(
                      icon: Icons.cloud_off_outlined,
                      title: 'Backend, then the store',
                      subtitle: 'A failing source falls back to the store',
                      onTap: _checkWithFallbackSource,
                    ),
                  ],
                ),
                ExampleSection(
                  title: 'Network',
                  children: [
                    ActionTile(
                      icon: Icons.network_check,
                      title: 'Store lookup with options',
                      subtitle: 'Retries, timeouts, headers and logging',
                      onTap: () => _checkWithNetworkOptions(unknownApp: false),
                    ),
                    ActionTile(
                      icon: Icons.error_outline,
                      title: 'App not on the store',
                      subtitle: 'Shows the stable error code',
                      onTap: () => _checkWithNetworkOptions(unknownApp: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _eventLog(context),
        ],
      ),
    );
  }
}
