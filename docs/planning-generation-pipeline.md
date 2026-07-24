# Planning Generation Pipeline

The new planning engine follows a strict separation between rotation, staff constraints and manual decisions.

```text
Published previous snapshot
        |
        v
Continuity Resolver
        |
        v
Rotation Configuration + Period
        |
        v
Team Rotation Engine
        |
        v
Team Schedule
        |
        v
Staff Projection
        |
        v
Availability / Leave Constraints
        |
        v
Manual Overrides
        |
        v
Validation
        |
        v
Immutable PlanningSnapshot
        |
        v
Atomic ObjectBox Publication
```

## Precedence rules

1. The team rotation is the baseline and is never changed because one staff member is absent.
2. Availability changes the staff assignment status, not the global team cycle.
3. Manual overrides are applied after availability and therefore represent an explicit human decision.
4. The final result is validated before publication.
5. Once published, the snapshot is historical and must not be recalculated.
6. The next month's continuity reads the last published state, including the final published manual decisions where the policy requires continuity.

## Performance

The rotation is calculated once per date and team. It is not recalculated for every staff member.

For `D` days, `T` teams and `S` staff:

- rotation baseline: `O(D × T)`
- staff projection: `O(D × S)`
- availability: should be indexed by `staffId` and date range in the data layer
- overrides: should be indexed by `(staffId, date)`

The UI should consume an immutable snapshot and use keyed widgets to avoid rebuilding the whole planning grid after a single cell change.
