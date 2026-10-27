/// Every failure the UI can see. [message] is always safe to show to people.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NoConnectionException extends AppException {
  const NoConnectionException()
      : super(
          "We couldn't connect to the internet. "
          'Please check your connection and try again.',
        );
}

final class RequestTimeoutException extends AppException {
  const RequestTimeoutException()
      : super(
          'This is taking too long, which usually means a slow connection. '
          'Please try again.',
        );
}

final class BadRequestException extends AppException {
  const BadRequestException([String? message])
      : super(message ?? "Some details aren't quite right. Please check them and try again.");
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException({required this.sessionEnded})
      : super(
          sessionEnded
              ? 'Your session has ended. Please sign in again.'
              : "We couldn't sign you in with those details. "
                  'Please check them and try again.',
        );

  final bool sessionEnded;
}

final class ForbiddenException extends AppException {
  const ForbiddenException()
      : super(
          "Your account doesn't have access to this. "
          'If you think this is a mistake, contact the property owner.',
        );
}

final class NotFoundException extends AppException {
  const NotFoundException([String? message])
      : super(message ?? "We couldn't find what you were looking for. It may have been removed.");
}

final class ConflictException extends AppException {
  const ConflictException([String? message])
      : super(message ?? 'This already exists. Please check the details and try again.');
}

final class ServerException extends AppException {
  const ServerException()
      : super(
          'Something went wrong on our side. '
          'Please try again in a moment.',
        );
}

final class ParseException extends AppException {
  const ParseException()
      : super(
          "We received something we didn't expect from the server. "
          'Please try again.',
        );
}

final class UnknownException extends AppException {
  const UnknownException()
      : super('Something went wrong. Please try again.');
}

/// Returns a message suitable for display for any error object.
String messageFor(Object error) =>
    error is AppException ? error.message : const UnknownException().message;
