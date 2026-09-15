/// Case-conversion helpers for turning a user-supplied name (any case style)
/// into the naming conventions used across generated files.
class StringUtils {
  const StringUtils._();

  /// `todo_list` -> `todo_list` (validates/normalizes to snake_case).
  static String toSnakeCase(String input) {
    final withUnderscores = input
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m[1]}_${m[2]}',
        )
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .toLowerCase();
    return withUnderscores.replaceAll(RegExp(r'_+'), '_');
  }

  /// `todo_list` -> `TodoList`
  static String toPascalCase(String input) {
    return toSnakeCase(input)
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join();
  }

  /// `todo_list` -> `todoList`
  static String toCamelCase(String input) {
    final pascal = toPascalCase(input);
    if (pascal.isEmpty) return pascal;
    return pascal[0].toLowerCase() + pascal.substring(1);
  }
}
