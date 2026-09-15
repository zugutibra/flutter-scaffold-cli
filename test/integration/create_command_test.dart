@Tags(['e2e'])
library;

// End-to-end: actually shells out to `flutter create` and runs the full
// generator, then asserts the resulting file tree. Slow and requires the
// Flutter SDK on PATH — skipped automatically if it isn't found.
// Run explicitly with: dart test --tags e2e
import 'dart:io';

import 'package:flutter_scaffold_cli/src/utils/process_runner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final cliEntry = p.join(Directory.current.path, 'bin', 'clean_flutter.dart');

  late Directory workDir;

  setUp(
    () => workDir = Directory.systemTemp.createTempSync('clean_flutter_e2e_'),
  );
  tearDown(() {
    if (workDir.existsSync()) workDir.deleteSync(recursive: true);
  });

  test(
    'create generates the expected Clean Architecture file tree',
    () async {
      final available = await isExecutableAvailable('flutter');
      if (!available) {
        markTestSkipped('flutter not found on PATH');
        return;
      }

      final result = await Process.run('dart', [
        'run',
        cliEntry,
        'create',
        'e2e_demo',
        '--db',
        'none',
      ], workingDirectory: workDir.path);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

      final projectDir = Directory(p.join(workDir.path, 'e2e_demo'));
      expect(projectDir.existsSync(), isTrue);

      const expectedFiles = [
        'lib/main.dart',
        'lib/core/di/injection_container.dart',
        'lib/core/errors/failures.dart',
        'lib/core/errors/exceptions.dart',
        'lib/core/usecases/usecase.dart',
        'lib/core/utils/input_converter.dart',
        'lib/features/example/domain/entities/todo.dart',
        'lib/features/example/domain/repositories/todo_repository.dart',
        'lib/features/example/domain/usecases/get_todos.dart',
        'lib/features/example/domain/usecases/add_todo.dart',
        'lib/features/example/data/models/todo_model.dart',
        'lib/features/example/data/datasources/todo_local_datasource.dart',
        'lib/features/example/data/repositories/todo_repository_impl.dart',
        'lib/features/example/presentation/bloc/todo_bloc.dart',
        'lib/features/example/presentation/bloc/todo_event.dart',
        'lib/features/example/presentation/bloc/todo_state.dart',
        'lib/features/example/presentation/pages/todo_page.dart',
      ];
      for (final relativePath in expectedFiles) {
        final file = File(p.join(projectDir.path, relativePath));
        expect(file.existsSync(), isTrue, reason: '$relativePath should exist');
      }

      // The stale counter-app widget test must not survive generation.
      expect(
        File(p.join(projectDir.path, 'test', 'widget_test.dart')).existsSync(),
        isFalse,
      );

      final pubGetResult = await Process.run('flutter', [
        'pub',
        'get',
      ], workingDirectory: projectDir.path);
      expect(
        pubGetResult.exitCode,
        0,
        reason: '${pubGetResult.stdout}\n${pubGetResult.stderr}',
      );

      final analyzeResult = await Process.run('flutter', [
        'analyze',
      ], workingDirectory: projectDir.path);
      expect(
        analyzeResult.exitCode,
        0,
        reason:
            'generated project must pass flutter analyze:\n${analyzeResult.stdout}',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
