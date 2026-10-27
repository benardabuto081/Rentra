import '../../../core/config/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/json.dart';
import '../models/maintenance_request.dart';

abstract class MaintenanceRepository {
  Future<List<MaintenanceRequest>> list(String orgId);
  Future<List<MaintenanceRequest>> pending(String orgId);
  Future<List<MaintenanceRequest>> forTenant(String orgId, String tenantId);
  Future<MaintenanceRequest> get(String orgId, String requestId);
  Future<MaintenanceRequest> assign(String orgId, String requestId, String assignedTo);

  Future<MaintenanceRequest> resolve(
    String orgId,
    String requestId, {
    required String resolutionNotes,
    double? cost,
  });

  Future<MaintenanceRequest> cancel(String orgId, String requestId);

  Future<MaintenanceRequest> setPriority(
    String orgId,
    String requestId,
    IssuePriority priority,
  );
}

class ApiMaintenanceRepository implements MaintenanceRepository {
  ApiMaintenanceRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<MaintenanceRequest>> list(String orgId) async => parseList(
        await _api.get(Endpoints.maintenance(orgId)),
        MaintenanceRequest.fromJson,
      );

  @override
  Future<List<MaintenanceRequest>> pending(String orgId) async => parseList(
        await _api.get(Endpoints.pendingMaintenance(orgId)),
        MaintenanceRequest.fromJson,
      );

  @override
  Future<List<MaintenanceRequest>> forTenant(
    String orgId,
    String tenantId,
  ) async =>
      parseList(
        await _api.get(Endpoints.maintenanceByTenant(orgId, tenantId)),
        MaintenanceRequest.fromJson,
      );

  @override
  Future<MaintenanceRequest> get(String orgId, String requestId) async =>
      parseObject(
        await _api.get(Endpoints.maintenanceRequest(orgId, requestId)),
        MaintenanceRequest.fromJson,
      );

  @override
  Future<MaintenanceRequest> assign(
    String orgId,
    String requestId,
    String assignedTo,
  ) async =>
      parseObject(
        await _api.patch(
          Endpoints.assignMaintenance(orgId, requestId),
          body: {'assignedTo': assignedTo},
        ),
        MaintenanceRequest.fromJson,
      );

  @override
  Future<MaintenanceRequest> resolve(
    String orgId,
    String requestId, {
    required String resolutionNotes,
    double? cost,
  }) async =>
      parseObject(
        await _api.patch(
          Endpoints.resolveMaintenance(orgId, requestId),
          body: withoutNulls({'resolutionNotes': resolutionNotes, 'cost': cost}),
        ),
        MaintenanceRequest.fromJson,
      );

  @override
  Future<MaintenanceRequest> cancel(String orgId, String requestId) async =>
      parseObject(
        await _api.patch(Endpoints.cancelMaintenance(orgId, requestId)),
        MaintenanceRequest.fromJson,
      );

  @override
  Future<MaintenanceRequest> setPriority(
    String orgId,
    String requestId,
    IssuePriority priority,
  ) async =>
      parseObject(
        await _api.patch(
          Endpoints.maintenancePriority(orgId, requestId),
          body: {'priority': priority.name},
        ),
        MaintenanceRequest.fromJson,
      );
}
