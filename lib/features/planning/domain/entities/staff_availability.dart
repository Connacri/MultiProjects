enum StaffAvailabilityType {
  available,
  leave,
  sickLeave,
  training,
  mission,
  unavailable,
}

/// A date interval that constrains planning generation.
class StaffAvailability {
  final int staffId;
  final DateTime startDate;
  final DateTime endDate;
  final StaffAvailabilityType type;
  final String? note;

  const StaffAvailability({
    required this.staffId,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.note,
  });

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}
