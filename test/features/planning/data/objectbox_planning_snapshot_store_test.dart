import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:objectbox/objectbox.dart';

import 'package:kenzy/features/planning/data/objectbox/planning_snapshot_entity.dart';
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

  test('putAtomically persists snapshot and all assignments in one transaction', () {
    final entity = snapshot(
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

    snapshotStore.putAtomically(entity, [assignment]);

    final stored = snapshotStore.findLatestByMonth(
      year: 2026,
      month: 7,
      branchId: 1,
    );

    expect(stored, isNotNull);
    expect(stored!.revision, 2);
    expect(stored.assignments.length, 1);
    expect(stored.assignments.first.staffId, 42);
    expect(stored.assignments.first.team, 'A');
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
    final modified = snapshot(
      branchId: 1,
      year: 2026,
      month: 7,
      revision: 2,
      status: 2,
    );

    snapshotStore.putAtomically(published, const []);
    snapshotStore.putAtomically(modified, const []);

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

  test('findByRevision returns the exact immutable snapshot', () {
    snapshotStore.putAtomically(
      snapshot(
        branchId: 1,
        year: 2026,
        month: 7,
        revision: 1,
        status: 1,
        publishedAtEpochMs: DateTime(2026, 7, 10).millisecondsSinceEpoch,
      ),
      const [],
    );
    snapshotStore.putAtomically(
      snapshot(
        branchId: 1,
        year: 2026,
        month: 7,
        revision: 2,
        status: 2,
      ),
      const [],
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
  });

  test('reads isolate snapshots by branch', () {
    snapshotStore.putAtomically(
      snapshot(branchId: 1, year: 2026, month: 7, revision: 1),
      const [],
    );
    snapshotStore.putAtomically(
      snapshot(branchId: 2, year: 2026, month: 7, revision: 3),
      const [],
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
