import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import '../errors/error_mapper.dart';
import 'request_flags.dart';

/// Thin wrapper over the single Dio instance. Returns decoded JSON and throws
/// only [AppException].
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) =>
      _send(() => _dio.get<dynamic>(
            path,
            queryParameters: query,
            options: _options(authenticated),
          ));

  Future<dynamic> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) =>
      _send(() => _dio.post<dynamic>(
            path,
            data: body,
            options: _options(authenticated),
          ));

  Future<dynamic> patch(
    String path, {
    Object? body,
    bool authenticated = true,
  }) =>
      _send(() => _dio.patch<dynamic>(
            path,
            data: body,
            options: _options(authenticated),
          ));

  Future<dynamic> delete(String path, {bool authenticated = true}) =>
      _send(() => _dio.delete<dynamic>(
            path,
            options: _options(authenticated),
          ));

  Options _options(bool authenticated) =>
      Options(extra: {RequestFlags.requiresAuth: authenticated});

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

/// Runs [parse] over decoded JSON, turning shape errors into [ParseException].
T parseResponse<T>(Object? data, T Function(Object? data) parse) {
  try {
    return parse(data);
  } on AppException {
    rethrow;
  } on FormatException {
    throw const ParseException();
  } on TypeError {
    throw const ParseException();
  }
}

List<T> parseList<T>(
  Object? data,
  T Function(Map<String, dynamic> json) fromJson,
) =>
    parseResponse(data, (d) {
      if (d is! List) throw const FormatException('Expected a list');
      return d.map((e) => fromJson(asJsonMap(e))).toList(growable: false);
    });

T parseObject<T>(
  Object? data,
  T Function(Map<String, dynamic> json) fromJson,
) =>
    parseResponse(data, (d) => fromJson(asJsonMap(d)));

Map<String, dynamic> asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  throw const FormatException('Expected an object');
}
