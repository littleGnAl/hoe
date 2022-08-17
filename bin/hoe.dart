import 'package:hoe/hoe.dart' as executable;
import 'package:cli_util/cli_logging.dart';
import 'package:file/local.dart';
import 'package:process/process.dart';

void main(List<String> args) {
  final fileSystem = const LocalFileSystem();
  final processManager = const LocalProcessManager();

  final verbose = args.contains('-v');
  final logger = verbose ? Logger.verbose() : Logger.standard();

  executable.run(
    args,
    fileSystem: fileSystem,
    processManager: processManager,
    logger: logger,
  );
}
