import 'dart:io';

void main() {
  final pubspec = File('pubspec.yaml');
  final lockfile = File('pubspec.lock');
  final generated = File('lib/objectbox.g.dart');

  if (!pubspec.existsSync()) {
    stderr.writeln('Missing pubspec.yaml.');
    exitCode = 2;
    return;
  }

  final pubspecText = pubspec.readAsStringSync();
  final lockText = lockfile.existsSync() ? lockfile.readAsStringSync() : '';

  final hasObjectBox = pubspecText.contains(RegExp(r'^\s*objectbox:\s*', multiLine: true));
  final hasObjectBoxFlutterLibs = pubspecText.contains(
    RegExp(r'^\s*objectbox_flutter_libs:\s*', multiLine: true),
  );
  final hasGenerator = pubspecText.contains(
    RegExp(r'^\s*objectbox_generator:\s*', multiLine: true),
  );
  final hasBuildRunner = pubspecText.contains(
    RegExp(r'^\s*build_runner:\s*', multiLine: true),
  );

  if (!hasObjectBox || !hasObjectBoxFlutterLibs || !hasGenerator || !hasBuildRunner) {
    stderr.writeln(
      'ObjectBox build_runner contract is incomplete. Expected objectbox, '
      'objectbox_flutter_libs, objectbox_generator and build_runner.',
    );
    exitCode = 1;
    return;
  }

  if (lockfile.existsSync() && !lockText.contains('objectbox_generator:')) {
    stderr.writeln(
      'pubspec.lock does not contain objectbox_generator. Run '
      '`flutter pub get` before ObjectBox generation.',
    );
    exitCode = 1;
    return;
  }

  if (!generated.existsSync()) {
    stderr.writeln(
      'Missing lib/objectbox.g.dart. Run `dart run build_runner build --delete-conflicting-outputs`.',
    );
    exitCode = 1;
    return;
  }

  final generatedText = generated.readAsStringSync();
  if (!generatedText.contains('GENERATED CODE - DO NOT MODIFY BY HAND')) {
    stderr.writeln(
      'lib/objectbox.g.dart exists but does not look like ObjectBox generated code.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('ObjectBox build_runner contract is valid.');
}
