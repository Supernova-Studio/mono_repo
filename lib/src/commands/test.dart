import 'dart:async';
import 'dart:io';

import 'package:io/ansi.dart';
import 'package:mono_repo/src/commands/mono_repo_command.dart';
import 'package:mono_repo/src/root_config.dart';
import 'package:path/path.dart' as p;

class TestCommand extends MonoRepoCommand {
  @override
  String get name => 'run_tests';

  @override
  String get description => 'Runs provided command in each module';

  @override
  FutureOr<void> run() {
    return test(rootConfig());
  }
}

Future<void> test(RootConfig rootConfig) async {
  final pkgDirs = rootConfig.map((pc) => pc.relativePath).toList();

  print(lightBlue.wrap('Running `test` across ${pkgDirs.length} package(s).'));

  for (var config in rootConfig) {

    final dir = config.relativePath;

    if (!config.hasFlutterDependency) {
      print(wrapWith('Skipping `$dir`, not a Flutter module', [styleBold, lightBlue]));
      continue;
    }

    print('Relative path: $dir');
    print('Current: ${p.current}');
    final testDirectory = Directory.fromUri(Uri.file(p.join(p.current, dir, 'test')));
    if (!testDirectory.existsSync()) {
      print(wrapWith('Skipping `$dir`, missing `test` directory.', [styleBold, lightBlue]));
      continue;
    }

    if (!config.pubspec.devDependencies.containsKey('flutter_test')) {
      print(wrapWith('Skipping `$dir`, missing `flutter_test` dependency in pubspec.yaml.', [styleBold, lightBlue]));
      continue;
    }

    final executable = 'flutter';
    final args = ['test'];

    print('');
    print(wrapWith('Starting `$executable ${args.join(' ')}` in `$dir`...', [styleBold, lightBlue]));
    final workingDir = p.join(rootConfig.rootDirectory, dir);

    final proc = await Process.start(executable, args, mode: ProcessStartMode.inheritStdio, workingDirectory: workingDir);

    final exit = await proc.exitCode;

    if (exit == 0) {
      print(wrapWith('`$dir`: success!', [styleBold, green]));
    } else {
      print(wrapWith('`$dir`: failed!', [styleBold, red]));
      if (exitCode == 0) {
        exitCode = exit;
      }
    }
  }
}
