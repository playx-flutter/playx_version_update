---
id: network-and-errors
title: Network and errors
sidebar_position: 10
---

# Network and errors

## Network options

`networkOptions` tunes the request to the store:

```dart
PlayxUpdateOptions(
  enableNetworkLogging: true, // log the request, response, errors and retries
  networkOptions: PlayxNetworkOptions(
    maxRetries: 2,
    connectTimeout: Duration(seconds: 10),
    headers: {'X-App': 'my-app'},
    dio: myDio,               // proxy, certificate pinning, your own interceptors
    cancelToken: cancelToken, // cancel a pending check
  ),
)
```

| Option | Default | Meaning |
| --- | --- | --- |
| `maxRetries` | `1` | retries for failures that can succeed later (timeouts, offline, throttling, 502-504). `0` disables |
| `retryDelay` | 1 second | base delay between retries; it grows with every attempt |
| `connectTimeout`, `sendTimeout`, `receiveTimeout` | 30 s, 20 s, 30 s | request timeouts |
| `headers` | — | extra headers; they override the package defaults |
| `dio` | — | a custom `Dio`. The package only adds its logging interceptor to it |
| `cancelToken` | — | cancel the check. A cancelled check fails with `NETWORK_REQUEST_CANCELED` |

### Logging

With `enableNetworkLogging: true` each request logs the method, URL and headers, then the status, headers,
timing and a short preview of the body. Errors and retries are logged too. Headers whose name contains
`auth`, `cookie`, `token`, `secret`, `password` or `key` are masked.

## Errors

Every failing call returns a `PlayxVersionUpdateError` with a `message` and a stable `errorCode`.

```dart
error: (error) {
  if (error is PlayxVersionNetworkError) {
    switch (error.errorCode) {
      case NetworkErrorCode.noInternetConnection:
        showOfflineBanner();
      case NetworkErrorCode.appNotFound:
        // wrong package id, or the app is not published in this country
        break;
      case NetworkErrorCode.consentRequired:
        // Google asked for cookie consent, see below
        break;
    }
    if (error.error.isRetryable) offerRetry();
    print('HTTP status: ${error.statusCode}');
  }
},
```

`PlayxVersionNetworkError.error` is the underlying `NetworkException`, which has an `errorCode`, a
`message`, the original `cause`, and `isRetryable`.

### Network error codes

| `NetworkErrorCode` | Exception | Retryable |
| --- | --- | --- |
| `NETWORK_NO_INTERNET_CONNECTION` | `NoInternetConnectionException` | yes |
| `NETWORK_REQUEST_TIMEOUT` | `RequestTimeoutException` | yes |
| `NETWORK_SEND_TIMEOUT` | `SendTimeoutException` | yes |
| `NETWORK_TOO_MANY_REQUESTS` | `TooManyRequestsException` | yes |
| `NETWORK_SERVICE_UNAVAILABLE` | `ServiceUnavailableException` (502, 503, 504) | yes |
| `STORE_APP_NOT_FOUND` | `AppNotFoundException` | no |
| `STORE_CONSENT_REQUIRED` | `ConsentRequiredException` | no |
| `NETWORK_NOT_FOUND` | `NotFoundException` | no |
| `NETWORK_BAD_REQUEST` | `BadRequestException` | no |
| `NETWORK_UNAUTHORIZED` | `UnauthorizedRequestException` (401, 403) | no |
| `NETWORK_CONFLICT` | `ConflictException` | no |
| `NETWORK_UNABLE_TO_PROCESS` | `UnableToProcessException` | no |
| `NETWORK_INTERNAL_SERVER_ERROR` | `InternalServerErrorException` | no |
| `NETWORK_API_ERROR` | `DefaultApiException` (other status codes) | no |
| `NETWORK_EMPTY_RESPONSE` | `EmptyResponseException` | no |
| `NETWORK_INVALID_FORMAT` | `InvalidFormatException` | no |
| `NETWORK_BAD_CERTIFICATE` | `BadCertificateException` | no |
| `NETWORK_REQUEST_CANCELED` | `RequestCanceledException` | no |
| `NETWORK_UNEXPECTED_ERROR` | `UnexpectedErrorException` | no |

Store specifics:

- **App not found**: Google Play answers 404, or the App Store lookup returns no result, for an id that
  is not on the store.
- **App Store 403**: treated as throttling (`NETWORK_TOO_MANY_REQUESTS`); the lookup API is rate limited.

### Google consent page {#consent}

In some regions (the EU and UK) Google Play answers with a cookie-consent page instead of the app page,
so the version cannot be read. This is reported as `ConsentRequiredException`
(`STORE_CONSENT_REQUIRED`) and retrying does not help. Provide the version from your own backend with a
[version source](./version-sources.md) (or `newVersion`), or send users to the store page with
[`openStore`](./opening-the-store.md).

### Other errors

| `errorCode` | Class | Meaning |
| --- | --- | --- |
| `PLAYX_VERSION_CANT_UPDATE_ERROR_CODE` | `PlayxVersionCantUpdateError` | the app is already up to date |
| `VERSION_FORMAT_ERROR` | `VersionFormatException` | a version could not be read or compared |
| `NOT_SUPPORTED_ERROR_CODE` | `NotSupportedException` | the platform has no store lookup or dialog |
| `PLATFORM_NOT_SUPPORTED_ERROR` | `PlatformNotSupportedError` | an in-app update call on a platform other than Android |
| `DEFAULT_FAILURE_ERROR` | `DefaultFailureError` | any other failure |

In-app update errors are listed in [Android in-app updates](./android-in-app-updates.md#errors).
