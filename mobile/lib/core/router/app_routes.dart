import '../../features/auth/models/app_user.dart';

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
  static const rentalSetup = '/rental/setup';
  static const rentalEdit = '/rental/edit';

  static const landlordDashboard = '/landlord/dashboard';
  static const landlordProperties = '/landlord/properties';
  static const landlordPayments = '/landlord/payments';
  static const landlordOperations = '/landlord/operations';
  static const landlordAccount = '/landlord/account';
  static const landlordTenants = '$landlordProperties/tenants';
  static String tenancy(String id) => '$landlordTenants/$id';
  static String building(String id) => '$landlordProperties/$id';
  static String unit(String buildingId, String unitId) =>
      '${building(buildingId)}/units/$unitId';
  static String payment(String id) => '$landlordPayments/$id';
  static String issue(String id) => '$landlordOperations/$id';

  static const newBuilding = '/landlord/buildings/new';
  static String editBuilding(String id) => '/landlord/buildings/$id/edit';
  static String addUnits(String buildingId, {bool afterNewBuilding = false}) =>
      '/landlord/buildings/$buildingId/units/new'
      '${afterNewBuilding ? '?next=building' : ''}';
  static String editUnit(String buildingId, String unitId) =>
      '/landlord/buildings/$buildingId/units/$unitId/edit';
  static String inviteTenant(String buildingId, String unitId) =>
      '/landlord/buildings/$buildingId/units/$unitId/invite';
  static String recordPayment({String? tenancyId}) =>
      '/landlord/record-payment'
      '${tenancyId == null ? '' : '?tenancy=$tenancyId'}';
  static const editPortfolio = '/landlord/portfolio/edit';

  /// Reachable without a session.
  static const signedOutRoutes = {
    welcome,
    login,
    createAccount,
    verifyEmail,
    privacy,
    role,
  };

  /// Leave these once signed in. Role is excluded because it creates the
  /// session and then moves on to setup by itself.
  static const signedOutOnly = {splash, welcome, login, createAccount, verifyEmail};

  static const _tenantAreas = [home, payments, household, activity, account, '/rental'];

  static String homeFor(UserRole? role) =>
      role == UserRole.tenant ? home : landlordDashboard;
}

enum AuthStatus { loading, signedOut, signedIn }

bool _within(String location, String area) =>
    location == area || location.startsWith('$area/');

/// Pure redirect rule, kept separate from go_router so it can be unit tested.
String? resolveRedirect({
  required String location,
  required AuthStatus status,
  UserRole? role,
}) {
  switch (status) {
    case AuthStatus.loading:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case AuthStatus.signedOut:
      return AppRoutes.signedOutRoutes.contains(location)
          ? null
          : AppRoutes.welcome;
    case AuthStatus.signedIn:
      if (AppRoutes.signedOutOnly.contains(location)) {
        return AppRoutes.homeFor(role);
      }
      final inLandlordArea = _within(location, '/landlord');
      final inTenantArea =
          AppRoutes._tenantAreas.any((area) => _within(location, area));
      if (role == UserRole.tenant && inLandlordArea) return AppRoutes.home;
      if (role != UserRole.tenant && inTenantArea) {
        return AppRoutes.landlordDashboard;
      }
      return null;
  }
}
