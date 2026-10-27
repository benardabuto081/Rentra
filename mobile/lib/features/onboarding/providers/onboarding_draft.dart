import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/session_providers.dart';

/// Sign-up details held in memory between onboarding steps. Never persisted.
class OnboardingDraft {
  const OnboardingDraft({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String password;

  @override
  String toString() => 'OnboardingDraft(email: $email)';
}

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftNotifier, OnboardingDraft?>(
  OnboardingDraftNotifier.new,
);

class OnboardingDraftNotifier extends Notifier<OnboardingDraft?> {
  @override
  OnboardingDraft? build() {
    ref.listen(sessionControllerProvider, (previous, next) {
      if (previous?.value != null && next.value == null) clear();
    });
    return null;
  }

  void set(OnboardingDraft draft) => state = draft;

  void clear() => state = null;
}
