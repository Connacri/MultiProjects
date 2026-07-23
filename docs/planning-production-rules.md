# Planning Production Rules

## Historical immutability

A published monthly planning is a historical snapshot. It must never be regenerated because the rotation configuration changed later.

If a correction is required after publication, create a new revision or correction record. Do not mutate the original historical snapshot silently.

## Generation safety

Before generating a month:

1. Check whether a published snapshot already exists for `(branchId, year, month)`.
2. If it exists, refuse automatic generation.
3. If it does not exist, resolve the previous published snapshot according to the configured continuity policy.
4. Generate the team rotation.
5. Project the rotation to staff.
6. Apply availability constraints.
7. Apply explicit manual overrides.
8. Validate uniqueness and period boundaries.
9. Persist atomically.

## Rotation continuity

The continuity rule is configuration-driven. For the continuous policy, the previous published month is the source of truth for the next period's starting state.

For paramedical and hygiene groups, the rotation must therefore continue from the actual last published state of the preceding month rather than restarting at day 1 of each calendar month.

## Manual changes

A manual change is an explicit override. It is never overwritten by a subsequent automatic recalculation of the same draft.

Once published, the resulting assignment is part of the historical snapshot. If the next period's continuity policy depends on the final state, the next period reads that published state.

## ObjectBox performance

Use indexed queries for:

- `(branchId, year, month)` snapshot lookup
- `(snapshotId, staffId, date)` assignment lookup
- `(staffId, date)` overrides
- `(branchId, startDate)` rotation periods

Avoid loading the entire planning database for a monthly lookup.

## UI performance

The planning grid should be fed by immutable state and update only affected cells. Avoid rebuilding the entire `DataTable` for every cell edit. Use stable keys and isolate cell-level state where possible.
