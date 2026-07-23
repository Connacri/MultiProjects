/// Defines how a rotation obtains its initial state.
enum RotationPolicy {
  /// Start from the configured reference state.
  fixedReference,

  /// Continue from the last published planning snapshot.
  continueFromPreviousPublished,
}
