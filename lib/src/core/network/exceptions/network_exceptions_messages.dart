
import 'package:playx_network/src/models/exceptions/message/exception_message.dart';

/// Default error messages related to network requests when
/// fetching version information from the App Store or Google Play.
///
/// You can override this class to provide custom messages.
class NetworkExceptionsMessages extends ExceptionMessage {
  const NetworkExceptionsMessages();

  @override
  String get badRequest =>
      "Invalid request while trying to fetch version information.";

  @override
  String get conflict =>
      "Version check could not be completed due to a conflict on the server.";

  @override
  String get defaultError =>
      "Something went wrong while checking for updates.";

  @override
  String get emptyResponse =>
      "No response received from the store while checking version info.";

  @override
  String get formatException =>
      "Invalid data format received while fetching app version info.";

  @override
  String get internalServerError =>
      "The store service encountered an internal error while checking for updates.";

  @override
  String get noInternetConnection =>
      "You are offline. Please connect to the internet to check for updates.";

  @override
  String get notAcceptable =>
      "The store server refused to accept the version check request.";

  @override
  String get notFound =>
      "Could not find the app on the store while checking for updates.";

  @override
  String get requestCancelled =>
      "The update check was cancelled before completion.";

  @override
  String get requestTimeout =>
      "Timed out while waiting for version information from the store.";

  @override
  String get sendTimeout =>
      "Connection to the store timed out while sending version check request.";

  @override
  String get serviceUnavailable =>
      "The store service is currently unavailable. Please try again later.";

  @override
  String get unableToProcess =>
      "Failed to process the store's response while checking for updates.";

  @override
  String get unauthorizedRequest =>
      "Unauthorized access while trying to fetch version information.";

  @override
  String get unexpectedError =>
      "An unexpected error occurred while checking for updates.";
}
