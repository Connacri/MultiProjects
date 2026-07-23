import '../entities/planning.dart';

/// Pure domain service responsible for deterministic team rotation.
///
/// No Flutter, Provider, ObjectBox or network dependency is allowed here.
class RotationEngine {
  const RotationEngine();

  /// Rotates a team order by one position to obtain the next monthly state.
  ///
  /// Example: A,C,B,D -> C,B,D,A.
  List<String> rotate(List<String> order, {int steps = 1}) {
    if (order.isEmpty) return const [];

    final normalizedSteps = steps % order.length;
    if (normalizedSteps == 0) return List.unmodifiable(order);

    return List.unmodifiable([
      ...order.skip(normalizedSteps),
      ...order.take(normalizedSteps),
    ]);
  }

  /// Computes the next month's rotation while keeping the day/night orders
  /// independently controlled.
  Planning nextMonth(Planning current) {
    return current.copyWith(
      year: current.month == 12 ? current.year + 1 : current.year,
      month: current.month == 12 ? 1 : current.month + 1,
      dayTeamOrder: rotate(current.dayTeamOrder),
      nightTeamOrder: rotate(current.nightTeamOrder),
      assignments: const [],
    );
  }

  /// Computes the previous month's rotation.
  Planning previousMonth(Planning current) {
    return current.copyWith(
      year: current.month == 1 ? current.year - 1 : current.year,
      month: current.month == 1 ? 12 : current.month - 1,
      dayTeamOrder: rotate(current.dayTeamOrder, steps: current.dayTeamOrder.length - 1),
      nightTeamOrder:
          rotate(current.nightTeamOrder, steps: current.nightTeamOrder.length - 1),
      assignments: const [],
    );
  }
}
