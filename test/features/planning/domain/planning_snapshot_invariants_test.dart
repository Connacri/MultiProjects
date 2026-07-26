import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/domain/entities/planning_assignment.dart';
import 'package:multi_projects/features/planning/domain/entities/planning_snapshot.dart';
import 'package:multi_projects/features/planning/domain/validators/planning_snapshot_validator.dart';

void main() {
  group('PlanningSnapshot invariants', () {
    final validator = const PlanningSnapshotValidator();

    PlanningSnapshot snapshot({
      int year = 2026,
      int month = 7,
      int revision = 1,
      DateTime? createdAt,
      DateTime? publishedAt,
      List<PlanningAssignment>? assignments,
    }) {
      final creation = createdAt ?? DateTime.utc(year, month, 1);
      return PlanningSnapshot(
        id: 'snapshot-$year-$month-$revision',
        year: year,
        month: month,
        configurationId: 'rotation-v2',
        configurationVersion: 1,
        engineVersion: 'engine-v2',
        revision: revision,
        createdAt: creation,
        publishedAt: publishedAt,
        assignments: assignments ??
            List.generate(
              DateTime(year, month + 1, 0).day,
              (index) => PlanningAssignment(
                date: DateTime(year, month, index + 1),
              ),
            ),
      );
    }

    test('accepts a complete monthly snapshot', () {
      final result = validator.validate(snapshot());

      expect(result, isEmpty);
    });

    test('rejects assignments outside the snapshot month', () {
      final result = validator.validate(
        snapshot(
          assignments: [
            const PlanningAssignment(date: DateTime(2026, 6, 30)),
          ],
        ),
      );

      expect(result, contains('assignment date is outside the snapshot month'));
      expect(
        result,
        contains('snapshot must contain exactly 31 daily assignments'),
      );
    });

    test('rejects duplicate assignment dates', () {
      final assignments = List.generate(
        31,
        (index) => PlanningAssignment(
          date: DateTime(2026, 7, index == 30 ? 30 : index + 1),
        ),
      );

      final result = validator.validate(snapshot(assignments: assignments));

      expect(result, contains(startsWith('duplicate assignment date:')));
    });

    test('rejects publication before creation', () {
      final result = validator.validate(
        snapshot(
          createdAt: DateTime.utc(2026, 7, 10),
          publishedAt: DateTime.utc(2026, 7, 9),
        ),
      );

      expect(result, contains('publishedAt cannot be before createdAt'));
    });

    test('nextRevision creates a new immutable revision', () {
      final source = snapshot(revision: 3);
      final next = source.nextRevision(
        createdAt: DateTime.utc(2026, 7, 20),
      );

      expect(next.id, isEmpty);
      expect(next.revision, 4);
      expect(next.createdAt, DateTime.utc(2026, 7, 20));
      expect(source.revision, 3);
    });

    test('nextRevision rejects an earlier creation date', () {
      final source = snapshot(
        createdAt: DateTime.utc(2026, 7, 10),
      );

      expect(
        () => source.nextRevision(
          createdAt: DateTime.utc(2026, 7, 9),
        ),
        throwsArgumentError,
      );
    });
  });
}
