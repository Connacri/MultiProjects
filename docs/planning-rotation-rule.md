# Planning Rotation Rule

## Canonical 4-day cycle

The default team rotation is a 4-day cycle:

```text
J1 = JOUR
J2 = NUIT
J3 = REPOS
J4 = REPOS
```

Then the same team repeats:

```text
J5 = JOUR
J6 = NUIT
J7 = REPOS
J8 = REPOS
```

The cycle is continuous and is not reset at the beginning of a calendar month.

## Team offset

The team order is configurable. A team can be assigned a phase offset so the global schedule can be represented as a rotation of the same canonical cycle.

Example conceptual offsets:

```text
A: phase 0
B: phase 1
C: phase 2
D: phase 3
```

The exact mapping is configuration data and must not be hard-coded in the UI.

## Monthly continuity

For a continuous policy, the first day of the new month is calculated from the last published rotation state of the previous month.

```text
Previous published month
        ↓
Last rotation state
        ↓
New month day 1
        ↓
Continue cycle
```

This applies especially to paramedical and hygiene groups where the user explicitly requires continuity between months.

## User-configurable logic

The user can change:

- team order;
- team phase offsets;
- cycle length;
- cycle phase definitions;
- continuity policy;
- reference date;
- reference phase.

A configuration change creates a new configuration version. It does not modify historical snapshots.

## Historical safety

A previously published planning is never recalculated because a new configuration is created. The new configuration affects only future periods that have not yet been published.
