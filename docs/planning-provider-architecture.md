# Planning Provider Architecture

The presentation layer is split into three responsibilities.

## PlanningProvider

Coordinates the workflow:

- generate draft;
- expose loading/error state;
- publish draft;
- prevent concurrent generate/publish calls.

It does not contain rotation rules or ObjectBox queries.

## PlanningEditorProvider

Owns only the in-memory draft editing session.

- cell edits become explicit `PlanningOverride` objects;
- no direct ObjectBox writes;
- edits are immutable at the snapshot level;
- publication is still controlled by the publication use case.

## PlanningHistoryProvider

Read-only access to historical snapshots.

Opening a historical month can only call `findByMonth`. It cannot invoke generation or publication.

## UI rule

The planning grid should subscribe only to the smallest required Provider scope. A single cell edit must not force unrelated pages or expensive data sources to rebuild.

For large grids, prefer selector-based subscriptions or dedicated cell view models. Keep the immutable `PlanningSnapshot` as the canonical state and derive display-only indexes in memory.
