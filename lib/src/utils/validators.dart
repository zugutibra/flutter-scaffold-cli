final RegExp _validDartIdentifier = RegExp(r'^[a-z][a-z0-9_]*$');

/// Mirrors the rule `flutter create` / `dart create` enforce: a valid Dart
/// package name is lowercase_with_underscores and not a reserved word.
class NameValidationException implements Exception {
  NameValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

void validatePackageName(String name, {required String kind}) {
  if (name.isEmpty) {
    throw NameValidationException('$kind name must not be empty.');
  }
  if (!_validDartIdentifier.hasMatch(name)) {
    throw NameValidationException(
      '$kind name "$name" is invalid. Use lowercase_with_underscores '
      '(must start with a letter, contain only a-z, 0-9 and _).',
    );
  }
  const reserved = {
    'assert',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'default',
    'do',
    'else',
    'enum',
    'extends',
    'false',
    'final',
    'finally',
    'for',
    'if',
    'in',
    'is',
    'new',
    'null',
    'rethrow',
    'return',
    'super',
    'switch',
    'this',
    'throw',
    'true',
    'try',
    'var',
    'void',
    'while',
    'with',
  };
  if (reserved.contains(name)) {
    throw NameValidationException(
      '$kind name "$name" is a reserved Dart keyword.',
    );
  }
}
