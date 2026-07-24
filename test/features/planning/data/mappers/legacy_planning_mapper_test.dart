import 'package:flutter_test/flutter_test.dart';
import 'package:multi_projects/features/planning/data/mappers/legacy_planning_mapper.dart';
import 'package:multi_projects/features/planning/data/models/planning_persistence_record.dart';
import 'package:multi_projects/features/planning/domain/enums/shift_type.dart';

void main() {
  const mapper = LegacyPlanningMapper();

  test('maps legacy snapshot without invoking rotation engine', () {
    final record = PlanningPersistenceRecord(
      id: 42,
      month: 1,
      year: 2026,
      teamOrder: 'A,B,C,D',
      branchId: 7,
      snapshotJson: '{"activites":[{"staffId":10,"jours":[{"jour":1,"statut":"J"},{"jour":2,"statut":"N"}]}]}',
    );

    final snapshot = mapper.toDomain(record);

    expect(snapshot.id, 'legacy-42');
    expect(snapshot.year, 2026);
    expect(snapshot.month, 1);
    expect(snapshot.branchId, 7);
    expect(snapshot.assignments, hasLength(2));
    expect(snapshot.assignments[0].date, DateTime(2026, 1, 1));
    expect(snapshot.assignments[0].shift, ShiftType.day);
    expect(snapshot.assignments[1].date, DateTime(2026, 1, 2));
    expect(snapshot.assignments[1].shift, ShiftType.night);
  });

  test('preserves unknown legacy status as rest without recalculation', () {
    final record = PlanningPersistenceRecord(
      id: 1,
      month: 2,
      year: 2026,
      teamOrder: 'A,B,C,D',
      branchId: null,
      snapshotJson: '{"activites":[{"staffId":1,"jours":[{"jour":1,"statut":"CM"}]}]}',
    );

    final snapshot = mapper.toDomain(record);

    expect(snapshot.assignments.single.code, 'CM');
    expect(snapshot.assignments.single.shift, ShiftType.rest);
  });

  test('ignores invalid days outside the persisted month', () {
    final record = PlanningPersistenceRecord(
      id: 1,
      month: 2,
      year: 2026,
      teamOrder: 'A,B,C,D',
      branchId: null,
      snapshotJson: '{"activites":[{"staffId":1,"jours":[{"jour":31,"statut":"J"}]}]}',
    );

    final snapshot = mapper.toDomain(record);

    expect(snapshot.assignments, isEmpty);
  });
}
