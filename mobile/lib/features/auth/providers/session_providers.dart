import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/session_store.dart';
import '../models/app_user.dart';
import '../models/session.dart';

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SecureSessionStore(ref.watch(secureStorageProvider)),
);

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, Session?>(SessionController.new);

class SessionController extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() => ref.read(sessionStoreProvider).read();

  Future<void> establish(Session session) async {
    await ref.read(sessionStoreProvider).save(session);
    ref.read(sessionNoticeProvider.notifier).clear();
    state = AsyncData(session);
  }

  Future<void> signOut() async {
    await ref.read(sessionStoreProvider).clear();
    state = const AsyncData(null);
  }

  /// Called when the server rejects the stored token.
  Future<void> expire() async {
    if (state.value == null) return;
    ref.read(sessionNoticeProvider.notifier).show(
          const UnauthorizedException(sessionEnded: true).message,
        );
    await signOut();
  }
}

/// A one-off message for the Welcome screen, such as a session ending.
final sessionNoticeProvider =
    NotifierProvider<SessionNotice, String?>(SessionNotice.new);

class SessionNotice extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) => state = message;

  void clear() => state = null;
}

final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(sessionControllerProvider).value?.user,
);

final splashDurationProvider = Provider<Duration>(
  (ref) => AppConfig.splashMinimum,
);

/// Completes once the splash has shown for its minimum time.
final splashGateProvider = FutureProvider<void>(
  (ref) => Future<void>.delayed(ref.watch(splashDurationProvider)),
);
