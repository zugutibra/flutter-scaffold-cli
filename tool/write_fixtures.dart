// Regenerates the golden fixtures under test/fixtures/. Run with:
//   dart run tool/write_fixtures.dart
// after intentionally changing a template's expected output.
import 'dart:io';

import 'package:flutter_scaffold_cli/src/templates/example_feature_templates.dart';
import 'package:flutter_scaffold_cli/src/templates/feature_stub_templates.dart';

void main() {
  final fixturesDir = Directory('test/fixtures')..createSync(recursive: true);

  File(
    '${fixturesDir.path}/todo_entity.dart.fixture',
  ).writeAsStringSync(todoEntityTemplate('demo_app'));
  File(
    '${fixturesDir.path}/todo_bloc.dart.fixture',
  ).writeAsStringSync(todoBlocTemplate('demo_app'));
  File(
    '${fixturesDir.path}/feature_bloc.dart.fixture',
  ).writeAsStringSync(featureBlocTemplate('demo_app', 'payments'));

  stdout.writeln('Wrote fixtures to ${fixturesDir.path}');
}
