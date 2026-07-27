class LeaveModel {
  final String staffId;
  final DateTime start;
  final DateTime end;
  final String type;

  const LeaveModel({
    required this.staffId,
    required this.start,
    required this.end,
    required this.type,
  });

  bool contains(DateTime day) {
    return !day.isBefore(start) && !day.isAfter(end);
  }
}
