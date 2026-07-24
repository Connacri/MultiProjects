import '../entities/rotation_state_snapshot.dart';

class PlanningCacheKey {
  final int year;
  final int month;
  final int? branchId;
  final String configurationId;
  final int configurationVersion;

  const PlanningCacheKey({
    required this.year,
    required this.month,
    required this.branchId,
    required this.configurationId,
    required this.configurationVersion,
  });
}

class PlanningCachePolicy {
  const PlanningCachePolicy();

  bool canReusePublishedSnapshot({
    required PlanningSnapshotMetadata snapshot,
    required PlanningCacheKey requested,
  }) {
    return snapshot.year == requested.year &&
        snapshot.month == requested.month &&
        snapshot.branchId == requested.branchId &&
        snapshot.configurationId == requested.configurationId &&
        snapshot.configurationVersion == requested.configurationVersion &&
        snapshot.isPublished;
  }

  /// Returns true when a snapshot can be used as the continuity source for
  /// generating a future month. It never means the old month is recalculated.
  bool canUseAsContinuitySource({
    required PlanningSnapshotMetadata snapshot,
    required PlanningCacheKey requested,
    required RotationStateSnapshot? rotationState,
  }) {
    if (!snapshot.isPublished || rotationState == null) return false;
    if (snapshot.branchId != requested.branchId) return false;
    if (rotationState.configurationId != requested.configurationId) return false;
    if (rotationState.configurationVersion != requested.configurationVersion) {
      return false;
    }

    final requestedMonth = DateTime(requested.year, requested.month);
    final snapshotMonth = DateTime(snapshot.year, snapshot.month);
    return snapshotMonth.isBefore(requestedMonth);
  }
}

class PlanningSnapshotMetadata {
  final int year;
  final int month;
  final int? branchId;
  final String configurationId;
  final int configurationVersion;
  final bool isPublished;

  const PlanningSnapshotMetadata({
    required this.year,
    required this.month,
    required this.branchId,
    required this.configurationId,
    required this.configurationVersion,
    required this.isPublished,
  });
}
