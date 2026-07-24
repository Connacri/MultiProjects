import 'package:objectbox/objectbox.dart';
import 'rotation_state_snapshot_entity.dart';

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

  String configurationId = '';
  int configurationVersion = 0;
  String engineVersion = '';
  int revision = 1;
  int status = 0;
  int createdAtEpochMs = 0;
  int? publishedAtEpochMs;

  /// Persisted checkpoint used to continue rotation into the next month.
  ///
  /// This relation is intentionally independent from assignments. Editing
  /// leave or team order must never mutate the historical rotation checkpoint.
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

  String? team;
  String shift = '';
  String? code;
  String? note;

  final snapshot = ToOne<PlanningSnapshotEntity>();
}
