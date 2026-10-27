import '../../../core/utils/json.dart';

enum IssueCategory {
  plumbing('Plumbing'),
  electrical('Electrical'),
  structural('Structural'),
  cleaning('Cleaning'),
  security('Security'),
  appliance('Appliance'),
  other('Other');

  const IssueCategory(this.label);

  final String label;

  static IssueCategory fromJson(Object? raw) =>
      parseEnum(IssueCategory.values, (c) => c.name, raw);
}

enum IssuePriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  urgent('Urgent');

  const IssuePriority(this.label);

  final String label;

  static IssuePriority fromJson(Object? raw) =>
      parseEnum(IssuePriority.values, (p) => p.name, raw);
}

enum IssueStatus {
  pending('pending', 'Open'),
  inProgress('in_progress', 'In progress'),
  resolved('resolved', 'Resolved'),
  cancelled('cancelled', 'Cancelled');

  const IssueStatus(this.wire, this.label);

  final String wire;
  final String label;

  static IssueStatus fromJson(Object? raw) =>
      parseEnum(IssueStatus.values, (s) => s.wire, raw);
}

/// A reported issue. The backend calls this a maintenance request.
class MaintenanceRequest {
  const MaintenanceRequest({
    required this.id,
    required this.organizationId,
    required this.buildingId,
    required this.unitId,
    required this.tenantId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.assignedTo,
    this.resolutionNotes,
    this.cost,
    this.resolvedAt,
    this.createdAt,
  });

  final String id;
  final String organizationId;
  final String buildingId;
  final String unitId;
  final String tenantId;
  final String title;
  final String description;
  final IssueCategory category;
  final IssuePriority priority;
  final IssueStatus status;
  final String? assignedTo;
  final String? resolutionNotes;
  final double? cost;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) =>
      MaintenanceRequest(
        id: requireString(json, 'id'),
        organizationId: requireString(json, 'organizationId'),
        buildingId: requireString(json, 'buildingId'),
        unitId: requireString(json, 'roomId'),
        tenantId: requireString(json, 'tenantId'),
        title: requireString(json, 'title'),
        description: requireString(json, 'description'),
        category: IssueCategory.fromJson(json['category']),
        priority: IssuePriority.fromJson(json['priority']),
        status: IssueStatus.fromJson(json['status']),
        assignedTo: optionalString(json, 'assignedTo'),
        resolutionNotes: optionalString(json, 'resolutionNotes'),
        cost: optionalMoney(json, 'cost'),
        resolvedAt: optionalDate(json, 'resolvedAt'),
        createdAt: optionalDate(json, 'createdAt'),
      );
}
