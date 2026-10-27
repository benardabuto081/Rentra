import '../../../core/utils/json.dart';

class DashboardOverview {
  const DashboardOverview({
    required this.totalBuildings,
    required this.activeTenants,
    required this.tenantsOnNotice,
    required this.openIssues,
  });

  final int totalBuildings;
  final int activeTenants;
  final int tenantsOnNotice;
  final int openIssues;

  factory DashboardOverview.fromJson(Map<String, dynamic> json) =>
      DashboardOverview(
        totalBuildings: optionalInt(json, 'totalBuildings') ?? 0,
        activeTenants: optionalInt(json, 'totalActiveTenants') ?? 0,
        tenantsOnNotice: optionalInt(json, 'totalNoticeTenants') ?? 0,
        openIssues: optionalInt(json, 'totalPendingMaintenance') ?? 0,
      );
}

class FinancialSummary {
  const FinancialSummary({
    required this.month,
    required this.year,
    required this.expected,
    required this.collected,
    required this.collectionRate,
    required this.outstanding,
    required this.outstandingCount,
  });

  final int month;
  final int year;
  final double expected;
  final double collected;
  final int collectionRate;
  final double outstanding;
  final int outstandingCount;

  factory FinancialSummary.fromJson(Map<String, dynamic> json) =>
      FinancialSummary(
        month: requireInt(json, 'month'),
        year: requireInt(json, 'year'),
        expected: moneyOrZero(json, 'totalExpected'),
        collected: moneyOrZero(json, 'totalCollected'),
        collectionRate: optionalInt(json, 'collectionRate') ?? 0,
        outstanding: moneyOrZero(json, 'totalOutstandingArrears'),
        outstandingCount: optionalInt(json, 'totalArrearsCount') ?? 0,
      );
}

class BuildingSummary {
  const BuildingSummary({
    required this.buildingId,
    required this.buildingName,
    required this.totalUnits,
    required this.occupiedUnits,
    required this.vacantUnits,
  });

  final String buildingId;
  final String buildingName;
  final int totalUnits;
  final int occupiedUnits;
  final int vacantUnits;

  factory BuildingSummary.fromJson(Map<String, dynamic> json) =>
      BuildingSummary(
        buildingId: requireString(json, 'buildingId'),
        buildingName: requireString(json, 'buildingName'),
        totalUnits: optionalInt(json, 'totalRooms') ?? 0,
        occupiedUnits: optionalInt(json, 'occupiedRooms') ?? 0,
        vacantUnits: optionalInt(json, 'vacantRooms') ?? 0,
      );
}
