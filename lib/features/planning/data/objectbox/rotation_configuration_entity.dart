import 'package:objectbox/objectbox.dart';

@Entity()
class RotationConfigurationEntity {
  @Id()
  int id = 0;

  @Index()
  int branchId = 0;

  @Index()
  int version = 1;

  String name = '';
  String teamOrderJson = '[]';
  String cycleJson = '[]';
  int policy = 0;
  int referenceDateEpochMs = 0;
  int referencePhaseIndex = 0;
  bool active = true;
}

@Entity()
class RotationPeriodEntity {
  @Id()
  int id = 0;

  @Index()
  int branchId = 0;

  @Index()
  int startDateEpochMs = 0;

  int? endDateEpochMs;
  int configurationId = 0;
}

@Entity()
class PlanningOverrideEntity {
  @Id()
  int id = 0;

  @Index()
  int snapshotId = 0;

  @Index()
  int staffId = 0;

  @Index()
  int dateEpochMs = 0;

  String? team;
  String shift = '';
  String? code;
  String? note;
}
