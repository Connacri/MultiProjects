import 'package:objectbox/objectbox.dart';

/// Immutable ObjectBox checkpoint used to continue rotation across months.
///
/// This entity is deliberately independent from planning assignments. Future
/// continuity must be restored from this persisted state, never reconstructed
/// from mutable staff assignments or leave edits.
@Entity()
class RotationStateSnapshotEntity {
  @Id()
  int id = 0;

  @Index()
  int branchId = 0;

  @Index()
  int year = 0;

  @Index()
  int month = 0;

  @Index()
  int revision = 0;

  int dateEpochMs = 0;
  String configurationId = '';
  int configurationVersion = 0;
  int phaseIndex = 0;
  String teamPhaseByTeamJson = '{}';

  RotationStateSnapshotEntity();
}
