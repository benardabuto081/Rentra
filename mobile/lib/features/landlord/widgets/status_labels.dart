import '../../../core/widgets/status_chip.dart';
import '../../maintenance/models/maintenance_request.dart';
import '../../payments/models/payment.dart';
import '../models/tenancy.dart';
import '../models/unit.dart';

(String, StatusTone) unitStatus(UnitStatus status) => switch (status) {
      UnitStatus.vacant => ('Vacant', StatusTone.info),
      UnitStatus.occupied => ('Occupied', StatusTone.success),
      UnitStatus.maintenance => ('Under repair', StatusTone.warning),
      UnitStatus.inactive => ('Not in use', StatusTone.neutral),
    };

(String, StatusTone) tenancyStatus(TenancyStatus status) => switch (status) {
      TenancyStatus.active => ('Active', StatusTone.success),
      TenancyStatus.notice => ('On notice', StatusTone.warning),
      TenancyStatus.vacated => ('Moved out', StatusTone.neutral),
    };

(String, StatusTone) paymentStatus(PaymentStatus status) => switch (status) {
      PaymentStatus.completed => (status.label, StatusTone.success),
      PaymentStatus.partial => (status.label, StatusTone.warning),
      PaymentStatus.pending => (status.label, StatusTone.neutral),
      PaymentStatus.failed => (status.label, StatusTone.attention),
    };

(String, StatusTone) issueStatus(IssueStatus status) => switch (status) {
      IssueStatus.pending => (status.label, StatusTone.warning),
      IssueStatus.inProgress => (status.label, StatusTone.info),
      IssueStatus.resolved => (status.label, StatusTone.success),
      IssueStatus.cancelled => (status.label, StatusTone.neutral),
    };

(String, StatusTone) issuePriority(IssuePriority priority) =>
    switch (priority) {
      IssuePriority.urgent => ('Urgent', StatusTone.attention),
      IssuePriority.high => ('High priority', StatusTone.warning),
      IssuePriority.medium => ('Medium priority', StatusTone.neutral),
      IssuePriority.low => ('Low priority', StatusTone.neutral),
    };

StatusChip chipFor((String, StatusTone) status) =>
    StatusChip(label: status.$1, tone: status.$2);
