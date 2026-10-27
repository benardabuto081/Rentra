import 'package:dio/dio.dart';

import 'request_flags.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.readToken, required this.onSessionExpired});

  final String? Function() readToken;
  final void Function() onSessionExpired;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra[RequestFlags.requiresAuth] != false) {
      final token = readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        options.extra[RequestFlags.sentAuth] = true;
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra[RequestFlags.sentAuth] == true) {
      onSessionExpired();
    }
    handler.next(err);
  }
}
