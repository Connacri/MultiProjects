import 'staff_member.dart';
import 'staff_leave.dart';
import 'rotation_configuration.dart';

/// Minimal source of truth used to generate a new planning.
///
/// No historical assignments are accepted here by design.
class PlanningInput {
  final int year;
  final int month;
  final List<StaffMember> staff;
  final List<StaffLeave> leaves;
  final RotationConfiguration rotation;
  final int? branchId;

  const PlanningInput({
    required this.year,
    required this.month,
    required this.staff,
    required this.leaves,
    required this.rotation,
    this.branchId,
  });
}
