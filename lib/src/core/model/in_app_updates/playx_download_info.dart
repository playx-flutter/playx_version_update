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
    final map = json.decode(infoJson);
    return PlayxDownloadInfo(
        status: PlayxDownloadStatus.from(map["status"] as int?),
        bytesDownloaded: map["bytesDownloaded"] as int,
        totalBytesToDownload: map["totalBytesToDownload"] as int,
        installErrorCode: map["installErrorCode"] as int);
  }
}

enum PlayxDownloadStatus {
  pending,
  downloading,
  downloaded,
  installing,
  installed,
  failed,
  canceled;

  static PlayxDownloadStatus from(num? index) {
    if (index == null || index >= PlayxDownloadStatus.values.length) {
      return PlayxDownloadStatus.pending;
    }

    return PlayxDownloadStatus.values[index.toInt()];
  }
}
