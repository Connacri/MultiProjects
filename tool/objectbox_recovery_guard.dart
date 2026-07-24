import 'dart:io';

void main() {
  final source = File('lib/objectBox/classeObjectBox.dart');
  if (!source.existsSync()) {
    stderr.writeln('Missing lib/objectBox/classeObjectBox.dart');
    exitCode = 2;
    return;
  }

  final text = source.readAsStringSync();
  final forbidden = <String>[
    '_forceDeleteDatabase',
    'dir.delete(recursive: true)',
    'Directory(path).delete',
  ];

  final violations = forbidden.where(text.contains).toList(growable: false);
  if (violations.isNotEmpty) {
    stderr.writeln(
      'ObjectBox recovery guard failed. Automatic database deletion is '
      'forbidden: ${violations.join(', ')}',
    );
    exitCode = 1;
    return;
  }

  if (!text.contains('Local data was preserved')) {
    stderr.writeln(
      'ObjectBox recovery guard failed. The model-mismatch path must '
      'explicitly preserve local data.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('ObjectBox recovery guard passed.');
}
