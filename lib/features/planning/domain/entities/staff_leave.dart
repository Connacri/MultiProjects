class StaffLeave {
  final int staffId;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;

  const StaffLeave({
    required this.staffId,
    required this.startDate,
    required this.endDate,
    this.reason,
  });

  bool covers(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}
