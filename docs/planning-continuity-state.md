# Rotation Continuity State

## Principle

A published planning stores the exact rotation state required to continue the next period.

The next period must not infer continuity by scanning arbitrary staff assignments when a persisted state snapshot is available.

```text
Published PlanningSnapshot
        +
RotationStateSnapshot
        ↓
Next period start state
        ↓
RotationEngine
```

## Why this is required

Manual changes, absences, staff transfers and group changes can make staff assignments different from the original team rotation. The continuity state must represent the rotation engine state, not accidental consequences of staff-level changes.

## Configuration versioning

The continuity state stores:

- configuration ID;
- configuration version;
- final date;
- global phase;
- phase for each team.

If the user changes the rotation configuration, historical continuity states remain tied to the configuration version that generated them.

## Paramédical and hygiene

For continuous monthly groups, the next month's generation reads the last published rotation state. It never restarts at phase zero simply because the calendar changed month.

## Historical immutability

The continuity state belongs to the published snapshot. It must not be rewritten when a new configuration is created.
