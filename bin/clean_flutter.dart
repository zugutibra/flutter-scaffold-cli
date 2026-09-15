import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'package:flutter_scaffold_cli/src/commands/create_command.dart';
import 'package:flutter_scaffold_cli/src/commands/generate_feature_command.dart';

const String packageVersion = '0.1.0';

Future<void> main(List<String> arguments) async {
  final logger = Logger();
  final runner =
      CommandRunner<int>(
          'clean_flutter',
          'Scaffold Flutter projects and feature slices with Clean Architecture + BLoC.',
        )
        ..argParser.addFlag(
          'version',
          negatable: false,
          help: 'Print the current version.',
        )
        ..addCommand(CreateCommand(logger: logger))
        ..addCommand(GenerateFeatureCommand(logger: logger));

  if (arguments.contains('--version')) {
    logger.info(packageVersion);
    exit(0);
  }

  try {
    final exitCode = await runner.run(arguments);
    exit(exitCode ?? 0);
  } on UsageException catch (e) {
    logger
      ..err(e.message)
      ..info(e.usage);
    exit(64);
  }
}
