import 'dart:convert';
import 'dart:io';

import 'package:hoe/src/base/base_command.dart';
import 'package:process/process.dart';

extension ProcessManagerExt on ProcessManager {
  void runSyncWithOutput(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) {
    final result = runSync(
      command,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );

    if (result.exitCode != 0) {
      stderr.writeln(result.stderr);
      throwToolExit(result.stderr ?? '', exitCode: result.exitCode);
    }

    stdout.writeln(result.stdout);
  }

  Future<void> startWithOutput(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    return start(
      command,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      mode: mode,
    ).then((Process process) {
      process.stdout.listen((data) => stdout.writeln(data));
      process.stderr.listen((data) => stderr.writeln(data));
    });
  }
}
