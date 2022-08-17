import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:file/file.dart';
import 'package:process/process.dart';
import 'package:meta/meta.dart';

abstract class BaseCommand extends Command {
  BaseCommand(
    this.fileSystem,
    this.processManager,
    this.logger,
  );

  @protected
  final FileSystem fileSystem;

  @protected
  final ProcessManager processManager;

  @protected
  final Logger logger;
}

/// Throw a specialized exception for expected situations
/// where the tool should exit with a clear message to the user
/// and no stack trace unless the --verbose option is specified.
/// For example: network errors.
Never throwToolExit(String message, {int? exitCode}) {
  throw ToolExit(message, exitCode: exitCode);
}

/// Specialized exception for expected situations
/// where the tool should exit with a clear message to the user
/// and no stack trace unless the --verbose option is specified.
/// For example: network errors.
class ToolExit implements Exception {
  ToolExit(this.message, {this.exitCode});

  final String? message;
  final int? exitCode;

  @override
  String toString() => 'Exception: $message';
}
