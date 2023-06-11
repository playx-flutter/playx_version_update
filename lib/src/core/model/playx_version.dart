class PlayxVersion {
  String? localVersion;
  String? newVersion;
  String? minVersion;
  bool forceUpdate;
  String? googlePlayId;
  String? appStoreId;
  String country;

  PlayxVersion(
      {this.localVersion,
      this.newVersion,
      this.minVersion,
      this.forceUpdate = false,
      this.googlePlayId,
      this.appStoreId,
      this.country = 'en'});
}
