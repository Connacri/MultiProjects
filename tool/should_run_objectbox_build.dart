import 'dart:io';

const _objectBoxMarkers = <String>{
  '@Entity',
  '@Id',
  '@Property',
  '@Index',
  '@Unique',
  '@Backlink',
  '@Transient',
  '@HnswIndex',
  'ToOne<',
  'ToMany<',
  'Store(',
};

void main() {
  final changedFiles = _readChangedFiles();
  final shouldRun = changedFiles.any(_looksLikeObjectBoxEntityChange);

  stdout.writeln(shouldRun ? 'true' : 'false');
  stdout.writeln('ObjectBox generation required: $shouldRun');
}

List<String> _readChangedFiles() {
  final raw = Platform.environment['CHANGED_FILES'];
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split('\n')
      .map((file) => file.trim())
      .where((file) => file.isNotEmpty)
      .toList(growable: false);
}

bool _looksLikeObjectBoxEntityChange(String path) {
  if (!path.endsWith('.dart')) return false;
  if (path == 'lib/objectbox.g.dart') return false;
  if (path.startsWith('test/')) return false;
  if (path.startsWith('tool/')) return false;

  final file = File(path);
  if (!file.existsSync()) {
    // Deleted Dart model/entity files can still require ObjectBox generation.
    return path.contains('/entities/') || path.contains('/models/');
  }

  final content = file.readAsStringSync();
  return _objectBoxMarkers.any(content.contains);
}
