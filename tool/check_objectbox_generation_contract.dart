import 'dart:io';

void main() {
  final pubspec = File('pubspec.yaml');
  final generated = File('lib/objectbox.g.dart');

  if (!pubspec.existsSync() || !generated.existsSync()) {
    stderr.writeln('ObjectBox generation contract cannot be checked.');
    exitCode = 2;
    return;
  }

  final pubspecText = pubspec.readAsStringSync();
  final generatedText = generated.readAsStringSync();

  final hasGenerator = pubspecText.contains('objectbox_generator:');
  final hasBuildRunner = pubspecText.contains('build_runner:');
  final isGenerated = generatedText.contains('GENERATED CODE - DO NOT MODIFY BY HAND');
  final documentsCommand = generatedText.contains(
    'dart run build_runner build',
  );

  if (!hasGenerator || !hasBuildRunner || !isGenerated || !documentsCommand) {
    stderr.writeln(
      'ObjectBox generation contract is incomplete. Expected objectbox_generator, '
      'build_runner and a generated objectbox.g.dart with the documented '
      'build_runner regeneration command.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('ObjectBox generation contract is valid.');
}
