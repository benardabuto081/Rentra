/// Keys stored in Dio `RequestOptions.extra`.
class RequestFlags {
  const RequestFlags._();

  /// Set to false on endpoints that must not carry the session token.
  static const requiresAuth = 'rentra.requiresAuth';

  /// Set by the auth interceptor when a token was attached.
  static const sentAuth = 'rentra.sentAuth';
}
