import 'dart:convert';

import 'package:playx_version_update/src/core/utils/utils.dart';
import 'package:playx_version_update/src/core/version_checker/version.dart';

class StoreInfo {
  static final RegExp _versionStartsWithNumberRegexp = RegExp(r'^\d');
  static final RegExp _minimumVersionRegexp = RegExp(
    r'\[\s*minimum[\s_-]*version\s*[:=]\s*([^\]\r\n]+?)\s*\]',
    caseSensitive: false,
  );

  final String version;
  final String? minVersion;
  final String? releaseNotes;
  final String? storeUrl;

  StoreInfo(
      {required this.version,
      this.minVersion,
      this.releaseNotes,
      this.storeUrl});

  factory StoreInfo.fromGooglePlay(dynamic body) {
    String? storeVersion;

    // Attempt 1: Look for "Current Version" label followed by the version number.
    final currentVersionRegexp = RegExp(
        r'Current Version<\/div><span[^>]*><div[^>]*><span[^>]*>([0-9.]+(?:[a-zA-Z0-9.\-]+)?(?:(?:\s|&nbsp;)*[0-9A-Za-z.\-]+)?(?:[+\-][0-9A-Za-z.\-]+)?(?:[.\-][0-9A-Za-z.\-]+)*)<\/span>',
        caseSensitive: false);
    storeVersion = currentVersionRegexp.firstMatch(body)?.group(1)?.trim();

    // Attempt 2: Fallback to itemprop="softwareVersion" if the above fails.
    if (storeVersion == null || storeVersion.isEmpty) {
      final itempropRegexp =
          RegExp(r'<span[^>]*itemprop="softwareVersion"[^>]*>([^<]+)<');
      storeVersion = itempropRegexp.firstMatch(body)?.group(1)?.trim();
    }

    // Attempt 3: Fallback to the general JSON-like array structure if both above fail.
    // This is the least reliable but might catch edge cases.
    if (storeVersion == null || storeVersion.isEmpty) {
      final oldRegexp =
          RegExp(r'\[\[\[\"(\d+(?:\.\d+)*(?:[.-][0-9A-Za-z\-.]*)?)\"\]\]');
      storeVersion = oldRegexp.firstMatch(body)?.group(1);
    }

    // Release notes - This regex is kept as is, assuming it correctly extracts release notes.
    final regexpRelease =
        RegExp(r'\[(null,)\[(null,)\"((\.[a-z]+)?(([^"]|\\")*)?)\"\]\]');

    final releaseNotes =
        getFormattedHtmlText(regexpRelease.firstMatch(body)?.group(3));

    String? minVersion;

    try {
      // Minimum version from description - This regex is kept as is.
      final regexpDescription =
          RegExp(r'\[\[(null,)\"((\.[a-z]+)?(([^"]|\\")*)?)\"\]\]');
      final description = regexpDescription.firstMatch(body)?.group(2);
      minVersion = extractMinVersion(description);
    } catch (_) {
      // Error handling for minVersion extraction is already present.
    }

    return StoreInfo(
        version: storeVersion ?? '',
        minVersion: minVersion,
        releaseNotes: releaseNotes);
  }

  factory StoreInfo.fromAppStore(dynamic body) {
    try {
      final jsonObj = json.decode(body);
      final List results = jsonObj['results'] as List? ?? [];
      if (results.isEmpty) {
        throw Exception('Not found');
      }
      final storeVersion = jsonObj['results'][0]['version'];
      final appStoreLink = jsonObj['results'][0]['trackViewUrl'];
      final releaseNotes = jsonObj['results'][0]['releaseNotes'];

      String? minVersion;

      final description = jsonObj['results'][0]['description'];
      minVersion = extractMinVersion(description);
      return StoreInfo(
        version: storeVersion ?? '',
        minVersion: minVersion,
        releaseNotes: releaseNotes,
        storeUrl: appStoreLink,
      );
    } catch (_) {
      throw Exception('Not found');
    }
  }

  static String? extractMinVersion(dynamic description) {
    if (description is! String || description.trim().isEmpty) return null;

    final candidate =
        _minimumVersionRegexp.firstMatch(description)?.group(1)?.trim();
    if (candidate == null || candidate.isEmpty) return null;
    if (!_versionStartsWithNumberRegexp.hasMatch(candidate)) return null;

    try {
      Version.parse(candidate);
      return candidate;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() {
    return 'StoreInfo{version: $version, minVersion: $minVersion, releaseNotes: $releaseNotes, storeUrl: $storeUrl}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StoreInfo &&
        other.version == version &&
        other.minVersion == minVersion &&
        other.releaseNotes == releaseNotes &&
        other.storeUrl == storeUrl;
  }

  @override
  int get hashCode {
    return version.hashCode ^
        minVersion.hashCode ^
        releaseNotes.hashCode ^
        storeUrl.hashCode;
  }
}
