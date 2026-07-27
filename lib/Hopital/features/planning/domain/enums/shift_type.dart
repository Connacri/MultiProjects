/// Represents the semantic shift assigned to a planning entry.
///
/// Domain-only enum: it has no dependency on Flutter or ObjectBox.
enum ShiftType {
  day,
  night,
  rest,
  leave,
  training,
  activity,
  other,
}
