import 'dart:io';

import 'package:flutter_scaffold_cli/src/utils/pubspec_editor.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('PubspecEditor.addDependencies', () {
    late Directory tempDir;
    late File pubspec;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('pubspec_editor_test_');
      pubspec = File(p.join(tempDir.path, 'pubspec.yaml'))
        ..writeAsStringSync('''
name: demo
environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  lints: ^6.0.0
''');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('inserts new dependencies under dependencies:', () {
      PubspecEditor(pubspec.path).addDependencies({'flutter_bloc': '^9.0.0'});
      final content = pubspec.readAsStringSync();
      expect(content, contains('  flutter_bloc: ^9.0.0'));
      // still precedes dev_dependencies
      expect(
        content.indexOf('flutter_bloc'),
        lessThan(content.indexOf('dev_dependencies:')),
      );
    });

    test('does not duplicate an already-present dependency', () {
      PubspecEditor(pubspec.path).addDependencies({'flutter': 'sdk: flutter'});
      final content = pubspec.readAsStringSync();
      expect('  flutter:'.allMatches(content).length, 1);
    });
  });

  group('PubspecEditor.detectDbChoice', () {
    test('detects isar', () {
      expect(
        PubspecEditor.detectDbChoice('dependencies:\n  isar: ^3.0.0\n'),
        'isar',
      );
    });

    test('detects hive', () {
      expect(
        PubspecEditor.detectDbChoice('dependencies:\n  hive: ^2.0.0\n'),
        'hive',
      );
    });

    test('defaults to none', () {
      expect(
        PubspecEditor.detectDbChoice('dependencies:\n  path: ^1.0.0\n'),
        'none',
      );
    });
  });
}
