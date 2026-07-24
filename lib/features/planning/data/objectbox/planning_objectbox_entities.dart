import 'package:objectbox/objectbox.dart';

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
  String? rotationPeriodId;
  String engineVersion = '';
  int revision = 1;
  int createdAtEpochMs = 0;
  int? publishedAtEpochMs;
  String? rotationStateJson;

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
