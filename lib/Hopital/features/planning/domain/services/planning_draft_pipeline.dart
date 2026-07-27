import '../entities/planning_assignment.dart';
import '../entities/planning_override.dart';
import '../entities/staff_availability.dart';
import 'planning_override_applier.dart';
import 'staff_availability_applier.dart';

/// Canonical order for draft post-processing.
///
/// 1. Rotation creates the baseline.
/// 2. Availability marks non-working constraints.
/// 3. Manual overrides have the final word for the draft.
/// 4. The resulting assignments are what gets validated and published.
class PlanningDraftPipeline {
  final StaffAvailabilityApplier availabilityApplier;
  final PlanningOverrideApplier overrideApplier;

  const PlanningDraftPipeline({
    this.availabilityApplier = const StaffAvailabilityApplier(),
    this.overrideApplier = const PlanningOverrideApplier(),
  });

  List<PlanningAssignment> process({
    required List<PlanningAssignment> baseline,
    required List<StaffAvailability> availability,
    required List<PlanningOverride> overrides,
  }) {
    final constrained = availabilityApplier.apply(
      assignments: baseline,
      availability: availability,
    );

    return overrideApplier.apply(
      assignments: constrained,
      overrides: overrides,
    );
  }
}
