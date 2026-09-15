import 'package:clean_flutter_cli/src/templates/core_templates.dart';
import 'package:test/test.dart';

void main() {
  group('core templates', () {
    test('failuresTemplate defines Failure, ServerFailure, CacheFailure', () {
      expect(
        failuresTemplate,
        contains('abstract class Failure extends Equatable'),
      );
      expect(failuresTemplate, contains('class ServerFailure extends Failure'));
      expect(failuresTemplate, contains('class CacheFailure extends Failure'));
    });

    test(
      'exceptionsTemplate defines matching exception types with a message field',
      () {
        expect(
          exceptionsTemplate,
          contains('class ServerException implements Exception'),
        );
        expect(
          exceptionsTemplate,
          contains('class CacheException implements Exception'),
        );
        // regression check: CacheException must declare its own `message` field
        // (previously it only had the initializing formal, which failed to compile).
        final cacheExceptionBlock = exceptionsTemplate
            .split('class CacheException')
            .last;
        expect(cacheExceptionBlock, contains('final String message;'));
      },
    );

    test('usecaseTemplate interpolates the package name', () {
      final result = usecaseTemplate.replaceAll('{{package_name}}', 'demo_app');
      expect(result, contains("package:demo_app/core/errors/failures.dart"));
      expect(result, isNot(contains('{{package_name}}')));
    });

    test('injectionContainerTemplate embeds imports and registrations', () {
      final result = injectionContainerTemplate(
        packageName: 'demo_app',
        featureImports: ["import 'package:demo_app/foo.dart';\n"],
        featureRegistrations: ['  sl.registerLazySingleton(() => Foo());'],
      );
      expect(result, contains("import 'package:demo_app/foo.dart';"));
      expect(result, contains('sl.registerLazySingleton(() => Foo());'));
      expect(result, contains('Future<void> initDependencies() async {'));
    });
  });
}
