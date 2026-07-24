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

  if (!names.contains('PlanningRevisionEntity')) {
    stderr.writeln(
      'PlanningRevisionEntity is not registered in lib/objectbox-model.json. '
      'Register it through the ObjectBox model generation workflow before '
      'using the revision persistence datasource.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('PlanningRevisionEntity is registered in the ObjectBox model.');
}
