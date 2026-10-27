/// Categories of failures the UI knows how to present.
enum AppErrorType {
  timeout,
  network,
  notFound,
  server,
  invalidData,
  cancelled,
  unknown,
}

/// A failure that is safe to show to the user.
///
/// The repository converts Dio errors and malformed responses into this type
/// so that state and UI code never deal with raw exceptions or stack traces.
class AppException implements Exception {
  AppException(this.type, {this.statusCode});

  /// Wraps any error so callers can always work with an [AppException].
  factory AppException.from(Object error) =>
      error is AppException ? error : AppException(AppErrorType.unknown);

  final AppErrorType type;
  final int? statusCode;

  bool get isCancelled => type == AppErrorType.cancelled;

  String get message => switch (type) {
    AppErrorType.timeout => 'The request timed out. Please try again.',
    AppErrorType.network =>
      'Unable to connect. Check your internet connection and try again.',
    AppErrorType.notFound => 'Product not found',
    AppErrorType.server =>
      'The server could not complete the request. Please try again later.',
    AppErrorType.invalidData =>
      'We received unexpected data from the server. Please try again later.',
    AppErrorType.cancelled => 'The request was cancelled.',
    AppErrorType.unknown => 'Something went wrong. Please try again.',
  };

  @override
  String toString() => 'AppException($type, statusCode: $statusCode)';
}
