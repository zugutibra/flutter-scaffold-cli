import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../templates/feature_stub_templates.dart';
import '../utils/file_writer.dart';
import '../utils/pubspec_editor.dart';
import '../utils/string_utils.dart';
import '../utils/validators.dart';

/// `clean_flutter generate feature <feature_name> [--path lib/]`
///
/// Adds a new, empty-but-structured feature slice to an existing project
/// (plan section 5). Not wired into DI automatically — prints a manual
/// registration checklist instead, and reads the project's `pubspec.yaml`
/// to tailor the printed next steps to whatever `--db` it was created with.
class GenerateFeatureCommand extends Command<int> {
  GenerateFeatureCommand({required this.logger}) {
    addSubcommand(_GenerateFeatureFeatureCommand(logger: logger));
  }

  final Logger logger;

  @override
  String get name => 'generate';

  @override
  String get description =>
      'Generate a new feature slice in an existing project.';
}

class _GenerateFeatureFeatureCommand extends Command<int> {
  _GenerateFeatureFeatureCommand({required this.logger}) {
    argParser.addOption(
      'path',
      defaultsTo: 'lib',
      help: 'Path to the lib/ directory of the target project.',
    );
  }

  final Logger logger;

  @override
  String get name => 'feature';

  @override
  String get description =>
      'Generate domain/data/presentation folders for a feature.';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      logger.err(
        'Missing <feature_name>. Usage: clean_flutter generate feature <feature_name>',
      );
      return 64;
    }
    final rawName = rest.first;
    final featureName = StringUtils.toSnakeCase(rawName);

    try {
      validatePackageName(featureName, kind: 'Feature');
    } on NameValidationException catch (e) {
      logger.err(e.message);
      return 64;
    }

    final libPath = argResults!['path'] as String;
    final libDir = Directory(libPath);
    if (!libDir.existsSync()) {
      logger.err(
        '"$libPath" does not exist. Run this from inside a project, or pass --path.',
      );
      return 66;
    }

    final pubspecFile = _findPubspec(libDir);
    if (pubspecFile == null) {
      logger.err(
        'Could not find a pubspec.yaml above "$libPath" to read the package name from.',
      );
      return 66;
    }
    final pubspecContent = pubspecFile.readAsStringSync();
    final packageName = RegExp(
      r'^name:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspecContent)?.group(1);
    if (packageName == null) {
      logger.err('Could not read "name:" from ${pubspecFile.path}.');
      return 66;
    }
    final detectedDb = PubspecEditor.detectDbChoice(pubspecContent);

    final featureDir = p.join(libDir.path, 'features', featureName);
    if (Directory(featureDir).existsSync()) {
      logger.err('Feature "$featureName" already exists at $featureDir.');
      return 65;
    }

    final pascal = StringUtils.toPascalCase(featureName);
    final writer = FileWriter(logger);

    for (final layer in ['domain', 'data', 'presentation']) {
      for (final sub in _subfoldersFor(layer)) {
        Directory(p.join(featureDir, layer, sub)).createSync(recursive: true);
      }
    }

    writer.write(
      p.join(
        featureDir,
        'domain',
        'repositories',
        '${featureName}_repository.dart',
      ),
      featureRepositoryTemplate(packageName, featureName),
    );
    writer.write(
      p.join(
        featureDir,
        'data',
        'repositories',
        '${featureName}_repository_impl.dart',
      ),
      featureRepositoryImplTemplate(packageName, featureName),
    );
    writer.write(
      p.join(featureDir, 'presentation', 'bloc', '${featureName}_event.dart'),
      featureEventTemplate(packageName, featureName),
    );
    writer.write(
      p.join(featureDir, 'presentation', 'bloc', '${featureName}_state.dart'),
      featureStateTemplate(packageName, featureName),
    );
    writer.write(
      p.join(featureDir, 'presentation', 'bloc', '${featureName}_bloc.dart'),
      featureBlocTemplate(packageName, featureName),
    );

    logger
      ..success(
        '\n✔ Generated feature "$featureName" (${writer.writtenPaths.length} files)',
      )
      ..info('')
      ..info('Next steps — this feature is not wired into DI yet:')
      ..info(
        '  1. Add entities/usecases under domain/ and a datasource under data/.',
      )
      ..info('  2. Register in core/di/injection_container.dart:')
      ..info(
        '     sl.registerLazySingleton<${pascal}Repository>(() => ${pascal}RepositoryImpl(...));',
      )
      ..info('     sl.registerFactory(() => ${pascal}Bloc());')
      ..info(
        '  3. Provide ${pascal}Bloc via BlocProvider where you build its UI.',
      )
      ..info(
        '  (detected persistence: $detectedDb — match that in your datasource)',
      );

    return 0;
  }

  List<String> _subfoldersFor(String layer) {
    switch (layer) {
      case 'domain':
        return ['entities', 'repositories', 'usecases'];
      case 'data':
        return ['models', 'datasources', 'repositories'];
      case 'presentation':
        return ['bloc', 'pages', 'widgets'];
      default:
        return [];
    }
  }

  File? _findPubspec(Directory libDir) {
    var dir = libDir.absolute;
    for (var i = 0; i < 4; i++) {
      final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) return pubspec;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
  }
}
