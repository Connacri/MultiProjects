import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:objectbox/objectbox.dart';

import 'package:kenzy/features/planning/data/objectbox/planning_snapshot_entity.dart';
import 'package:kenzy/features/planning/data/objectbox/rotation_state_snapshot_entity.dart';
import 'package:kenzy/features/planning/data/repositories/objectbox_planning_snapshot_store.dart';
import 'package:kenzy/objectbox.g.dart';

void main() {
  late Store store;
  late ObjectBoxPlanningSnapshotStore snapshotStore;

  setUp(() {
    final directory = Directory.systemTemp.createTempSync('planning_snapshot_obx_');
    store = openStore(directory: directory.path);
    snapshotStore = ObjectBoxPlanningSnapshotStore(
      store: store,
      snapshotBox: Box<PlanningSnapshotEntity>(store),
      assignmentBox: Box<PlanningAssignmentEntity>(store),
      rotationStateBox: Box<RotationStateSnapshotEntity>(store),
    );
  });

  tearDown(() {
    store.close();
  });

  PlanningSnapshotEntity snapshot({
    required int branchId,
    required int year,
    required int month,
    required int revision,
    int status = 0,
    int? publishedAtEpochMs,
  }) {
    return PlanningSnapshotEntity()
      ..branchId = branchId
      ..year = year
      ..month = month
      ..configurationId = 'config-1'
      ..configurationVersion = 1
      ..engineVersion = 'test'
      ..revision = revision
      ..status = status
      ..createdAtEpochMs = DateTime(year, month, 1).millisecondsSinceEpoch
      ..publishedAtEpochMs = publishedAtEpochMs;
  }

  RotationStateSnapshotEntity rotationState({
    required int branchId,
    required int year,
    required int month,
    required int revision,
    int phaseIndex = 3,
  }) {
    return RotationStateSnapshotEntity()
      ..branchId = branchId
      ..year = year
      ..month = month
      ..revision = revision
      ..dateEpochMs = DateTime(year, month, 1).millisecondsSinceEpoch
      ..configurationId = 'config-1'
      ..configurationVersion = 1
      ..phaseIndex = phaseIndex
      ..teamPhaseByTeamJson = '{"A":3,"B":4}';
  }

  test('putAtomically persists snapshot, rotation checkpoint and assignments', () {
    final entity = snapshot(
      branchId: 1,
      year: 2026,
      month: 7,
      revision: 2,
    );
    final checkpoint = rotationState(
      branchId: 1,
      year: 2026,
      month: 7,
      revision: 2,
    );
    final assignment = PlanningAssignmentEntity()
      ..staffId = 42
      ..dateEpochMs = DateTime(2026, 7, 24).millisecondsSinceEpoch
      ..team = 'A'
      ..shift = 'J'
      ..code = 'WORK';

    snapshotStore.putAtomically(
      snapshot: entity,
      rotationState: checkpoint,
      assignments: [assignment],
    );

    final stored = snapshotStore.findLatestByMonth(
      year: 2026,
      month: 7,
      branchId: 1,
    );

    expect(stored, isNotNull);
    expect(stored!.revision, 2);
    expect(stored.assignments.length, 1);
    expect(stored.assignments.first.staffId, 42);
    expect(stored.rotationState.target, isNotNull);
    expect(stored.rotationState.target!.phaseIndex, 3);
    expect(stored.rotationState.target!.teamPhaseByTeamJson, '{"A":3,"B":4}');
  });

  test('latest and published reads are deterministic', () {
    final published = snapshot(
      branchId: 1,
      year: 2026,
      month: 7,
      revision: 1,
      status: 1,
      publishedAtEpochMs: DateTime(2026, 7, 10).millisecondsSinceEpoch,
    );
    final publishedState = rotationState(
      branchId: 1,
      year: 2026,
      month: 7,
      revision: 1,
      phaseIndex: 2,
    );
    final modified = snapshot(
      branchId: 1,
      year: 2026,
      month: 7,
      revision: 2,
      status: 2,
    );
    final modifiedState = rotationState(
      branchId: 1,
      year: 2026,
      month: 7,
      revision: 2,
      phaseIndex: 3,
    );

    snapshotStore.putAtomically(
      snapshot: published,
      rotationState: publishedState,
      assignments: const [],
    );
    snapshotStore.putAtomically(
      snapshot: modified,
      rotationState: modifiedState,
      assignments: const [],
    );

    expect(
      snapshotStore.findPublishedByMonth(
        year: 2026,
        month: 7,
        branchId: 1,
      )!.revision,
      1,
    );
    expect(
      snapshotStore.findLatestByMonth(
        year: 2026,
        month: 7,
        branchId: 1,
      )!.revision,
      2,
    );
  });

  test('findByRevision returns the exact immutable snapshot and checkpoint', () {
    snapshotStore.putAtomically(
      snapshot: snapshot(
        branchId: 1,
        year: 2026,
        month: 7,
        revision: 1,
        status: 1,
        publishedAtEpochMs: DateTime(2026, 7, 10).millisecondsSinceEpoch,
      ),
      rotationState: rotationState(
        branchId: 1,
        year: 2026,
        month: 7,
        revision: 1,
        phaseIndex: 2,
      ),
      assignments: const [],
    );
    snapshotStore.putAtomically(
      snapshot: snapshot(
        branchId: 1,
        year: 2026,
        month: 7,
        revision: 2,
        status: 2,
      ),
      rotationState: rotationState(
        branchId: 1,
        year: 2026,
        month: 7,
        revision: 2,
        phaseIndex: 3,
      ),
      assignments: const [],
    );

    final revisionOne = snapshotStore.findByRevision(
      year: 2026,
      month: 7,
      revision: 1,
      branchId: 1,
    );

    expect(revisionOne, isNotNull);
    expect(revisionOne!.revision, 1);
    expect(revisionOne.status, 1);
    expect(revisionOne.publishedAtEpochMs, isNotNull);
    expect(revisionOne.rotationState.target!.revision, 1);
    expect(revisionOne.rotationState.target!.phaseIndex, 2);
  });

  test('rejects a checkpoint belonging to another snapshot revision', () {
    expect(
      () => snapshotStore.putAtomically(
        snapshot: snapshot(
          branchId: 1,
          year: 2026,
          month: 7,
          revision: 2,
        ),
        rotationState: rotationState(
          branchId: 1,
          year: 2026,
          month: 7,
          revision: 1,
        ),
        assignments: const [],
      ),
      throwsArgumentError,
    );
  });

  test('reads isolate snapshots by branch', () {
    snapshotStore.putAtomically(
      snapshot: snapshot(branchId: 1, year: 2026, month: 7, revision: 1),
      rotationState: rotationState(branchId: 1, year: 2026, month: 7, revision: 1),
      assignments: const [],
    );
    snapshotStore.putAtomically(
      snapshot: snapshot(branchId: 2, year: 2026, month: 7, revision: 3),
      rotationState: rotationState(branchId: 2, year: 2026, month: 7, revision: 3),
      assignments: const [],
    );

    expect(
      snapshotStore.findLatestByMonth(year: 2026, month: 7, branchId: 1)!.branchId,
      1,
    );
    expect(
      snapshotStore.findLatestByMonth(year: 2026, month: 7, branchId: 2)!.branchId,
      2,
    );
  });
}
