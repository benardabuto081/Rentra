import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../auth/models/app_user.dart';
import '../../auth/models/session.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/session_providers.dart';
import 'onboarding_draft.dart';

/// The choices on the role screen. Owners and property managers are both
/// landlords; caretakers join by invitation only.
enum OnboardingRole {
  renter,
  owner,
  manager;

  UserRole get accountRole =>
      this == OnboardingRole.renter ? UserRole.tenant : UserRole.landlord;
}

final registrationProvider = Provider<Registration>(Registration.new);

class Registration {
  Registration(this._ref);

  final Ref _ref;

  bool get hasDraft => _ref.read(onboardingDraftProvider) != null;

  /// Creates the account for [role] from the onboarding draft and saves the
  /// session. If a session already exists it is returned unchanged, so a
  /// repeated confirmation never registers twice.
  Future<Session> register(OnboardingRole role) async {
    final existing = _ref.read(sessionControllerProvider).value;
    if (existing != null) return existing;

    final draft = _ref.read(onboardingDraftProvider);
    if (draft == null) throw StateError('No onboarding draft');

    final auth = _ref.read(authRepositoryProvider);
    final session = switch (role.accountRole) {
      UserRole.tenant => await auth.registerTenant(
          firstName: draft.firstName,
          lastName: draft.lastName,
          phone: draft.phone,
          email: draft.email,
          password: draft.password,
        ),
      _ => await auth.registerLandlord(
          firstName: draft.firstName,
          lastName: draft.lastName,
          email: draft.email,
          password: draft.password,
        ),
    };
    await _ref.read(sessionControllerProvider.notifier).establish(session);
    _ref.read(onboardingDraftProvider.notifier).clear();
    return session;
  }
}

/// Human explanation of a failed registration, and whether signing in is the
/// right next step.
({String message, bool alreadyRegistered}) describeRegistrationFailure(
  AppException error,
) {
  final text = error.message.toLowerCase();
  final duplicate = (error is BadRequestException || error is ConflictException) &&
      text.contains('already registered');
  if (!duplicate) return (message: error.message, alreadyRegistered: false);
  return (
    message: text.contains('phone')
        ? 'That phone number is already registered. Try signing in instead.'
        : 'That email is already registered. Try signing in instead.',
    alreadyRegistered: true,
  );
}
