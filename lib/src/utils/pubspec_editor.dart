import 'dart:io';

/// Minimal `pubspec.yaml` editing without pulling in a YAML-editing
/// dependency: `flutter create` always emits a `dependencies:` block as the
/// first top-level key after `environment:`, so we insert new entries right
/// after that line. Good enough for generator-authored pubspecs; not a
/// general-purpose YAML editor.
class PubspecEditor {
  PubspecEditor(this.path);

  final String path;

  /// Adds `name: constraint` entries under `dependencies:`. No-ops for a
  /// package already present.
  void addDependencies(Map<String, String> deps) {
    final file = File(path);
    var content = file.readAsStringSync();
    final lines = content.split('\n');
    final depsIndex = lines.indexWhere((l) => l.trim() == 'dependencies:');
    if (depsIndex == -1) {
      throw StateError('Could not find "dependencies:" in $path');
    }

    final toAdd = deps.entries
        .where((e) => !content.contains('\n  ${e.key}:'))
        .map((e) => '  ${e.key}: ${e.value}')
        .toList();
    if (toAdd.isEmpty) return;

    lines.insertAll(depsIndex + 1, toAdd);
    content = lines.join('\n');
    file.writeAsStringSync(content);
  }

  /// Detects the flag a generated project was configured with by checking
  /// which known dependency is present (used by `generate feature`).
  static String? detectDbChoice(String pubspecContent) {
    if (pubspecContent.contains('\n  isar:')) return 'isar';
    if (pubspecContent.contains('\n  hive:')) return 'hive';
    return 'none';
  }
}
