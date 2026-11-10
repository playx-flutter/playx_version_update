import 'package:flutter/foundation.dart';

/// Runs a callback supplied by the app (an event, `onUpdate`, `onCancel`...).
///
/// An error thrown by it is reported to [FlutterError.onError] instead of
/// breaking the update flow, so a bug in the app's analytics code cannot leave
/// the update dialog half-handled.
void guardCallback(String description, void Function() callback) {
  try {
    callback();
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'playx_version_update',
        context: ErrorDescription('while $description'),
      ),
    );
  }
}
