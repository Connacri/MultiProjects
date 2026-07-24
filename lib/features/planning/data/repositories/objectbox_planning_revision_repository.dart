import '../../domain/entities/planning_revision.dart';
import '../datasources/objectbox_planning_revision_datasource.dart';

class ObjectBoxPlanningRevisionRepository {
  final ObjectBoxPlanningRevisionDataSource dataSource;

  const ObjectBoxPlanningRevisionRepository({required this.dataSource});

  PlanningRevision? findLatest({required int year, required int month}) {
    return dataSource.findLatest(year: year, month: month);
  }

  bool hasModification({required int year, required int month}) {
    return dataSource.hasModification(year: year, month: month);
  }

  PlanningRevision save(PlanningRevision revision) {
    return dataSource.save(revision);
  }
}
