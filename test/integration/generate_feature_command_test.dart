import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final cliEntry = p.join(Directory.current.path, 'bin', 'clean_flutter.dart');

  late Directory workDir;

  setUp(() {
    workDir = Directory.systemTemp.createTempSync('clean_flutter_generate_');
    File(p.join(workDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: host_app
environment:
  sdk: ^3.0.0
dependencies:
  hive: ^2.2.3
''');
    Directory(p.join(workDir.path, 'lib')).createSync();
  });

  tearDown(() {
    if (workDir.existsSync()) workDir.deleteSync(recursive: true);
  });

  test('generate feature scaffolds domain/data/presentation folders', () async {
    final result = await Process.run('dart', [
      'run',
      cliEntry,
      'generate',
      'feature',
      'payments',
    ], workingDirectory: workDir.path);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('hive'));

    final featureDir = p.join(workDir.path, 'lib', 'features', 'payments');
    const expectedDirs = [
      'domain/entities',
      'domain/repositories',
      'domain/usecases',
      'data/models',
      'data/datasources',
      'data/repositories',
      'presentation/bloc',
      'presentation/pages',
      'presentation/widgets',
    ];
    for (final dir in expectedDirs) {
      expect(
        Directory(p.join(featureDir, dir)).existsSync(),
        isTrue,
        reason: '$dir should exist',
      );
    }

    const expectedFiles = [
      'domain/repositories/payments_repository.dart',
      'data/repositories/payments_repository_impl.dart',
      'presentation/bloc/payments_event.dart',
      'presentation/bloc/payments_state.dart',
      'presentation/bloc/payments_bloc.dart',
    ];
    for (final file in expectedFiles) {
      expect(
        File(p.join(featureDir, file)).existsSync(),
        isTrue,
        reason: '$file should exist',
      );
    }
  });

  test('refuses to overwrite an existing feature', () async {
    await Process.run('dart', [
      'run',
      cliEntry,
      'generate',
      'feature',
      'payments',
    ], workingDirectory: workDir.path);
    final second = await Process.run('dart', [
      'run',
      cliEntry,
      'generate',
      'feature',
      'payments',
    ], workingDirectory: workDir.path);
    expect(second.exitCode, isNot(0));
    expect(second.stderr, contains('already exists'));
  });
}
