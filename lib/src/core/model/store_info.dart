import 'dart:convert';

import 'package:playx_version_update/src/core/utils/utils.dart';

class StoreInfo {
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
    final regexp =
        RegExp(r'\[\[\[\"(\d+\.\d+(\.[a-z]+)?(\.([^"]|\\")*)?)\"\]\]');
    final storeVersion = regexp.firstMatch(body)?.group(1);

    //Release notes
    final regexpRelease =
        RegExp(r'\[(null,)\[(null,)\"((\.[a-z]+)?(([^"]|\\")*)?)\"\]\]');

    final releaseNotes =
        getFormattedHtmlText(regexpRelease.firstMatch(body)?.group(3));

    String? minVersion;

    try {
      final regexpDescription =
          RegExp(r'\[\[(null,)\"((\.[a-z]+)?(([^"]|\\")*)?)\"\]\]');
      final description =
          regexpDescription.firstMatch(body)?.group(2)?.toLowerCase();

      if (description != null && description.isNotEmpty) {
        final minimumVersionPrefix = '[Minimum Version :'.toLowerCase();
        if (description.contains(minimumVersionPrefix)) {
          minVersion = description
              .substring(description.indexOf(minimumVersionPrefix))
              .split(minimumVersionPrefix)[1]
              .split(']')[0]
              .trim();
        }
      }
    } catch (_) {}

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

      if (description != null && description.isNotEmpty) {
        final minimumVersionPrefix = '[Minimum Version :'.toLowerCase();
        if (description.contains(minimumVersionPrefix)) {
          minVersion = description
              .substring(description.indexOf(minimumVersionPrefix))
              .split(minimumVersionPrefix)[1]
              .split(']')[0]
              .trim();
        }
      }
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
