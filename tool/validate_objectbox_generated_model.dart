import 'dart:convert';
import 'dart:io';

void main() {
  final modelFile = File('lib/objectbox-model.json');
  final generatedFile = File('lib/objectbox.g.dart');

  if (!modelFile.existsSync()) {
    stderr.writeln('Missing lib/objectbox-model.json');
    exitCode = 2;
    return;
  }

  if (!generatedFile.existsSync()) {
    stderr.writeln('Missing lib/objectbox.g.dart');
    exitCode = 2;
    return;
  }

  final model = jsonDecode(modelFile.readAsStringSync()) as Map<String, dynamic>;
  final entities = (model['entities'] as List?) ?? const [];
  final names = entities
      .whereType<Map>()
      .map((entity) => entity['name'])
      .whereType<String>()
      .toSet();

  const required = {
    'PlanningSnapshotEntity',
    'PlanningAssignmentEntity',
    'RotationStateSnapshotEntity',
    'RotationConfigurationEntity',
    'RotationPeriodEntity',
    'PlanningOverrideEntity',
    'PlanningRevisionEntity',
  };

  final missing = required.difference(names);
  if (missing.isNotEmpty) {
    stderr.writeln(
      'ObjectBox model is missing required Planning entities: '
      '${missing.toList()..sort()}',
    );
    exitCode = 1;
    return;
  }

  final generated = generatedFile.readAsStringSync();
  if (!generated.contains('RotationStateSnapshotEntity')) {
    stderr.writeln(
      'Generated ObjectBox model is stale: '
      'RotationStateSnapshotEntity is missing from lib/objectbox.g.dart. '
      'Run: dart run build_runner build --delete-conflicting-outputs',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('ObjectBox Planning model and generated code are synchronized.');
}
