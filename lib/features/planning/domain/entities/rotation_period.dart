/// Defines the validity interval of a rotation configuration.
class RotationPeriod {
  final String id;
  final String configurationId;
  final int configurationVersion;
  final DateTime startDate;
  final DateTime? endDate;

  const RotationPeriod({
    required this.id,
    required this.configurationId,
    required this.configurationVersion,
    required this.startDate,
    this.endDate,
  });

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = endDate == null
        ? null
        : DateTime(endDate!.year, endDate!.month, endDate!.day);
    return !day.isBefore(start) && (end == null || !day.isAfter(end));
  }
}
