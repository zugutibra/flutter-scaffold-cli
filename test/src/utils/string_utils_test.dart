import 'package:flutter_scaffold_cli/src/utils/string_utils.dart';
import 'package:test/test.dart';

void main() {
  group('StringUtils.toSnakeCase', () {
    test('normalizes camelCase', () {
      expect(StringUtils.toSnakeCase('todoList'), 'todo_list');
    });

    test('normalizes PascalCase', () {
      expect(StringUtils.toSnakeCase('TodoList'), 'todo_list');
    });

    test('normalizes kebab-case and spaces', () {
      expect(StringUtils.toSnakeCase('todo-list'), 'todo_list');
      expect(StringUtils.toSnakeCase('todo list'), 'todo_list');
    });

    test('leaves snake_case untouched', () {
      expect(StringUtils.toSnakeCase('todo_list'), 'todo_list');
    });

    test('collapses repeated separators', () {
      expect(StringUtils.toSnakeCase('todo__list'), 'todo_list');
    });
  });

  group('StringUtils.toPascalCase', () {
    test('converts snake_case', () {
      expect(StringUtils.toPascalCase('todo_list'), 'TodoList');
    });

    test('converts a single word', () {
      expect(StringUtils.toPascalCase('payments'), 'Payments');
    });
  });

  group('StringUtils.toCamelCase', () {
    test('converts snake_case', () {
      expect(StringUtils.toCamelCase('todo_list'), 'todoList');
    });

    test('converts a single word', () {
      expect(StringUtils.toCamelCase('payments'), 'payments');
    });
  });
}
