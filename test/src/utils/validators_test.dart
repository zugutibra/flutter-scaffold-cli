import 'package:flutter_scaffold_cli/src/utils/validators.dart';
import 'package:test/test.dart';

void main() {
  group('validatePackageName', () {
    test('accepts a valid lowercase_with_underscores name', () {
      expect(
        () => validatePackageName('todo_list', kind: 'Project'),
        returnsNormally,
      );
    });

    test('rejects an empty name', () {
      expect(
        () => validatePackageName('', kind: 'Project'),
        throwsA(isA<NameValidationException>()),
      );
    });

    test('rejects camelCase', () {
      expect(
        () => validatePackageName('todoList', kind: 'Project'),
        throwsA(isA<NameValidationException>()),
      );
    });

    test('rejects a name starting with a digit', () {
      expect(
        () => validatePackageName('1todo', kind: 'Project'),
        throwsA(isA<NameValidationException>()),
      );
    });

    test('rejects a name with hyphens', () {
      expect(
        () => validatePackageName('todo-list', kind: 'Project'),
        throwsA(isA<NameValidationException>()),
      );
    });

    test('rejects a reserved Dart keyword', () {
      expect(
        () => validatePackageName('class', kind: 'Project'),
        throwsA(isA<NameValidationException>()),
      );
    });
  });
}
