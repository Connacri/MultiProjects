import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('lib/objectbox-model.json');
  if (!file.existsSync()) {
    stderr.writeln('Missing lib/objectbox-model.json');
    exitCode = 2;
    return;
  }

  final root = jsonDecode(file.readAsStringSync());
  final entities = (root['entities'] as List?) ?? const [];
  final names = entities
      .whereType<Map>()
      .map((entity) => entity['name'])
      .whereType<String>()
      .toSet();

  const required = {
    'PlanningSnapshotEntity',
    'PlanningAssignmentEntity',
    'RotationConfigurationEntity',
    'RotationPeriodEntity',
    'PlanningOverrideEntity',
    'PlanningRevisionEntity',
  };

  final missing = required.difference(names);
  if (missing.isNotEmpty) {
    stderr.writeln(
      'Planning ObjectBox model is incomplete. Missing entities: '
      '${missing.toList()..sort()}',\n'
      'Run the ObjectBox generator after registering the entities in the '
      'application Store model entry point.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('Planning ObjectBox model contains all required entities.');
}
