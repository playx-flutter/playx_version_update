/// A successful store response.
class NetworkResponse {
  /// The raw response body.
  final String body;

  /// The HTTP status code.
  final int? statusCode;

  /// The URL the body was finally served from, after following redirects.
  final Uri finalUri;

  const NetworkResponse({
    required this.body,
    required this.finalUri,
    this.statusCode,
  });
}
