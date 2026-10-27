import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../landlord/models/organization.dart';
import '../models/app_user.dart';
import '../models/session.dart';

abstract class SessionStore {
  Future<Session?> read();
  Future<void> save(Session session);
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore(this._storage);

  final FlutterSecureStorage _storage;

  static const tokenKey = 'rentra.session.token';
  static const userKey = 'rentra.session.user';
  static const organizationKey = 'rentra.session.organization';

  @override
  Future<Session?> read() async {
    final token = await _storage.read(key: tokenKey);
    final userJson = await _storage.read(key: userKey);
    if (token == null || token.isEmpty || userJson == null) return null;
    try {
      final orgJson = await _storage.read(key: organizationKey);
      return Session(
        token: token,
        user: AppUser.fromJson(_decode(userJson)),
        organization: orgJson == null
            ? null
            : Organization.fromJson(_decode(orgJson)),
      );
    } on Object {
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(Session session) async {
    await _storage.write(key: tokenKey, value: session.token);
    await _storage.write(key: userKey, value: jsonEncode(session.user.toJson()));
    final org = session.organization;
    if (org == null) {
      await _storage.delete(key: organizationKey);
    } else {
      await _storage.write(key: organizationKey, value: jsonEncode(org.toJson()));
    }
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: userKey);
    await _storage.delete(key: organizationKey);
  }

  static Map<String, dynamic> _decode(String raw) =>
      (jsonDecode(raw) as Map).cast<String, dynamic>();
}
