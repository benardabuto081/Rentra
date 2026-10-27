import '../../../core/config/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/json.dart';
import '../models/building.dart';
import '../models/dashboard.dart';
import '../models/organization.dart';
import '../models/passkey.dart';
import '../models/tenancy.dart';
import '../models/unit.dart';

abstract class OrganizationRepository {
  Future<Organization> get(String orgId);

  Future<Organization> update(
    String orgId, {
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
  });
}

class ApiOrganizationRepository implements OrganizationRepository {
  ApiOrganizationRepository(this._api);

  final ApiClient _api;

  @override
  Future<Organization> get(String orgId) async =>
      parseObject(await _api.get(Endpoints.organization(orgId)), Organization.fromJson);

  @override
  Future<Organization> update(
    String orgId, {
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
  }) async {
    final data = await _api.patch(
      Endpoints.organization(orgId),
      body: withoutNulls({
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
      }),
    );
    return parseObject(data, Organization.fromJson);
  }
}

abstract class BuildingRepository {
  Future<List<Building>> list(String orgId);
  Future<Building> get(String orgId, String buildingId);

  Future<Building> create(
    String orgId, {
    required String name,
    String? address,
    String? city,
    String? county,
    int? totalFloors,
    String? description,
  });

  Future<Building> update(
    String orgId,
    String buildingId, {
    String? name,
    String? address,
    String? city,
    String? county,
    int? totalFloors,
    String? description,
  });

  /// The backend deactivates rather than deletes.
  Future<Building> deactivate(String orgId, String buildingId);
}

class ApiBuildingRepository implements BuildingRepository {
  ApiBuildingRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Building>> list(String orgId) async =>
      parseList(await _api.get(Endpoints.buildings(orgId)), Building.fromJson);

  @override
  Future<Building> get(String orgId, String buildingId) async => parseObject(
        await _api.get(Endpoints.building(orgId, buildingId)),
        Building.fromJson,
      );

  @override
  Future<Building> create(
    String orgId, {
    required String name,
    String? address,
    String? city,
    String? county,
    int? totalFloors,
    String? description,
  }) async {
    final data = await _api.post(
      Endpoints.buildings(orgId),
      body: withoutNulls({
        'name': name,
        'address': address,
        'city': city,
        'county': county,
        'totalFloors': totalFloors,
        'description': description,
      }),
    );
    return parseObject(data, Building.fromJson);
  }

  @override
  Future<Building> update(
    String orgId,
    String buildingId, {
    String? name,
    String? address,
    String? city,
    String? county,
    int? totalFloors,
    String? description,
  }) async {
    final data = await _api.patch(
      Endpoints.building(orgId, buildingId),
      body: withoutNulls({
        'name': name,
        'address': address,
        'city': city,
        'county': county,
        'totalFloors': totalFloors,
        'description': description,
      }),
    );
    return parseObject(data, Building.fromJson);
  }

  @override
  Future<Building> deactivate(String orgId, String buildingId) async =>
      parseObject(
        await _api.delete(Endpoints.building(orgId, buildingId)),
        Building.fromJson,
      );
}

abstract class UnitRepository {
  Future<List<Unit>> list(String orgId, String buildingId);
  Future<List<Unit>> vacant(String orgId, String buildingId);
  Future<Unit> get(String orgId, String buildingId, String unitId);

  Future<Unit> create(
    String orgId,
    String buildingId, {
    required String name,
    required double rentAmount,
    UnitType? type,
    int? floor,
    double? storageAmount,
    String? description,
  });

  Future<Unit> update(
    String orgId,
    String buildingId,
    String unitId, {
    String? name,
    double? rentAmount,
    UnitType? type,
    int? floor,
    double? storageAmount,
    String? description,
  });

  Future<Unit> vacate(String orgId, String buildingId, String unitId);
}

class ApiUnitRepository implements UnitRepository {
  ApiUnitRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Unit>> list(String orgId, String buildingId) async =>
      parseList(await _api.get(Endpoints.units(orgId, buildingId)), Unit.fromJson);

  @override
  Future<List<Unit>> vacant(String orgId, String buildingId) async => parseList(
        await _api.get(Endpoints.vacantUnits(orgId, buildingId)),
        Unit.fromJson,
      );

  @override
  Future<Unit> get(String orgId, String buildingId, String unitId) async =>
      parseObject(
        await _api.get(Endpoints.unit(orgId, buildingId, unitId)),
        Unit.fromJson,
      );

  @override
  Future<Unit> create(
    String orgId,
    String buildingId, {
    required String name,
    required double rentAmount,
    UnitType? type,
    int? floor,
    double? storageAmount,
    String? description,
  }) async {
    final data = await _api.post(
      Endpoints.units(orgId, buildingId),
      body: withoutNulls({
        'name': name,
        'rentAmount': rentAmount,
        'type': type?.wire,
        'floor': floor,
        'storageAmount': storageAmount,
        'description': description,
      }),
    );
    return parseObject(data, Unit.fromJson);
  }

