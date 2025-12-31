// lib/Tinder/core/domain/enums/swipe_action.dart

/// Actions possibles lors du swipe
enum SwipeAction {
  pass(0, 'pass'),
  like(1, 'like'),
  superlike(2, 'superlike');

  final int value;
  final String name;

  const SwipeAction(this.value, this.name);

  /// Convertit depuis CardSwiperDirection
  static SwipeAction fromDirection(dynamic direction) {
    final directionStr = direction.toString();
    
    if (directionStr.contains('left')) return SwipeAction.pass;
    if (directionStr.contains('right')) return SwipeAction.like;
    if (directionStr.contains('top')) return SwipeAction.superlike;
    
    return SwipeAction.pass; // Fallback
  }

  /// Convertit depuis un int
  static SwipeAction fromInt(int value) {
    return SwipeAction.values.firstWhere(
      (action) => action.value == value,
      orElse: () => SwipeAction.pass,
    );
  }

  /// Convertit depuis un String
  static SwipeAction fromString(String name) {
    return SwipeAction.values.firstWhere(
      (action) => action.name == name,
      orElse: () => SwipeAction.pass,
    );
  }
}
