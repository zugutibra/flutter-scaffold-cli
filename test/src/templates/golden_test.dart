import 'dart:io';

import 'package:flutter_scaffold_cli/src/templates/example_feature_templates.dart';
import 'package:flutter_scaffold_cli/src/templates/feature_stub_templates.dart';
import 'package:test/test.dart';

/// Diffs generated template output against checked-in fixtures. If a
/// template's expected output intentionally changes, regenerate fixtures
/// with `dart run tool/write_fixtures.dart`.
void main() {
  String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

  test('todoEntityTemplate matches golden fixture', () {
    expect(todoEntityTemplate('demo_app'), fixture('todo_entity.dart.fixture'));
  });

  test('todoBlocTemplate matches golden fixture', () {
    expect(todoBlocTemplate('demo_app'), fixture('todo_bloc.dart.fixture'));
  });

  test('featureBlocTemplate matches golden fixture', () {
    expect(
      featureBlocTemplate('demo_app', 'payments'),
      fixture('feature_bloc.dart.fixture'),
    );
  });
}
