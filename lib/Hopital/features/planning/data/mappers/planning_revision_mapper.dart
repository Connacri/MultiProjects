import 'dart:convert';

import '../../domain/entities/planning_revision.dart';
import '../objectbox/planning_revision_entity.dart';

class PlanningRevisionMapper {
  const PlanningRevisionMapper();

  PlanningRevision fromObjectBox(PlanningRevisionEntity entity) {
    final decoded = jsonDecode(entity.changedFieldsJson);
    final fields = decoded is List
        ? decoded.whereType<String>().toList(growable: false)
        : const <String>[];

    return PlanningRevision(
      id: entity.revisionId,
      baseSnapshotId: entity.baseSnapshotId,
      effectiveSnapshotId: entity.effectiveSnapshotId,
      year: entity.year,
      month: entity.month,
      revision: entity.revision,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(
        entity.modifiedAtEpochMs,
      ),
      modifiedBy: entity.modifiedBy,
      changedFields: fields,
      validated: entity.validated,
    );
  }

  PlanningRevisionEntity toObjectBox(PlanningRevision revision) {
    return PlanningRevisionEntity(
      revisionId: revision.id,
      baseSnapshotId: revision.baseSnapshotId,
      effectiveSnapshotId: revision.effectiveSnapshotId,
      year: revision.year,
      month: revision.month,
      revision: revision.revision,
      modifiedAtEpochMs: revision.modifiedAt.millisecondsSinceEpoch,
      modifiedBy: revision.modifiedBy,
      changedFieldsJson: jsonEncode(revision.changedFields),
      validated: revision.validated,
    );
  }
}
