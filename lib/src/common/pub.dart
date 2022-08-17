import 'package:cli_util/cli_logging.dart';
import 'package:process/process.dart';

class FlutterTool {
  FlutterTool(this.workingDirectory, this.processManager, this.logger,
      {this.exitIfFail = false});
  final String workingDirectory;
  final ProcessManager processManager;
  final Logger logger;
  final bool exitIfFail;
  void get() {
    logger.stdout('Run pub get in $workingDirectory');
    _runCommand(['flutter', 'pub', 'get']);
  }

  void runBuildRunner() {
    logger.stdout('Run pub build_runner in $workingDirectory');
    _runCommand([
      'flutter',
      'pub',
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs'
    ]);
  }

  void _runCommand(List<Object> command) {
    final result = processManager.runSync(command,
        workingDirectory: workingDirectory, runInShell: true);
    logger.stdout(result.stdout);
    if (result.exitCode != 0) {
      logger.stderr(result.stderr);
    }
  }
}
