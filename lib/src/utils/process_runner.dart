import 'dart:io';

/// Thrown when a shelled-out process (e.g. `flutter create`) fails or the
/// binary can't be found on PATH.
class ProcessFailedException implements Exception {
  ProcessFailedException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Runs an external command and streams its output, throwing on failure.
/// Extracted behind a function (rather than called inline) so tests can
/// stub it out without actually invoking `flutter`.
Future<void> runProcess(
  String executable,
  List<String> args, {
  String? workingDirectory,
}) async {
  final ProcessResult result;
  try {
    result = await Process.run(
      executable,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
  } on ProcessException catch (e) {
    throw ProcessFailedException(
      'Could not run "$executable": ${e.message}. '
      'Is it installed and on your PATH?',
    );
  }

  if (result.exitCode != 0) {
    throw ProcessFailedException(
      '"$executable ${args.join(' ')}" failed with exit code '
      '${result.exitCode}.\n${result.stdout}\n${result.stderr}',
    );
  }
}

Future<bool> isExecutableAvailable(String executable) async {
  try {
    final result = await Process.run(Platform.isWindows ? 'where' : 'which', [
      executable,
    ], runInShell: true);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}
