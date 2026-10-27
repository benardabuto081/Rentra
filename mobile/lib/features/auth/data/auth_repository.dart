import '../../../core/config/endpoints.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/json.dart';
import '../../landlord/models/organization.dart';
import '../models/app_user.dart';
import '../models/passkey_preview.dart';
import '../models/session.dart';

enum OtpChannel { phone, email }

abstract class AuthRepository {
  Future<void> sendOtp({required String recipient, required OtpChannel channel});

  Future<void> verifyOtp({
    required String recipient,
    required OtpChannel channel,
    required String code,
  });

  /// Creates a landlord and their portfolio.
  Future<Session> registerLandlord({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  Future<Session> registerTenant({
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    required String password,
  });

  Future<Session> login({required String email, required String password});

  Future<Session> tenantLogin({required String phone, required String password});

  Future<PasskeyPreview> previewPasskey(String code);

  /// Joins the signed-in tenant to the unit the passkey was issued for.
  Future<Session> linkPasskey({
    required String passkeyCode,
    required double rentAmount,
    required DateTime moveInDate,
  });
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api);

  final ApiClient _api;

  @override
  Future<void> sendOtp({
    required String recipient,
    required OtpChannel channel,
  }) async {
    await _api.post(
      Endpoints.otpSend,
      body: {'recipient': recipient, 'type': channel.name},
      authenticated: false,
    );
  }

  @override
  Future<void> verifyOtp({
    required String recipient,
    required OtpChannel channel,
    required String code,
  }) async {
    final data = await _api.post(
      Endpoints.otpVerify,
      body: {'recipient': recipient, 'type': channel.name, 'code': code},
      authenticated: false,
    );
    final verified = parseObject(data, (json) => json['verified'] == true);
    if (!verified) {
      throw const BadRequestException(
        "That code didn't work. Please check it and try again.",
      );
    }
  }

  @override
  Future<Session> registerLandlord({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      Endpoints.register,
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      },
      authenticated: false,
    );
    return parseObject(data, _sessionFromJson);
  }

  @override
  Future<Session> registerTenant({
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    required String password,
  }) async {
    final data = await _api.post(
      Endpoints.registerTenant,
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        'password': password,
      },
      authenticated: false,
    );
    return parseObject(data, _sessionFromJson);
  }

  @override
  Future<Session> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      Endpoints.login,
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    return parseObject(data, _sessionFromJson);
  }

  @override
  Future<Session> tenantLogin({
    required String phone,
    required String password,
  }) async {
    final data = await _api.post(
      Endpoints.tenantLogin,
      body: {'phone': phone, 'password': password},
      authenticated: false,
    );
    return parseObject(data, _sessionFromJson);
  }

  @override
  Future<PasskeyPreview> previewPasskey(String code) async {
    final data = await _api.get(Endpoints.passkeyPreview(code));
    return parseObject(data, (json) => PasskeyPreview.fromJson(code, json));
  }

  @override
  Future<Session> linkPasskey({
    required String passkeyCode,
    required double rentAmount,
    required DateTime moveInDate,
  }) async {
    final data = await _api.post(
      Endpoints.linkPasskey,
      body: {
        'passkeyCode': passkeyCode,
        'rentAmount': rentAmount,
        'moveInDate': toIsoDate(moveInDate),
      },
    );
    return parseObject(data, _sessionFromJson);
  }

  static Session _sessionFromJson(Map<String, dynamic> json) {
    final org = json['organization'];
    return Session(
      token: requireString(json, 'token'),
      user: AppUser.fromJson(asJsonMap(json['user'])),
      organization: org == null ? null : Organization.fromJson(asJsonMap(org)),
    );
  }
}
