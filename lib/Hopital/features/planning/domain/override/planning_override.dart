import 'override_reason.dart';

class PlanningOverride {
  final String staffId;
  final int day;
  final String originalShift;
  final String effectiveShift;
  final OverrideReason reason;
  final String createdBy;

  const PlanningOverride({
    required this.staffId,
    required this.day,
    required this.originalShift,
    required this.effectiveShift,
    required this.reason,
    required this.createdBy,
  });
}
