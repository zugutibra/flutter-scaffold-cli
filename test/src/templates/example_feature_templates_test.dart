import 'package:clean_flutter_cli/src/templates/example_feature_templates.dart';
import 'package:test/test.dart';

void main() {
  group('todoLocalDatasourceTemplate (hive)', () {
    test('masks the generated key into Hive\'s valid int range', () {
      // Regression test: Hive int keys must fit in 0..0xFFFFFFFF.
      // millisecondsSinceEpoch alone is a 13-digit number and overflows
      // that, which threw `HiveError: Integer keys need to be in the
      // range 0 - 0xFFFFFFFF` at runtime on a real device.
      final result = todoLocalDatasourceTemplate('demo_app', DbChoice.hive);
      expect(result, contains('& 0xFFFFFFFF'));
    });
  });
}
