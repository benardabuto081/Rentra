import 'package:dio/dio.dart';

import '../network/request_flags.dart';
import 'app_exception.dart';

AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const RequestTimeoutException();
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return const NoConnectionException();
    case DioExceptionType.cancel:
      return const UnknownException();
    case DioExceptionType.badResponse:
      return mapStatus(
        e.response?.statusCode,
        e.response?.data,
        sentAuth: e.requestOptions.extra[RequestFlags.sentAuth] == true,
      );
    case DioExceptionType.unknown:
      if (e.error is FormatException) return const ParseException();
      return const UnknownException();
  }
}

AppException mapStatus(int? status, Object? body, {required bool sentAuth}) {
  final serverMessage = humanizeServerMessage(extractServerMessage(body));
  if (status == null) return const UnknownException();
  if (status >= 500) return const ServerException();
  switch (status) {
    case 400:
    case 422:
      return BadRequestException(serverMessage);
    case 401:
      return UnauthorizedException(sessionEnded: sentAuth);
    case 403:
      return const ForbiddenException();
    case 404:
      return NotFoundException(serverMessage);
    case 409:
      return ConflictException(serverMessage);
    default:
      return const UnknownException();
  }
}

/// Pulls `message` out of a NestJS error body. Handles string and array forms.
String? extractServerMessage(Object? body) {
  if (body is! Map) return null;
  final message = body['message'];
  if (message is String && message.trim().isNotEmpty) return message.trim();
  if (message is List) {
    final parts = message
        .whereType<String>()
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join('\n');
  }
  return null;
}

final _routeNotFound = RegExp(r'^Cannot (GET|POST|PATCH|PUT|DELETE) ');

const _vocabulary = <(String, String)>[
  ('Maintenance request', 'Request'),
  ('maintenance request', 'request'),
  ('Rental relationship', 'Rental'),
  ('rental relationship', 'rental'),
  ('Organization', 'Portfolio'),
  ('organization', 'portfolio'),
  ('OTP code', 'code'),
  ('OTP', 'code'),
  ('Rooms', 'Units'),
  ('rooms', 'units'),
  ('Room', 'Unit'),
  ('room', 'unit'),
];

/// Rewrites backend vocabulary into product language. Returns null for
/// messages that are purely technical.
String? humanizeServerMessage(String? message) {
  if (message == null) return null;
  if (_routeNotFound.hasMatch(message)) return null;
  var result = message;
  for (final (from, to) in _vocabulary) {
    final word = RegExp(r'\b' + RegExp.escape(from) + r'\b');
    result = result.replaceAll(word, to);
  }
  return result;
}
