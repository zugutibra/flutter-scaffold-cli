import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// Thin wrapper around `dart:io` file writes so command code stays
/// declarative (`writer.write(path, contents)`) and every write is logged
/// the same way.
class FileWriter {
  FileWriter(this.logger);

  final Logger logger;
  final List<String> writtenPaths = [];

  void write(String path, String contents) {
    final file = File(path);
    file.createSync(recursive: true);
    file.writeAsStringSync(contents);
    writtenPaths.add(path);
    logger.detail('  created ${p.relative(path)}');
  }
}