  @override
  Future<Unit> update(
    String orgId,
    String buildingId,
    String unitId, {
    String? name,
    double? rentAmount,
    UnitType? type,
    int? floor,
    double? storageAmount,
    String? description,
  }) async {
    final data = await _api.patch(
      Endpoints.unit(orgId, buildingId, unitId),
      body: withoutNulls({
        'name': name,
        'rentAmount': rentAmount,
        'type': type?.wire,
        'floor': floor,
        'storageAmount': storageAmount,
        'description': description,
      }),
    );
    return parseObject(data, Unit.fromJson);
  }

  @override
  Future<Unit> vacate(String orgId, String buildingId, String unitId) async =>
      parseObject(
        await _api.patch(Endpoints.vacateUnit(orgId, buildingId, unitId)),
        Unit.fromJson,
      );
}

abstract class TenancyRepository {
  Future<List<Tenancy>> list(String orgId);
  Future<List<Tenancy>> active(String orgId);
  Future<Tenancy> get(String orgId, String tenancyId);
  Future<Tenancy> giveNotice(String orgId, String tenancyId, DateTime noticeDate);
  Future<Tenancy> vacate(String orgId, String tenancyId, DateTime moveOutDate);

  Future<Tenancy> update(
    String orgId,
    String tenancyId, {
    double? rentAmount,
    double? storageAmount,
    String? notes,
  });
}

class ApiTenancyRepository implements TenancyRepository {
  ApiTenancyRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Tenancy>> list(String orgId) async =>
      parseList(await _api.get(Endpoints.tenancies(orgId)), Tenancy.fromJson);

  @override
  Future<List<Tenancy>> active(String orgId) async => parseList(
        await _api.get(Endpoints.activeTenancies(orgId)),
        Tenancy.fromJson,
      );

  @override
  Future<Tenancy> get(String orgId, String tenancyId) async => parseObject(
        await _api.get(Endpoints.tenancy(orgId, tenancyId)),
        Tenancy.fromJson,
      );

  @override
  Future<Tenancy> giveNotice(
    String orgId,
    String tenancyId,
    DateTime noticeDate,
  ) async =>
      parseObject(
        await _api.patch(
          Endpoints.tenancyNotice(orgId, tenancyId),
          body: {'noticeDate': toIsoDate(noticeDate)},
        ),
        Tenancy.fromJson,
      );

  @override
  Future<Tenancy> vacate(
    String orgId,
    String tenancyId,
    DateTime moveOutDate,
  ) async =>
      parseObject(
        await _api.patch(
          Endpoints.tenancyVacate(orgId, tenancyId),
          body: {'moveOutDate': toIsoDate(moveOutDate)},
        ),
        Tenancy.fromJson,
      );

  @override
  Future<Tenancy> update(
    String orgId,
    String tenancyId, {
    double? rentAmount,
    double? storageAmount,
    String? notes,
  }) async {
    final data = await _api.patch(
      Endpoints.tenancy(orgId, tenancyId),
      body: withoutNulls({
        'rentAmount': rentAmount,
        'storageAmount': storageAmount,
        'notes': notes,
      }),
    );
    return parseObject(data, Tenancy.fromJson);
  }
}

abstract class DashboardRepository {
  Future<DashboardOverview> overview(String orgId);
  Future<FinancialSummary> financial(String orgId, {required int month, required int year});
  Future<List<BuildingSummary>> buildings(String orgId);
}

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository(this._api);

  final ApiClient _api;

  @override
  Future<DashboardOverview> overview(String orgId) async => parseObject(
        await _api.get(Endpoints.dashboardOverview(orgId)),
        DashboardOverview.fromJson,
      );

  @override
  Future<FinancialSummary> financial(
    String orgId, {
    required int month,
    required int year,
  }) async =>
      parseObject(
        await _api.get(
          Endpoints.dashboardFinancial(orgId),
          query: {'month': month, 'year': year},
        ),
        FinancialSummary.fromJson,
      );

  @override
  Future<List<BuildingSummary>> buildings(String orgId) async => parseList(
        await _api.get(Endpoints.dashboardBuildings(orgId)),
        BuildingSummary.fromJson,
      );
}

abstract class PasskeyRepository {
  Future<Passkey> generate({
    required String unitId,
    required String organizationId,
    required String generatedBy,
    required int expiresInDays,
  });
}

class ApiPasskeyRepository implements PasskeyRepository {
  ApiPasskeyRepository(this._api);

  final ApiClient _api;

  @override
  Future<Passkey> generate({
    required String unitId,
    required String organizationId,
    required String generatedBy,
    required int expiresInDays,
  }) async {
    final data = await _api.post(
      Endpoints.generatePasskey,
      body: {
        'unitId': unitId,
        'organizationId': organizationId,
        'generatedBy': generatedBy,
        'expiresInDays': expiresInDays,
      },
    );
    return parseObject(data, Passkey.fromJson);
  }
}
