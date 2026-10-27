class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const createAccount = '/create-account';
  static const verifyEmail = '/verify-email';
  static const privacy = '/privacy';
  static const role = '/role';
  static const tenantSetup = '/setup/tenant';
  static const ownerSetup = '/setup/owner';
  static const tour = '/tour';
  static const home = '/home';
  static const payments = '/payments';
  static const household = '/household';
  static const activity = '/activity';
  static const account = '/account';

  /// Reachable without a session.
  static const signedOutRoutes = {
    welcome,
    login,
    createAccount,
    verifyEmail,
    privacy,
  };

  /// Leave these once signed in. Privacy is excluded because it creates the
  /// session and then moves on by itself.
  static const signedOutOnly = {splash, welcome, login, createAccount, verifyEmail};
}

enum AuthStatus { loading, signedOut, signedIn }

/// Pure redirect rule, kept separate from go_router so it can be unit tested.
String? resolveRedirect({required String location, required AuthStatus status}) {
  switch (status) {
    case AuthStatus.loading:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case AuthStatus.signedOut:
      return AppRoutes.signedOutRoutes.contains(location)
          ? null
          : AppRoutes.welcome;
    case AuthStatus.signedIn:
      return AppRoutes.signedOutOnly.contains(location) ? AppRoutes.home : null;
  }
}
