import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentra/core/errors/app_exception.dart';
import 'package:rentra/core/errors/error_mapper.dart';
import 'package:rentra/core/network/request_flags.dart';

DioException _response(int status, Object? body, {bool sentAuth = false}) {
  final options = RequestOptions(path: '/x');
  if (sentAuth) options.extra[RequestFlags.sentAuth] = true;
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

DioException _ofType(DioExceptionType type, {Object? error}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      error: error,
    );

void main() {
  test('no connection', () {
    final e = mapDioException(_ofType(DioExceptionType.connectionError));
    expect(e, isA<NoConnectionException>());
    expect(e.message, contains("couldn't connect to the internet"));
  });

  test('timeouts', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.transformTimeout,
    ]) {
      expect(mapDioException(_ofType(type)), isA<RequestTimeoutException>());
    }
  });

  test('400 with a string message keeps the server explanation', () {
    final e = mapDioException(
      _response(400, {'message': 'Email already registered', 'statusCode': 400}),
    );
    expect(e, isA<BadRequestException>());
    expect(e.message, 'Email already registered');
  });

  test('400 with an array message joins the lines', () {
    final e = mapDioException(
      _response(400, {
        'message': ['name should not be empty', 'rentAmount must be a number'],
      }),
    );
    expect(e.message, 'name should not be empty\nrentAmount must be a number');
  });

  test('400 without a message falls back to human copy', () {
    final e = mapDioException(_response(400, null));
    expect(e, isA<BadRequestException>());
    expect(e.message, isNotEmpty);
  });

  test('backend vocabulary becomes product language', () {
    final e = mapDioException(
      _response(400, {'message': 'Room already has an active tenant'}),
    );
    expect(e.message, 'Unit already has an active tenant');
    expect(
      humanizeServerMessage('Invalid OTP code.'),
      'Invalid code.',
    );
    expect(
      humanizeServerMessage('Organization not found'),
      'Portfolio not found',
    );
    expect(humanizeServerMessage('Bathroom leak'), 'Bathroom leak');
  });

  test('401 without a token is a sign-in failure', () {
    final e = mapDioException(_response(401, {'message': 'Invalid credentials'}));
    expect(e, isA<UnauthorizedException>());
    expect((e as UnauthorizedException).sessionEnded, isFalse);
    expect(e.message, contains("couldn't sign you in"));
  });

  test('401 with a token means the session ended', () {
    final e = mapDioException(_response(401, null, sentAuth: true));
    expect((e as UnauthorizedException).sessionEnded, isTrue);
    expect(e.message, 'Your session has ended. Please sign in again.');
  });

  test('403 never shows the raw server text', () {
    final e = mapDioException(
      _response(403, {'message': 'You do not have permission to access this resource.'}),
    );
    expect(e, isA<ForbiddenException>());
    expect(e.message, isNot(contains('resource')));
  });

  test('404 hides framework route messages', () {
    final e = mapDioException(
      _response(404, {'message': 'Cannot GET /auth/passkey-preview/RTR-ABC123'}),
    );
    expect(e, isA<NotFoundException>());
    expect(e.message, isNot(contains('Cannot GET')));
  });

  test('404 keeps a meaningful server message', () {
    final e = mapDioException(_response(404, {'message': 'Invalid passkey'}));
    expect(e.message, 'Invalid passkey');
  });

  test('409', () {
    expect(mapDioException(_response(409, null)), isA<ConflictException>());
  });

  test('5xx', () {
    for (final status in [500, 502, 503]) {
      final e = mapDioException(_response(status, '<html>Bad gateway</html>'));
      expect(e, isA<ServerException>());
      expect(e.message, isNot(contains('html')));
    }
  });

  test('parse errors', () {
    expect(
      mapDioException(_ofType(DioExceptionType.unknown, error: const FormatException())),
      isA<ParseException>(),
    );
  });

  test('messageFor never leaks non-app errors', () {
    expect(messageFor(StateError('boom')), isNot(contains('boom')));
  });
}
