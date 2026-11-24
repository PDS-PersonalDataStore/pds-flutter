import 'dart:io';

/// Script to generate Pigeon bindings and optionally verify code generation drift.
///
/// Usage:
///   dart run tool/generate_pigeon.dart          # Generates code
///   dart run tool/generate_pigeon.dart --check  # Verifies no diff / drift
void main(List<String> args) async {
  final checkOnly = args.contains('--check');

  stdout.writeln('Running Pigeon code generator...');
  final pigeonProcess = await Process.run(
    'flutter',
    ['pub', 'run', 'pigeon', '--input', 'pigeons/pds_api.dart'],
    runInShell: true,
  );

  stdout.write(pigeonProcess.stdout);
  stderr.write(pigeonProcess.stderr);

  if (pigeonProcess.exitCode != 0) {
    stderr.writeln('Pigeon generator failed with exit code ${pigeonProcess.exitCode}');
    exit(pigeonProcess.exitCode);
  }

  stdout.writeln('Pigeon code generation completed.');

  if (checkOnly) {
    stdout.writeln('Checking for code generation drift...');
    final gitDiff = await Process.run(
      'git',
      [
        'status',
        '--porcelain',
        'lib/src/pds_api.g.dart',
        'android/src/main/kotlin/top/tau2c/pds/flutter/pds_flutter/PdsApi.g.kt',
      ],
      runInShell: true,
    );

    final diffOutput = (gitDiff.stdout as String).trim();
    if (diffOutput.isNotEmpty) {
      stderr.writeln(
        'ERROR: Pigeon generated code has drift! Commit the updated generated files.',
      );
      stderr.writeln(diffOutput);
      exit(1);
    }
    stdout.writeln('Pigeon generated files are in sync.');
  }
}
