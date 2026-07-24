# v2.0.0-rc1

Release Candidate for the planning refactor.

## Included

- Clean Architecture planning module
- Deterministic team rotation engine
- Immutable monthly snapshots
- Continuity state between months
- Legacy ObjectBox read-only migration layer
- Atomic snapshot publication
- Planning validation and integrity checks
- Manual override pipeline
- Staff availability pipeline
- Desktop and mobile provider architecture

## Important rules

- Published snapshots are historical facts.
- Existing published months are never silently recalculated.
- New months are generated from the last published continuity state when the policy requires it.
- Legacy ObjectBox planning data is read as historical data only.

## Status

This branch is frozen as the release candidate baseline for final stabilization and review.
