import 'dart:convert';

import 'package:objectbox/objectbox.dart';

import '../../../../objectbox.g.dart';
import '../../domain/entities/planning_revision.dart';
import '../mappers/planning_revision_mapper.dart';
import '../objectbox/planning_revision_entity.dart';

class ObjectBoxPlanningRevisionDataSource {
  final Box<PlanningRevisionEntity> revisionBox;
  final PlanningRevisionMapper mapper;

  ObjectBoxPlanningRevisionDataSource({
    required Store store,
    this.mapper = const PlanningRevisionMapper(),
  }) : revisionBox = Box<PlanningRevisionEntity>(store);

  PlanningRevision? findLatest({required int year, required int month}) {
    final query = revisionBox
        .query(
          PlanningRevisionEntity_.year.equals(year) &
              PlanningRevisionEntity_.month.equals(month),
        )
        .build();
    try {
      final entities = query.find();
      if (entities.isEmpty) return null;
      entities.sort((a, b) => b.revision.compareTo(a.revision));
      return mapper.fromObjectBox(entities.first);
    } finally {
      query.close();
    }
  }

  bool hasModification({required int year, required int month}) {
    return findLatest(year: year, month: month) != null;
  }

  PlanningRevision save(PlanningRevision revision) {
    final id = revisionBox.put(mapper.toObjectBox(revision));
    final stored = revisionBox.get(id);
    if (stored == null) {
      throw StateError('Unable to persist planning revision ${revision.id}.');
    }
    return mapper.fromObjectBox(stored);
  }

  List<String> decodeChangedFields(PlanningRevision revision) {
    final entity = revisionBox
        .query(PlanningRevisionEntity_.revisionId.equals(revision.id))
        .build();
    try {
      final item = entity.findFirst();
      if (item == null) return const [];
      final decoded = jsonDecode(item.changedFieldsJson);
      return decoded is List
          ? decoded.whereType<String>().toList(growable: false)
          : const [];
    } finally {
      entity.close();
    }
  }
}
