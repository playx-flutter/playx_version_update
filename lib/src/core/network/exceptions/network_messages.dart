/// Default user-facing messages for network failures that happen while
/// fetching version information from the App Store or Google Play.
abstract final class NetworkMessages {
  static const badRequest =
      'Invalid request while trying to fetch version information.';
  static const unauthorized =
      'Unauthorized access while trying to fetch version information.';
  static const notFound =
      'Could not find the app on the store while checking for updates.';
  static const appNotFound =
      'The app was not found on the store. Check the package name / bundle id and that the app is published in this country.';
  static const conflict =
      'Version check could not be completed due to a conflict on the server.';
  static const requestTimeout =
      'Timed out while waiting for version information from the store.';
  static const sendTimeout =
      'Connection to the store timed out while sending version check request.';
  static const unableToProcess =
      "Failed to process the store's response while checking for updates.";
  static const tooManyRequests =
      'Too many requests were sent to the store. Please try again later.';
  static const internalServerError =
      'The store service encountered an internal error while checking for updates.';
  static const serviceUnavailable =
      'The store service is currently unavailable. Please try again later.';
  static const emptyResponse =
      'No response received from the store while checking version info.';
  static const defaultError =
      'Something went wrong while checking for updates.';
  static const requestCanceled =
      'The update check was cancelled before completion.';
  static const noInternetConnection =
      'You are offline. Please connect to the internet to check for updates.';
  static const invalidFormat =
      'Invalid data format received while fetching app version info.';
  static const badCertificate =
      'A secure connection to the store could not be established.';
  static const unexpected =
      'An unexpected error occurred while checking for updates.';
}
