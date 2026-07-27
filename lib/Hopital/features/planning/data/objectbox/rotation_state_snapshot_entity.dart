import 'package:objectbox/objectbox.dart';

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

  /// Supabase identity is optional until the checkpoint is synchronized.
  @Index()
  String? remoteId;

  int dateEpochMs = 0;
  String configurationId = '';
  int configurationVersion = 0;
  int phaseIndex = 0;
  String teamPhaseByTeamJson = '{}';

  int syncState = 0;
  int? lastSyncedAtEpochMs;
  String? syncError;

  RotationStateSnapshotEntity();
}
