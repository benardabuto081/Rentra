import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Counts requests that have been pending longer than a threshold.
class SlowRequestTracker extends ChangeNotifier {
  int _slowCount = 0;

  bool get isSlow => _slowCount > 0;

  void _increment() {
    _slowCount++;
    if (_slowCount == 1) notifyListeners();
  }

  void _decrement() {
    if (_slowCount == 0) return;
    _slowCount--;
    if (_slowCount == 0) notifyListeners();
  }
}

class SlowRequestInterceptor extends Interceptor {
  SlowRequestInterceptor(this._tracker, {required this.threshold});

  final SlowRequestTracker _tracker;
  final Duration threshold;
  final Map<RequestOptions, Timer> _timers = {};
  final Set<RequestOptions> _slow = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _timers[options] = Timer(threshold, () {
      _slow.add(options);
      _tracker._increment();
    });
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _finish(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _finish(err.requestOptions);
    handler.next(err);
  }

  void _finish(RequestOptions options) {
    _timers.remove(options)?.cancel();
    if (_slow.remove(options)) _tracker._decrement();
  }
}
