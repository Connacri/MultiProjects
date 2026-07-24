# Planning ObjectBox Migration

## Current legacy storage

The current hospital planning storage uses:

- `Planification`: month, year, team order, branch and `activitesJson` snapshot.
- `ActiviteJour`: staff, day number and status.
- `Staff`: personnel metadata and team membership.
- `TimeOff`: staff absence interval.

The new Clean Architecture must not delete or reinterpret these records during migration.

## Migration invariant

```text
Existing Planification
      |
      v
Read legacy snapshot
      |
      v
Map to PlanningSnapshot
      |
      X  NO RotationEngine
      X  NO regeneration
```

## Legacy snapshot mapping

`activitesJson` is parsed as persisted historical data. The mapper reconstructs the original month/date from `Planification.annee` and `Planification.mois`.

Unknown legacy status codes are preserved in `PlanningAssignment.code`. They are mapped to the neutral `rest` domain value only for compatibility with the current `ShiftType` model; the original code remains available for rendering and migration auditing.

## Important limitation

The legacy `activitesJson` format stores `staffId`, `jour` and `statut`, but does not always store the historical team on each assignment. Therefore the migration must not infer a team from today's `Staff.equipe` when historical continuity is required. A future migration step should persist `team` as a snapshot field for all newly generated assignments.

## ObjectBox repository

The repository currently supports safe read operations:

- `findByMonth`
- `exists`
- `findPreviousPublished`

Publication remains intentionally disabled until the new ObjectBox schema is added. This prevents accidentally writing new snapshots with an incomplete persistence model.

## Next schema stage

Add versioned ObjectBox entities for:

- `PlanningSnapshotEntity`
- `PlanningAssignmentEntity`
- `RotationConfigurationEntity`
- `RotationPeriodEntity`
- `PlanningOverrideEntity`

Required indexes:

- snapshot: `(branchId, year, month)` unique
- assignment: `(snapshotId, staffId, date)` unique
- configuration: `(branchId, version)` unique
- rotation period: `(branchId, startDate)`

Published snapshots must be immutable at the application layer. Revisions create a new snapshot/revision record rather than overwriting historical data.
