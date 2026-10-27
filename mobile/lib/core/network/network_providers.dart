import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/session_providers.dart';
import '../config/app_config.dart';
import 'api_client.dart';
import 'auth_interceptor.dart';
import 'slow_request_tracker.dart';

final slowRequestTrackerProvider = Provider<SlowRequestTracker>((ref) {
  final tracker = SlowRequestTracker();
  ref.onDispose(tracker.dispose);
  return tracker;
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.addAll([
    AuthInterceptor(
      readToken: () => ref.read(sessionControllerProvider).value?.token,
      onSessionExpired: () =>
          ref.read(sessionControllerProvider.notifier).expire(),
    ),
    SlowRequestInterceptor(
      ref.read(slowRequestTrackerProvider),
      threshold: AppConfig.slowRequestThreshold,
    ),
  ]);
  ref.onDispose(dio.close);
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
