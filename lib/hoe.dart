import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:file/file.dart';
import 'package:hoe/src/commands/build_agora_rtc_engine_example_command.dart';
import 'package:process/process.dart';

final String commnadName = 'hoe';

Future<dynamic> run(
  List<String> args, {
  required FileSystem fileSystem,
  required ProcessManager processManager,
  required Logger logger,
}) {
  final runner = CommandRunner(commnadName,
      '$commnadName is a CLI tool.')
    ..addCommand(BuildAgoraRtcEngineExampleCommand(
        fileSystem: fileSystem,
        processManager: processManager,
        logger: logger));
  return runner.run(args);
}
