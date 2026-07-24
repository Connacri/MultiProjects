# Planning Snapshot Cache Strategy

## Goal

A planning month is generated once, persisted, and reused. Opening an already published month must be a database read and must not invoke the rotation engine.

## Read path

```text
Request month
    ↓
Find published snapshot by (branch, year, month)
    ↓
Check configuration ID/version
    ├── Valid → return snapshot directly
    └── Missing → generation path
```

## Generation path

```text
Requested month
    ↓
Snapshot exists?
    ├── Yes → never recalculate
    └── No
         ↓
Find latest published snapshot before requested month
         ↓
Use ONLY its RotationStateSnapshot for forward continuity
         ↓
Load current staff + leaves
         ↓
Generate requested month
         ↓
Save draft
         ↓
Validate
         ↓
Publish atomically
         ↓
Persist new RotationStateSnapshot
```

## Important rule

A previous snapshot is never used to reconstruct or recalculate its own assignments. It is only a continuity checkpoint for generating a later month.

## Configuration changes

A configuration version is part of the cache key. A snapshot generated with configuration version N is never silently treated as equivalent to version N+1.

If the user creates a new configuration version, future planning can be generated with that version. Existing published snapshots remain immutable.

## Personnel changes

Current personnel and leave data are inputs for a newly generated month. They do not invalidate or recalculate already published months.

## Continuity chain

```text
Jan V1 [published]
    ↓ state
Feb V1 [published]
    ↓ state
Mar V1 [published]
    ↓ state
Apr V1 [not generated]
```

Opening April generates it from the latest valid published continuity state. January, February, and March remain untouched.

## Performance

Use indexed lookups for:

- branchId + year + month;
- configurationId + configurationVersion;
- published status.

The normal path for an existing month is O(1)-style indexed retrieval rather than rotation recalculation.
