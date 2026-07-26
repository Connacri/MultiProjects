import 'package:objectbox/objectbox.dart';
import 'rotation_state_snapshot_entity.dart';

import 'planning_sync_state.dart';

@Entity()
class PlanningSnapshotEntity {
  @Id()
  int id = 0;

  @Index()
  int branchId = 0;

  @Index()
  int year = 0;

  @Index()
  int month = 0;

  /// Stable Supabase UUID. Null until the snapshot is uploaded.
  @Index()
  String? remoteId;

  String configurationId = '';
  int configurationVersion = 0;
  String engineVersion = '';
  int revision = 1;
  int status = 0;
  int createdAtEpochMs = 0;
  int? publishedAtEpochMs;

  @Index()
  int syncState = PlanningSyncState.pending.index;

  int? lastSyncedAtEpochMs;
  String? syncError;

  final rotationState = ToOne<RotationStateSnapshotEntity>();

  @Backlink('snapshot')
  final assignments = ToMany<PlanningAssignmentEntity>();
}

@Entity()
class PlanningAssignmentEntity {
  @Id()
  int id = 0;

  @Index()
  int staffId = 0;

  @Index()
  int dateEpochMs = 0;

  /// Stable remote identity. The snapshot relationship remains the local
  /// ObjectBox relationship and is not replaced by this field.
  @Index()
  String? remoteId;

  String? team;
  String shift = '';
  String? code;
  String? note;

  final snapshot = ToOne<PlanningSnapshotEntity>();
}
