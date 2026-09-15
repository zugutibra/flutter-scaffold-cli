import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../templates/core_templates.dart';
import '../templates/example_feature_templates.dart';
import '../templates/main_template.dart';
import '../utils/file_writer.dart';
import '../utils/process_runner.dart';
import '../utils/pubspec_editor.dart';
import '../utils/validators.dart';

/// `clean_flutter create <project_name> [--org com.example] [--db isar|hive|none]`
///
/// Scaffolds a brand-new Flutter project matching the Clean Architecture +
/// BLoC layout described in the plan (section 3): runs `flutter create`
/// for a valid base project, strips the counter-app boilerplate, lays down
/// `core/` and `features/example/`, adds starter dependencies, and wires
/// `main.dart` to the DI container.
class CreateCommand extends Command<int> {
  CreateCommand({required this.logger}) {
    argParser
      ..addOption('org', help: 'Organization identifier, e.g. com.example.')
      ..addOption(
        'state',
        allowed: ['bloc'],
        defaultsTo: 'bloc',
        help: 'State management approach (only "bloc" is supported today).',
      )
      ..addOption(
        'db',
        allowed: ['hive', 'isar', 'none'],
        defaultsTo: 'hive',
        help: 'Persistence for the example Todo feature.',
      );
  }

  final Logger logger;

  @override
  String get name => 'create';

  @override
  String get description =>
      'Scaffold a new Flutter project with Clean Architecture + BLoC.';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      logger.err(
        'Missing <project_name>. Usage: clean_flutter create <project_name>',
      );
      return 64;
    }
    final projectName = rest.first;
    final org = argResults!['org'] as String?;
    final db = dbChoiceFromFlag(argResults!['db'] as String);

    try {
      validatePackageName(projectName, kind: 'Project');
    } on NameValidationException catch (e) {
      logger.err(e.message);
      return 64;
    }

    final targetDir = Directory(p.join(Directory.current.path, projectName));
    if (targetDir.existsSync()) {
      logger.err('Directory "${targetDir.path}" already exists.');
      return 65;
    }

    if (!await isExecutableAvailable('flutter')) {
      logger.err(
        'The "flutter" command was not found on your PATH. '
        'Install Flutter first: https://docs.flutter.dev/get-started/install',
      );
      return 69;
    }

    final progress = logger.progress('Running flutter create');
    try {
      await runProcess('flutter', [
        'create',
        if (org != null) ...['--org', org],
        projectName,
      ]);
    } on ProcessFailedException catch (e) {
      progress.fail();
      logger.err(e.toString());
      return 70;
    }
    progress.complete('Base Flutter project created');

    final libDir = p.join(targetDir.path, 'lib');
    final mainFile = File(p.join(libDir, 'main.dart'));
    if (mainFile.existsSync()) mainFile.deleteSync();

    // The default counter-app widget test no longer matches the generated
    // app (it expects a counter and MyApp with no DI); remove it rather
    // than ship a test that fails out of the box.
    final defaultWidgetTest = File(
      p.join(targetDir.path, 'test', 'widget_test.dart'),
    );
    if (defaultWidgetTest.existsSync()) defaultWidgetTest.deleteSync();

    final writer = FileWriter(logger);
    _writeCoreFiles(writer, libDir, projectName, db);
    _writeExampleFeature(writer, libDir, projectName, db);
    writer.write(
      p.join(libDir, 'main.dart'),
      mainDartTemplate(projectName, db),
    );

    _addDependencies(targetDir.path, db);

    logger
      ..success(
        '\n✔ Generated ${writer.writtenPaths.length} files in ${p.relative(targetDir.path)}/',
      )
      ..info('')
      ..info('Next steps:')
      ..info('  cd $projectName')
      ..info('  flutter pub get');
    if (db == DbChoice.isar) {
      logger.info('  dart run build_runner build --delete-conflicting-outputs');
    }
    logger.info('  flutter run');

    return 0;
  }

  void _writeCoreFiles(
    FileWriter writer,
    String libDir,
    String packageName,
    DbChoice db,
  ) {
    final coreDir = p.join(libDir, 'core');
    writer.write(p.join(coreDir, 'errors', 'failures.dart'), failuresTemplate);
    writer.write(
      p.join(coreDir, 'errors', 'exceptions.dart'),
      exceptionsTemplate,
    );
    writer.write(
      p.join(coreDir, 'usecases', 'usecase.dart'),
      usecaseTemplate.replaceAll('{{package_name}}', packageName),
    );
    writer.write(
      p.join(coreDir, 'utils', 'input_converter.dart'),
      inputConverterTemplate.replaceAll('{{package_name}}', packageName),
    );
    writer.write(
      p.join(coreDir, 'di', 'injection_container.dart'),
      injectionContainerTemplate(
        packageName: packageName,
        featureImports: [exampleFeatureDiImports(packageName, db)],
        featureRegistrations: [exampleFeatureDiRegistration(packageName, db)],
      ),
    );
  }

  void _writeExampleFeature(
    FileWriter writer,
    String libDir,
    String packageName,
    DbChoice db,
  ) {
    final featureDir = p.join(libDir, 'features', 'example');

    writer.write(
      p.join(featureDir, 'domain', 'entities', 'todo.dart'),
      todoEntityTemplate(packageName),
    );
    writer.write(
      p.join(featureDir, 'domain', 'repositories', 'todo_repository.dart'),
      todoRepositoryTemplate(packageName),
    );
    writer.write(
      p.join(featureDir, 'domain', 'usecases', 'get_todos.dart'),
      getTodosUsecaseTemplate(packageName),
    );
    writer.write(
      p.join(featureDir, 'domain', 'usecases', 'add_todo.dart'),
      addTodoUsecaseTemplate(packageName),
    );

    writer.write(
      p.join(featureDir, 'data', 'models', 'todo_model.dart'),
      todoModelTemplate(packageName, db),
    );
    writer.write(
      p.join(featureDir, 'data', 'datasources', 'todo_local_datasource.dart'),
      todoLocalDatasourceTemplate(packageName, db),
    );
    writer.write(
      p.join(featureDir, 'data', 'repositories', 'todo_repository_impl.dart'),
      todoRepositoryImplTemplate(packageName),
    );

    writer.write(
      p.join(featureDir, 'presentation', 'bloc', 'todo_event.dart'),
      todoEventTemplate(packageName),
    );
    writer.write(
      p.join(featureDir, 'presentation', 'bloc', 'todo_state.dart'),
      todoStateTemplate(packageName),
    );
    writer.write(
      p.join(featureDir, 'presentation', 'bloc', 'todo_bloc.dart'),
      todoBlocTemplate(packageName),
    );
    writer.write(
      p.join(featureDir, 'presentation', 'pages', 'todo_page.dart'),
      todoPageTemplate(packageName),
    );
  }

  void _addDependencies(String projectDir, DbChoice db) {
    final deps = <String, String>{
      'flutter_bloc': '^9.0.0',
      'equatable': '^2.0.5',
      'get_it': '^8.0.0',
      'dio': '^5.7.0',
      'fpdart': '^1.1.0',
    };
    switch (db) {
      case DbChoice.hive:
        deps['hive'] = '^2.2.3';
        deps['hive_flutter'] = '^1.1.0';
      case DbChoice.isar:
        deps['isar'] = '^3.1.0';
        deps['isar_flutter_libs'] = '^3.1.0';
        deps['path_provider'] = '^2.1.4';
      case DbChoice.none:
        break;
    }
    PubspecEditor(p.join(projectDir, 'pubspec.yaml')).addDependencies(deps);
  }
}
