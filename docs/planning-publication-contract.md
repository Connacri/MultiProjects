# Planning Publication Contract

The planning feature now separates generation from publication.

## Generation

`GeneratePlanning` creates a draft only. It refuses to generate a month that already has a snapshot.

## Publication

`PublishPlanning`:

1. Rechecks that the month does not already exist.
2. Runs integrity checks.
3. Runs domain validation.
4. Adds publication timestamp.
5. Persists the complete snapshot atomically.

## Historical rule

A published snapshot is never regenerated as a side effect of opening the planning screen, changing configuration, or generating another month.

## Concurrency rule

The repository repeats the existence check inside the ObjectBox write transaction. This is a second line of defense against two publication requests racing for the same `(branchId, year, month)` period.

For maximum database-level enforcement, the final ObjectBox schema should also use a deterministic unique business key or a dedicated period entity with a unique index where supported by the project's ObjectBox model configuration.

## Important implementation note

The current repository writes the snapshot with its ToMany assignment relation inside the same transaction. The generated ObjectBox model must be regenerated before compilation. Existing ObjectBox model IDs must never be manually reused or changed.
