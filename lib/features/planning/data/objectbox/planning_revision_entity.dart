import 'package:objectbox/objectbox.dart';

/// ObjectBox persistence model for post-validation revisions.
///
/// A revision is an audit record. The original published snapshot is never
/// overwritten. The effective snapshot is stored separately and must pass
/// validation before it can become the next published version.
@Entity()
class PlanningRevisionEntity {
  @Id()
  int id = 0;

  String revisionId;
  String baseSnapshotId;
  String effectiveSnapshotId;
  int year;
  int month;
  int revision;
  int modifiedAtEpochMs;
  String modifiedBy;
  String changedFieldsJson;
  bool validated;

  PlanningRevisionEntity({
    this.id = 0,
    required this.revisionId,
    required this.baseSnapshotId,
    required this.effectiveSnapshotId,
    required this.year,
    required this.month,
    required this.revision,
    required this.modifiedAtEpochMs,
    required this.modifiedBy,
    required this.changedFieldsJson,
    required this.validated,
  });
}
