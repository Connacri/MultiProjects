import 'planning_snapshot.dart';

/// Result of a successful publication.
class PlanningPublication {
  final PlanningSnapshot snapshot;
  final DateTime publishedAt;

  const PlanningPublication({
    required this.snapshot,
    required this.publishedAt,
  });
}
