# Planning Clean Architecture v2

## Status

The planning refactor is being implemented on branch `refactor/planning-clean-architecture-v2`.

## Non-negotiable business rules

1. A team follows `DAY -> NIGHT -> REST -> REST`.
2. Four teams are phase-shifted so each day has one day team, one night team and two rest teams.
3. Team order is configurable by the user; the engine must not hard-code `A/B/C/D`.
4. Published monthly snapshots are historical facts and are never silently recalculated.
5. Opening an existing month is a read operation only.
6. New months are generated as drafts, validated, then published.
7. For paramedical and hygiene, continuity is based on the last published state when the policy requires it.
8. Manual overrides are part of the final published state and therefore influence subsequent continuity.
9. Missing intermediate months must be generated sequentially, because the next month can depend on the previous state.
10. The UI and PDF must consume the same domain snapshot; PDF generation must never recalculate rotation.

## Target architecture

```text
Presentation
  -> Provider
  -> UseCases
  -> Domain
  -> Repository interfaces
  -> ObjectBox datasource
  -> Crud / remote synchronization
```

## Domain components

- `RotationConfiguration`: versioned cycle, team order, policy and reference state.
- `RotationPeriod`: validity interval of a configuration.
- `RotationState`: last known state needed for continuity.
- `PlanningSnapshot`: immutable published monthly aggregate.
- `PlanningAssignment`: individual staff/date assignment.
- `RotationEngine`: pure deterministic team-level rotation service.

## Persistence rule

ObjectBox is an implementation detail of the data layer. Pages and widgets must not query ObjectBox directly.

## No-recalculation invariant

```text
load month
  -> find existing snapshot
  -> return snapshot
  -> never invoke RotationEngine
```

```text
generate month
  -> verify snapshot does not already exist
  -> resolve configuration and rotation period
  -> resolve continuity state when required
  -> generate draft
  -> validate
  -> publish transactionally
```

## Migration strategy

The existing planning implementation remains available while the new domain is introduced. Existing `Planification` snapshots must be treated as legacy historical data and mapped without recomputing their assignments.

## Next implementation stages

1. Complete draft generation with team schedule projection.
2. Add continuity resolver for previous published snapshots.
3. Add planning validator.
4. Add ObjectBox models/datasources and repository implementation.
5. Add Provider orchestration.
6. Migrate the planning page to the new repository/use-case flow.
7. Replace the grid rendering with targeted rebuilds and synchronized scrolling.
8. Make PDF export consume the exact snapshot used by the UI.
9. Add migration tests and integration tests.
10. Run Flutter analyzer and test suite before merging.
