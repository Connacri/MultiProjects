class PlanningAssignmentModel {
  final String staffId;
  final int day;
  final String rotationShift;
  final String effectiveShift;
  final String availability;

  const PlanningAssignmentModel({
    required this.staffId,
    required this.day,
    required this.rotationShift,
    required this.effectiveShift,
    required this.availability,
  });

  bool get isBlocked => availability != 'AVAILABLE';
}
