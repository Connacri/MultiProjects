# Planning V2 — Supabase Sync

## Architecture

ObjectBox remains the offline-first local read model. Supabase is the remote collaboration/persistence layer.

```text
UI / Provider
    |
    v
Planning Repository
    |
    +--> ObjectBox (read/write local)
    |
    +--> PlanningSyncService
              |
              v
       SupabasePlanningDatasource
              |
              v
           Supabase
```

## Push order

1. Upsert `planning_configurations`.
2. Upsert `planning_snapshots`.
3. Replace `planning_assignments` for the snapshot.
4. Upsert `rotation_state_snapshots`.

The local snapshot must be persisted successfully before a push is started.

## Current limitation

The current ObjectBox entities do not yet persist a Supabase `remoteId` or an explicit sync state. The datasource therefore resolves the remote snapshot by the business key `(branch_id, year, month, revision)`.

Before enabling background sync, realtime, or conflict resolution, add persistent remote identity and sync metadata to ObjectBox. This avoids ambiguous identity after local database recreation or migration.

## RLS

RLS is intentionally left unchanged and disabled for this migration phase, as requested. It must be revisited before production exposure.

## Conflict strategy

Not implemented yet. Do not silently overwrite a newer remote revision. The next implementation phase should compare revision/configuration version and record conflicts explicitly.
