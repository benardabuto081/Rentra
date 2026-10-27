import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class FakeReply {
  const FakeReply(this.status, this.body, {this.raw = false});

  /// Throws a connection error instead of responding.
  const FakeReply.offline()
      : status = 0,
        body = null,
        raw = false;

  final int status;
  final Object? body;

  /// Send [body] as plain text instead of JSON.
  final bool raw;
}

/// Answers Dio requests from a map keyed by `METHOD /path`.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.replies);

  final Map<String, FakeReply> replies;
  final List<RequestOptions> requests = [];

  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = replies['${options.method} ${options.path}'];
    if (reply == null) {
      return ResponseBody.fromString(
        jsonEncode({
          'message': 'Cannot ${options.method} ${options.path}',
          'error': 'Not Found',
          'statusCode': 404,
        }),
        404,
        headers: _json,
      );
    }
    if (reply.status == 0) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      reply.raw ? '${reply.body}' : jsonEncode(reply.body),
      reply.status,
      headers: reply.raw
          ? {
              Headers.contentTypeHeader: ['text/html'],
            }
          : _json,
    );
  }

  static final _json = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  void close({bool force = false}) {}
}
