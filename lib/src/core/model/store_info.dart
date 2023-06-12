import 'dart:convert';

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

    final releaseNotes = regexpRelease.firstMatch(body)?.group(3);

    String? minVersion;

    try {
      final regexpDescription =
          RegExp(r'\[\[(null,)\"((\.[a-z]+)?(([^"]|\\")*)?)\"\]\]');
      final description = regexpDescription.firstMatch(body)?.group(2);

      if (description != null && description.isNotEmpty) {
        if (description.contains('[minimum version :'.toLowerCase())) {
          minVersion = description
              .substring(
                  description.indexOf('[minimum version :'.toLowerCase()))
              .split('[minimum version :'.toLowerCase())[1]
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
    final jsonObj = json.decode(body);
    final List results = jsonObj['results'];
    if (results.isEmpty) {
      throw Exception('Not found');
    }
    final storeVersion = jsonObj['results'][0]['version'];
    final appStoreLink = jsonObj['results'][0]['trackViewUrl'];
    final releaseNotes = jsonObj['results'][0]['releaseNotes'];

    String? minVersion;

    try {
      final description = jsonObj['results'][0]['description'];

      if (description != null && description.isNotEmpty) {
        if (description.contains('[minimum version :'.toLowerCase())) {
          minVersion = description
              .substring(
                  description.indexOf('[minimum version :'.toLowerCase()))
              .split('[minimum version :'.toLowerCase())[1]
              .split(']')[0]
              .trim();
        }
      }
    } catch (_) {}

    return StoreInfo(
      version: storeVersion ?? '',
      minVersion: minVersion,
      releaseNotes: releaseNotes,
      storeUrl: appStoreLink,
    );
  }
}
