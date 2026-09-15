/// Templates for `clean_flutter generate feature <name>` — empty-but-
/// structured boilerplate for a new feature slice in an existing project.
/// Not wired into DI automatically (plan section 5); the command prints a
/// manual-registration checklist instead.
library;

import '../utils/string_utils.dart';

String featureRepositoryTemplate(String packageName, String featureName) {
  final pascal = StringUtils.toPascalCase(featureName);
  return '''
import 'package:fpdart/fpdart.dart';

import 'package:$packageName/core/errors/failures.dart';

abstract class ${pascal}Repository {
  // TODO: define the contract for the "$featureName" feature.
}
''';
}

String featureRepositoryImplTemplate(String packageName, String featureName) {
  final pascal = StringUtils.toPascalCase(featureName);
  return '''
import 'package:$packageName/features/$featureName/domain/repositories/${featureName}_repository.dart';

class ${pascal}RepositoryImpl implements ${pascal}Repository {
  // TODO: inject data source(s) and implement ${pascal}Repository.
}
''';
}

String featureEventTemplate(String packageName, String featureName) {
  final pascal = StringUtils.toPascalCase(featureName);
  return '''
import 'package:equatable/equatable.dart';

abstract class ${pascal}Event extends Equatable {
  const ${pascal}Event();

  @override
  List<Object?> get props => [];
}

// TODO: add events, e.g. class Load$pascal extends ${pascal}Event {}
''';
}

String featureStateTemplate(String packageName, String featureName) {
  final pascal = StringUtils.toPascalCase(featureName);
  return '''
import 'package:equatable/equatable.dart';

abstract class ${pascal}State extends Equatable {
  const ${pascal}State();

  @override
  List<Object?> get props => [];
}

class ${pascal}Initial extends ${pascal}State {
  const ${pascal}Initial();
}

// TODO: add loading/loaded/error states as needed.
''';
}

String featureBlocTemplate(String packageName, String featureName) {
  final pascal = StringUtils.toPascalCase(featureName);
  return '''
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:$packageName/features/$featureName/presentation/bloc/${featureName}_event.dart';
import 'package:$packageName/features/$featureName/presentation/bloc/${featureName}_state.dart';

class ${pascal}Bloc extends Bloc<${pascal}Event, ${pascal}State> {
  ${pascal}Bloc() : super(const ${pascal}Initial()) {
    // TODO: register event handlers with `on<Event>(...)`.
  }
}
''';
}
