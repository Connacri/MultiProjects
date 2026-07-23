import 'package:flutter_test/flutter_test.dart';
import 'package:multi_projects/features/planning/domain/entities/planning.dart';
import 'package:multi_projects/features/planning/domain/services/rotation_engine.dart';

void main() {
  const engine = RotationEngine();

  group('RotationEngine', () {
    test('rotates a team order by one position', () {
      expect(
        engine.rotate(const ['A', 'C', 'B', 'D']),
        ['C', 'B', 'D', 'A'],
      );
    });

    test('does not mutate the input order', () {
      final source = ['A', 'C', 'B', 'D'];
      engine.rotate(source);
      expect(source, ['A', 'C', 'B', 'D']);
    });

    test('handles empty order', () {
      expect(engine.rotate(const []), isEmpty);
    });

    test('handles December to January transition', () {
      const planning = Planning(
        year: 2026,
        month: 12,
        dayTeamOrder: ['A', 'C', 'B', 'D'],
        nightTeamOrder: ['D', 'A', 'C', 'B'],
      );

      final next = engine.nextMonth(planning);

      expect(next.year, 2027);
      expect(next.month, 1);
      expect(next.dayTeamOrder, ['C', 'B', 'D', 'A']);
      expect(next.nightTeamOrder, ['A', 'C', 'B', 'D']);
    });

    test('handles January to December transition', () {
      const planning = Planning(
        year: 2026,
        month: 1,
        dayTeamOrder: ['A', 'C', 'B', 'D'],
        nightTeamOrder: ['D', 'A', 'C', 'B'],
      );

      final previous = engine.previousMonth(planning);

      expect(previous.year, 2025);
      expect(previous.month, 12);
      expect(previous.dayTeamOrder, ['D', 'A', 'C', 'B']);
      expect(previous.nightTeamOrder, ['B', 'D', 'A', 'C']);
    });
  });
}
