import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:objectbox/objectbox.dart';

import 'package:kenzy/features/planning/data/datasources/objectbox_planning_revision_datasource.dart';
import 'package:kenzy/features/planning/domain/entities/planning_revision.dart';
import 'package:kenzy/objectbox.g.dart';

void main() {
  late Store store;
  late ObjectBoxPlanningRevisionDataSource datasource;

  setUp(() {
    final directory = Directory.systemTemp.createTempSync('planning_revision_obx_');
    store = openStore(directory: directory.path);
    datasource = ObjectBoxPlanningRevisionDataSource(store: store);
  });

  tearDown(() {
    store.close();
  });

  PlanningRevision revision({
    required String id,
    required int revisionNumber,
    required bool validated,
    List<String> changedFields = const ['leave'],
  }) {
    return PlanningRevision(
      id: id,
      baseSnapshotId: 'published-1',
      effectiveSnapshotId: 'draft-$revisionNumber',
      year: 2026,
      month: 7,
      revision: revisionNumber,
      modifiedAt: DateTime(2026, 7, 24, 10 + revisionNumber),
      modifiedBy: 'admin',
      changedFields: changedFields,
      validated: validated,
    );
  }

  test('persists revision and restores changed fields after reload', () {
    final original = revision(
      id: 'revision-1',
      revisionNumber: 1,
      validated: false,
      changedFields: const ['leave', 'teamOrder'],
    );

    datasource.save(original);

    final restored = datasource.findLatest(year: 2026, month: 7);

    expect(restored, isNotNull);
    expect(restored!.id, original.id);
    expect(restored.effectiveSnapshotId, original.effectiveSnapshotId);
    expect(restored.validated, isFalse);
    expect(restored.changedFields, ['leave', 'teamOrder']);
    expect(datasource.decodeChangedFields(restored), ['leave', 'teamOrder']);
  });

  test('findLatest returns the highest revision for a month', () {
    datasource.save(
      revision(id: 'revision-1', revisionNumber: 1, validated: false),
    );
    datasource.save(
      revision(id: 'revision-2', revisionNumber: 2, validated: false),
    );

    final latest = datasource.findLatest(year: 2026, month: 7);

    expect(latest, isNotNull);
    expect(latest!.id, 'revision-2');
    expect(latest.revision, 2);
  });

  test('validated state survives persistence', () {
    final original = revision(
      id: 'revision-validated',
      revisionNumber: 3,
      validated: true,
      changedFields: const ['teamOrder'],
    );

    datasource.save(original);

    final restored = datasource.findLatest(year: 2026, month: 7);

    expect(restored!.validated, isTrue);
    expect(restored.changedFields, ['teamOrder']);
  });
}
