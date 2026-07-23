# ObjectBox Persistence Design for Planning

## Goals

- Fast lookup of an existing month.
- Immutable published snapshots.
- Forward-only continuity.
- No historical recalculation.
- Atomic publication of snapshot and continuity state.

## Recommended entities

### PlanningSnapshotEntity

Stores the monthly planning header and lifecycle state.

Logical fields:

- id
- branchId
- year
- month
- configurationId
- configurationVersion
- engineVersion
- revision
- status (`draft`, `validated`, `published`, `archived`)
- createdAt
- publishedAt
- continuityStateId

### PlanningAssignmentEntity

Stores one staff/day result.

Logical fields:

- id
- snapshotId
- staffId
- dateEpochDay
- team
- rotationShift
- effectiveShift
- rotationCode
- availabilityCode
- note

### RotationStateSnapshotEntity

Stores the exact state required to continue generation forward.

Logical fields:

- id
- snapshotId
- dateEpochDay
- configurationId
- configurationVersion
- phaseIndex
- serialized team phase map

## Index strategy

The monthly snapshot lookup should be indexed by a deterministic unique logical key:

`branchId + year + month + configurationId + configurationVersion`

If ObjectBox does not support the required composite uniqueness directly for the chosen entity model, store a normalized `cacheKey` string and put a unique index on it.

Example:

`branch:1|2027|04|rotation-main|3`

Assignment lookup should be indexed by:

- `snapshotId`
- `staffId + dateEpochDay` where practical
- `dateEpochDay`

## Publication transaction

Publishing must be one ObjectBox transaction:

1. Verify the draft exists.
2. Verify it is not already published.
3. Validate all assignments.
4. Write/finalize the snapshot.
5. Write all assignments.
6. Write the continuity state.
7. Mark the snapshot published.

If any operation fails, the transaction rolls back.

## Immutability

After `published`:

- assignments cannot be edited in place;
- rotation state cannot be edited in place;
- the published snapshot is never recalculated.

Corrections use a new revision or a new explicit override/audit operation, according to business requirements.

## Forward continuity

When generating month N+1:

- query the latest published snapshot strictly before N+1;
- require the same branch and configuration version;
- load its persisted rotation state;
- generate N+1;
- do not regenerate N.

If there is a gap of several months, the engine may advance the rotation state mathematically across the gap without materializing every missing month, provided the business rules allow generation without historical staff assignments. This avoids unnecessary recalculation.
