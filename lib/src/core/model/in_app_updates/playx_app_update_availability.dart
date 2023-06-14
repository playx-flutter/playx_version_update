enum PlayxAppUpdateAvailability {
  unknown,
  notAvailable,
  available,
  inProgress;

  static PlayxAppUpdateAvailability fromUpdateAvailability(num? index) {
    if (index == null || index >= PlayxAppUpdateAvailability.values.length) {
      return PlayxAppUpdateAvailability.unknown;
    }

    return PlayxAppUpdateAvailability.values[index.toInt()];
  }
}
