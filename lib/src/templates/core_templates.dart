/// Templates for `lib/core/**` — the framework-agnostic building blocks
/// every feature slice depends on. These are static (no per-project
/// interpolation needed) except for [injectionContainerTemplate], which
/// wires in the example feature's dependencies.
library;

const String failuresTemplate = '''
import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures. Repositories return
/// `Either<Failure, T>` instead of throwing so callers must handle errors
/// explicitly.
abstract class Failure extends Equatable {
  const Failure([this.message = 'Something went wrong']);

  final String message;

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}
''';

const String exceptionsTemplate = '''
/// Thrown by data sources; caught by repository implementations and
/// converted into a [Failure] before crossing into the domain layer.
class ServerException implements Exception {
  const ServerException([this.message = 'Server error']);
  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Cache error']);
  final String message;
}
''';

const String usecaseTemplate = '''
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:{{package_name}}/core/errors/failures.dart';

/// Base contract every use case implements: given [Params], produce a
/// `Type` or a [Failure].
abstract class UseCase<ReturnType, Params> {
  Future<Either<Failure, ReturnType>> call(Params params);
}

/// Marker type for use cases that take no parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object> get props => [];
}
''';

const String inputConverterTemplate = '''
import 'package:fpdart/fpdart.dart';

import 'package:{{package_name}}/core/errors/failures.dart';

/// Example shared utility: parses a string into a non-negative integer,
/// returning a [Failure] instead of throwing on bad input.
class InputConverter {
  Either<Failure, int> stringToUnsignedInteger(String input) {
    try {
      final value = int.parse(input);
      if (value < 0) throw const FormatException();
      return Right(value);
    } on FormatException {
      return const Left(InvalidInputFailure());
    }
  }
}

class InvalidInputFailure extends Failure {
  const InvalidInputFailure() : super('Invalid input: must be a non-negative integer');
}
''';

/// [featureRegistrations] is a list of DI-registration source snippets
/// contributed by each generated feature (starts with just the example
/// Todo feature).
String injectionContainerTemplate({
  required String packageName,
  required List<String> featureImports,
  required List<String> featureRegistrations,
}) {
  final imports = featureImports.join();
  final registrations = featureRegistrations.join('\n\n');
  return '''
import 'package:get_it/get_it.dart';

$imports
final GetIt sl = GetIt.instance;

/// Registers every dependency in the app. Called once from `main()` before
/// `runApp`. Each feature contributes its own registration block below;
/// `clean_flutter generate feature` appends new ones here automatically
/// when possible, otherwise prints instructions to add them manually.
Future<void> initDependencies() async {
$registrations
}
''';
}
