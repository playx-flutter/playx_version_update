import 'dart:convert';

class PlayxDownloadInfo {
  final PlayxDownloadStatus status;
  final int bytesDownloaded;
  final int totalBytesToDownload;
  final int installErrorCode;

  PlayxDownloadInfo(
      {required this.status,
      required this.bytesDownloaded,
      required this.totalBytesToDownload,
      required this.installErrorCode});

  factory PlayxDownloadInfo.fromJson(String infoJson) {
    final map = json.decode(infoJson) as Map<String, dynamic>;
    // Missing or null numbers (for example before the download starts) are
    // read as 0 instead of failing.
    int number(String key) => (map[key] as num?)?.toInt() ?? 0;

    return PlayxDownloadInfo(
        status: PlayxDownloadStatus.from(map["status"] as num?),
        bytesDownloaded: number("bytesDownloaded"),
        totalBytesToDownload: number("totalBytesToDownload"),
        installErrorCode: number("installErrorCode"));
  }

  @override
  String toString() {
    return "DownloadInfo : status :$status , totalBytesToDownload :$totalBytesToDownload : bytesDownloaded :$bytesDownloaded , installErrorCode :$installErrorCode";
  }
}

enum PlayxDownloadStatus {
  unknown,
  pending,
  downloading,
  downloaded,
  installing,
  installed,
  failed,
  canceled;

  static PlayxDownloadStatus from(num? index) {
    if (index == null || index >= PlayxDownloadStatus.values.length) {
      return PlayxDownloadStatus.unknown;
    }

    return PlayxDownloadStatus.values[index.toInt()];
  }
}
