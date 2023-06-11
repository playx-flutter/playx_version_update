class StoreInfo {
  final String version;
  final String? minVersion;
  final String? releaseNotes;

  StoreInfo({required this.version, this.minVersion, this.releaseNotes});

  factory StoreInfo.fromGooglePlay(dynamic body) {
    final regexp =
        RegExp(r'\[\[\[\"(\d+\.\d+(\.[a-z]+)?(\.([^"]|\\")*)?)\"\]\]');
    final storeVersion = regexp.firstMatch(body)?.group(1);

    //Release notes
    final regexpRelease =
        RegExp(r'\[(null,)\[(null,)\"((\.[a-z]+)?(([^"]|\\")*)?)\"\]\]');

    final releaseNotes = regexpRelease.firstMatch(body)?.group(3);

    final regexpDescription =
        RegExp(r'\[\[(null,)\"((\.[a-z]+)?(([^"]|\\")*)?)\"\]\]');
    final description = regexpDescription.firstMatch(body)?.group(2);

    String? minVersion;

    if (description != null && description.isNotEmpty) {
      if (description.contains('[minimum version :'.toLowerCase())) {
        try {
          minVersion = description.substring(
              description.indexOf('[minimum version :'..toLowerCase()));

          minVersion = minVersion.split('[minimum version :'.toLowerCase())[1];
          minVersion = minVersion.split(']')[0].trim();
        } catch (_) {}
      }
    }

    return StoreInfo(
        version: storeVersion ?? '',
        minVersion: minVersion,
        releaseNotes: releaseNotes);
  }
}
