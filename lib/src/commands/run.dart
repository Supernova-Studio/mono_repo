import 'dart:async';
import 'dart:io';

import 'package:io/ansi.dart';
import 'package:mono_repo/src/commands/mono_repo_command.dart';
import 'package:mono_repo/src/root_config.dart';
import 'package:path/path.dart' as p;

class RunCommand extends MonoRepoCommand {
  @override
  String get name => 'run';

  @override
  String get description => 'Runs provided command in each module';

  @override
  FutureOr<void> run() {
    print('Got arguments: ${argResults.arguments.join('|||')}');

    if (argResults.arguments.isEmpty) {
      print(red.wrap('No executable command has been provided.'));
      return null;
    }

    return _run(argResults.arguments[0], argResults.arguments.sublist(1), rootConfig());
  }
}

Future<void> _run(String executable, List<String> args, RootConfig rootConfig) async {
  final pkgDirs = rootConfig.map((pc) => pc.relativePath).toList();

  print(lightBlue.wrap('Running `$executable ${args.join(' ')}` across ${pkgDirs.length} package(s).'));

  for (var config in rootConfig) {
    final dir = config.relativePath;

    print('');
    print(wrapWith('Starting `$executable ${args.join(' ')}` in `$dir`...', [styleBold, lightBlue]));
    final workingDir = p.join(rootConfig.rootDirectory, dir);

    final proc = await Process.start(
      executable,
      args,
      mode: ProcessStartMode.inheritStdio,
      workingDirectory: workingDir,
      runInShell: Platform.isWindows,
    );

    final exit = await proc.exitCode;

    if (exit == 0) {
      print(wrapWith('`$dir`: success!', [styleBold, green]));
    } else {
      print(wrapWith('`$dir`: failed!', [styleBold, red]));
    }

    if (exitCode == 0) {
      exitCode = exit;
    }
  }
}
