/// Every backend path the app uses. Paths are relative to [AppConfig.apiBaseUrl].
class Endpoints {
  const Endpoints._();

  static const otpSend = '/auth/otp/send';
  static const otpVerify = '/auth/otp/verify';
  static const register = '/auth/register';
  static const registerTenant = '/auth/register-tenant';
  static const login = '/auth/login';
  static const tenantLogin = '/auth/tenant-login';
  static const linkPasskey = '/auth/link-passkey';
  static const generatePasskey = '/auth/generate-passkey';
  static String passkeyPreview(String code) => '/auth/passkey-preview/$code';

  static String organization(String orgId) => '/organizations/$orgId';

  static String buildings(String orgId) => '/organizations/$orgId/buildings';
  static String building(String orgId, String buildingId) =>
      '${buildings(orgId)}/$buildingId';

  static String units(String orgId, String buildingId) =>
      '${building(orgId, buildingId)}/rooms';
  static String vacantUnits(String orgId, String buildingId) =>
      '${units(orgId, buildingId)}/vacant';
  static String unit(String orgId, String buildingId, String unitId) =>
      '${units(orgId, buildingId)}/$unitId';
  static String vacateUnit(String orgId, String buildingId, String unitId) =>
      '${unit(orgId, buildingId, unitId)}/vacate';

  static String tenancies(String orgId) => '/organizations/$orgId/tenants';
  static String activeTenancies(String orgId) => '${tenancies(orgId)}/active';
  static String tenancy(String orgId, String id) => '${tenancies(orgId)}/$id';
  static String tenancyNotice(String orgId, String id) =>
      '${tenancy(orgId, id)}/notice';
  static String tenancyVacate(String orgId, String id) =>
      '${tenancy(orgId, id)}/vacate';

  static String payments(String orgId) => '/organizations/$orgId/payments';
  static String paymentArrears(String orgId) => '${payments(orgId)}/arrears';
  static String paymentStats(String orgId) => '${payments(orgId)}/stats';
  static String paymentsByMonth(String orgId) => '${payments(orgId)}/month';
  static String paymentsByTenant(String orgId, String tenantId) =>
      '${payments(orgId)}/tenant/$tenantId';
  static String payment(String orgId, String id) => '${payments(orgId)}/$id';

  static String maintenance(String orgId) =>
      '/organizations/$orgId/maintenance';
  static String pendingMaintenance(String orgId) =>
      '${maintenance(orgId)}/pending';
  static String maintenanceByTenant(String orgId, String tenantId) =>
      '${maintenance(orgId)}/tenant/$tenantId';
  static String maintenanceRequest(String orgId, String id) =>
      '${maintenance(orgId)}/$id';
  static String assignMaintenance(String orgId, String id) =>
      '${maintenanceRequest(orgId, id)}/assign';
  static String resolveMaintenance(String orgId, String id) =>
      '${maintenanceRequest(orgId, id)}/resolve';
  static String cancelMaintenance(String orgId, String id) =>
      '${maintenanceRequest(orgId, id)}/cancel';
  static String maintenancePriority(String orgId, String id) =>
      '${maintenanceRequest(orgId, id)}/priority';

  static String dashboardOverview(String orgId) =>
      '/organizations/$orgId/dashboard/overview';
  static String dashboardFinancial(String orgId) =>
      '/organizations/$orgId/dashboard/financial';
  static String dashboardBuildings(String orgId) =>
      '/organizations/$orgId/dashboard/buildings';

  static const shadowRentals = '/shadow-relationships';
  static String shadowRental(String id) => '$shadowRentals/$id';
  static String endShadowRental(String id) => '${shadowRental(id)}/end';
}
