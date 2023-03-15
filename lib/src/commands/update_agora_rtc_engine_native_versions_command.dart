import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:file/file.dart';
import 'package:hoe/src/base/base_command.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';

class VersionLink {
  const VersionLink(this.cdn, this.mavenOrCocoaPods);
  final String cdn;
  final List<String> mavenOrCocoaPods;
}

class UpdateAgoraRtcEngineNativeVersionsCommand extends BaseCommand {
  UpdateAgoraRtcEngineNativeVersionsCommand({
    required FileSystem fileSystem,
    required ProcessManager processManager,
    required Logger logger,
  }) : super(fileSystem, processManager, logger) {
    argParser.addOption('native-sdk-version-content');
    argParser.addFlag('iris-version-content');
  }

  late final Directory _workspace;

  @override
  String get description => 'Update agora flutter sdks native dependencies';

  @override
  String get name => 'update-agora-flutter-native-dependencies';

  @override
  Future<void> run() async {
    final String nativeSdkVersionContent =
        argResults?['native-sdk-version-content'] ?? '';
    final String irisVersionContent = argResults?['iris-version-content'] ?? '';
    final String projectDir = argResults?['project-dir'] ?? '';

    _workspace = fileSystem.directory(projectDir);
    stdout.writeln(_workspace.absolute.path);

    final androidGradleFilePath =
        path.join(_workspace.absolute.path, 'android', 'build.gradle');
    final iosPodspecFilePath =
        path.join(_workspace.absolute.path, 'ios', 'agora_rtc_engine.podspec');
    final macosPodspecFilePath = path.join(
        _workspace.absolute.path, 'macos', 'agora_rtc_engine.podspec');
    final windowsCMakeFilePath =
        path.join(_workspace.absolute.path, 'windows', 'CMakeLists.txt');

    final androidGradleFile = fileSystem.file(androidGradleFilePath);
    androidGradleFile.writeAsStringSync(modifiedAndroidGradleContent(
      androidGradleFile.readAsLinesSync(),
      nativeSdkVersionContent,
      irisVersionContent,
    ));

    final iosPodspecFile = fileSystem.file(iosPodspecFilePath);
    iosPodspecFile.writeAsStringSync(modifiedIOSPodspecContent(
      iosPodspecFile.readAsLinesSync(),
      nativeSdkVersionContent,
      irisVersionContent,
    ));

    final macosPodspecFile = fileSystem.file(macosPodspecFilePath);
    macosPodspecFile.writeAsStringSync(modifiedMacOSPodspecContent(
      macosPodspecFile.readAsLinesSync(),
      nativeSdkVersionContent,
      irisVersionContent,
    ));

    final windowsCMakeFile = fileSystem.file(windowsCMakeFilePath);
    windowsCMakeFile.writeAsStringSync(modifiedWindowsCMakeContent(
      windowsCMakeFile.readAsLinesSync(),
      irisVersionContent,
    ));
  }

  VersionLink findNativeAndroidMaven(String nativeSdkVersionContent) {
    List<String> mavens = [];

    RegExp mavenFullRegExp = RegExp(
      r"^implementation 'io.agora.rtc:full-sdk:[0-9a-z\.-]+'",
      caseSensitive: true,
      multiLine: true,
    );
    if (mavenFullRegExp.hasMatch(nativeSdkVersionContent)) {
      mavens.add(mavenFullRegExp.stringMatch(nativeSdkVersionContent) ?? '');
    }

    RegExp mavenSpecialRegExp = RegExp(
      r"^implementation 'io.agora.rtc:agora-special-full:[0-9a-z\.-]+'",
      caseSensitive: true,
      multiLine: true,
    );
    if (mavenSpecialRegExp.hasMatch(nativeSdkVersionContent)) {
      mavens.add(mavenSpecialRegExp.stringMatch(nativeSdkVersionContent) ?? '');
    }

    RegExp mavenFullScreenSharingRegExp = RegExp(
      r"^implementation 'io.agora.rtc:full-screen-sharing:[0-9a-z\.-]+'",
      caseSensitive: true,
      multiLine: true,
    );
    if (mavenFullScreenSharingRegExp.hasMatch(nativeSdkVersionContent)) {
      mavens.add(
          mavenFullScreenSharingRegExp.stringMatch(nativeSdkVersionContent) ??
              '');
    }

    return VersionLink('', mavens);
  }

  VersionLink findNativeIOSPod(String nativeSdkVersionContent) {
    List<String> cocoapods = [];

    RegExp cocoapodsFullRegExp = RegExp(
      r"^pod 'AgoraRtcEngine_iOS', '[0-9a-z.-]+'$",
      caseSensitive: true,
      multiLine: true,
    );
    if (cocoapodsFullRegExp.hasMatch(nativeSdkVersionContent)) {
      cocoapods
          .add(cocoapodsFullRegExp.stringMatch(nativeSdkVersionContent) ?? '');
    }

    RegExp cocoapodsSpecialRegExp = RegExp(
      r"^pod 'AgoraRtcEngine_Special_iOS', '[0-9a-z.-]+'$",
      caseSensitive: true,
      multiLine: true,
    );
    if (cocoapodsSpecialRegExp.hasMatch(nativeSdkVersionContent)) {
      cocoapods.add(
          cocoapodsSpecialRegExp.stringMatch(nativeSdkVersionContent) ?? '');
    }

    return VersionLink('', cocoapods);
  }

  VersionLink findNativeMacosPod(String nativeSdkVersionContent) {
    List<String> cocoapods = [];

    RegExp cocoapodsFullRegExp = RegExp(
      r"^pod 'AgoraRtcEngine_macOS', '[0-9a-z.-]+'$",
      caseSensitive: true,
      multiLine: true,
    );
    if (cocoapodsFullRegExp.hasMatch(nativeSdkVersionContent)) {
      cocoapods
          .add(cocoapodsFullRegExp.stringMatch(nativeSdkVersionContent) ?? '');
    }

    RegExp cocoapodsSpecialRegExp = RegExp(
      r"^pod 'AgoraRtcEngine_Special_macOS', '[0-9a-z.-]+'$",
      caseSensitive: true,
      multiLine: true,
    );
    if (cocoapodsSpecialRegExp.hasMatch(nativeSdkVersionContent)) {
      cocoapods.add(
          cocoapodsSpecialRegExp.stringMatch(nativeSdkVersionContent) ?? '');
    }

    return VersionLink('', cocoapods);
  }

  VersionLink findNativeWindowsCDN(String nativeSdkVersionContent) {
    String cdn = '';
    RegExp cdnRegExp = RegExp(
      r'^https:\/\/download.agora.io\/sdk\/release\/Agora_Native_SDK_for_Windows_rel.v[0-9a-z\.-_]+_FULL_[0-9_]+\.zip$',
      caseSensitive: true,
      multiLine: true,
    );
    if (cdnRegExp.hasMatch(nativeSdkVersionContent)) {
      cdn = cdnRegExp.stringMatch(nativeSdkVersionContent) ?? '';
    }

    return VersionLink(cdn, []);
  }

  VersionLink findIrisAndroidMaven(String irisVersionContent) {
    String cdn = '';
    String maven = '';

    RegExp cdnRegExp = RegExp(
      r'^https:\/\/download\.agora\.io\/sdk\/release\/iris_[0-9a-z\.-]+_DCG_Android_Video_[0-9]+_[0-9]+\.zip$',
      caseSensitive: true,
      multiLine: true,
    );
    if (cdnRegExp.hasMatch(irisVersionContent)) {
      cdn = cdnRegExp.stringMatch(irisVersionContent) ?? '';
    }

    RegExp mavenRegExp = RegExp(
      r"^implementation 'io.agora.rtc:iris-rtc:[0-9a-z\.-]+'",
      caseSensitive: true,
      multiLine: true,
    );
    if (mavenRegExp.hasMatch(irisVersionContent)) {
      maven = mavenRegExp.stringMatch(irisVersionContent) ?? '';
    }

    return VersionLink(cdn, [maven]);
  }

  VersionLink findIrisIOSPod(String irisVersionContent) {
    String cdn = '';
    String cocoapods = '';

    RegExp cdnRegExp = RegExp(
      r'^https:\/\/download\.agora\.io\/sdk\/release\/iris_[0-9a-z\.-]+_DCG_iOS_Video_[0-9]+_[0-9]+\.zip$',
      caseSensitive: true,
      multiLine: true,
    );
    if (cdnRegExp.hasMatch(irisVersionContent)) {
      cdn = cdnRegExp.stringMatch(irisVersionContent) ?? '';
    }

    RegExp cocoapodsRegExp = RegExp(
      r"^pod \'AgoraIrisRTC_iOS\', \'[0-9a-z.-]+\'$",
      caseSensitive: true,
      multiLine: true,
    );
    if (cocoapodsRegExp.hasMatch(irisVersionContent)) {
      cocoapods = cocoapodsRegExp.stringMatch(irisVersionContent) ?? '';
    }

    return VersionLink(cdn, [cocoapods]);
  }

  VersionLink findIrisMacosPod(String irisVersionContent) {
    String cdn = '';
    String cocoapods = '';

    RegExp cdnRegExp = RegExp(
      r'^https:\/\/download\.agora\.io\/sdk\/release\/iris_[0-9a-z\.-]+_DCG_Mac_Video_[0-9]+_[0-9]+\.zip$',
      caseSensitive: true,
      multiLine: true,
    );
    if (cdnRegExp.hasMatch(irisVersionContent)) {
      cdn = cdnRegExp.stringMatch(irisVersionContent) ?? '';
    }

    RegExp cocoapodsRegExp = RegExp(
      r"^pod \'AgoraIrisRTC_macOS\', \'[0-9a-z.-]+\'$",
      caseSensitive: true,
      multiLine: true,
    );
    if (cocoapodsRegExp.hasMatch(irisVersionContent)) {
      cocoapods = cocoapodsRegExp.stringMatch(irisVersionContent) ?? '';
    }

    return VersionLink(cdn, [cocoapods]);
  }

  VersionLink findIrisWindowsCDN(String irisVersionContent) {
    String cdn = '';

    RegExp cdnRegExp = RegExp(
      r'^https:\/\/download\.agora\.io\/sdk\/release\/iris_[0-9a-z\.-]+_DCG_Windows_Video_[0-9]+_[0-9]+\.zip$',
      caseSensitive: true,
      multiLine: true,
    );
    if (cdnRegExp.hasMatch(irisVersionContent)) {
      cdn = cdnRegExp.stringMatch(irisVersionContent) ?? '';
    }

    return VersionLink(cdn, []);
  }

  String modifiedAndroidGradleContent(
    List<String> sourceFileContentLines,
    String nativeSdkVersionContent,
    String irisVersionContent,
  ) {
    final tab = '    ';

    return _modifiedVersFileContent(
      sourceFileContentLines,
      () => findIrisAndroidMaven(irisVersionContent),
      () => findNativeAndroidMaven(nativeSdkVersionContent),
      r"^[\s]*(implementation|api) 'io.agora.rtc:[a-z-]+:[0-9a-zA-Z\.-]+'",
      (sourceLine) => '$tab${sourceLine.replaceFirst('implementation', 'api')}',
    );
  }

  String modifiedIOSPodspecContent(
    List<String> sourceFileContentLines,
    String nativeSdkVersionContent,
    String irisVersionContent,
  ) {
    final regExp = r"^[\s]*s.dependency 'Agora[a-zA-Z-_]+', '[0-9a-zA-Z\.-]+'";
    return _modifiedVersFileContent(
      sourceFileContentLines,
      () => findNativeIOSPod(nativeSdkVersionContent),
      () => findIrisIOSPod(irisVersionContent),
      regExp,
      (e) {
        return '  ${e.replaceFirst('pod', 's.dependency')}';
      },
    );
  }

  String modifiedMacOSPodspecContent(
    List<String> sourceFileContentLines,
    String nativeSdkVersionContent,
    String irisVersionContent,
  ) {
    final regExp = r"^[\s]*s.dependency 'Agora[a-zA-Z-_]+', '[0-9a-zA-Z\.-]+'";
    return _modifiedVersFileContent(
      sourceFileContentLines,
      () => findNativeMacosPod(nativeSdkVersionContent),
      () => findIrisMacosPod(irisVersionContent),
      regExp,
      (e) {
        return '  ${e.replaceFirst('pod', 's.dependency')}';
      },
    );
  }

  String modifiedWindowsCMakeContent(
    List<String> sourceFileContentLines,
    String irisVersionContent,
  ) {
    List<String> modifiedFileContentLines = [];

    final downloadUrlCMakeRegExp = RegExp(
      r'^[\s]*set\(IRIS_SDK_DOWNLOAD_URL "[\S]*"\)',
      multiLine: true,
      caseSensitive: true,
    );

    final downloadNameCMakeRegExp = RegExp(
      r'^[\s]*set\(IRIS_SDK_DOWNLOAD_NAME "[\S]*"\)',
      multiLine: true,
      caseSensitive: true,
    );

    final downloadNameFromCDNRegExp = RegExp(
      r'iris_[a-zA-Z0-9\.\-_]+_DCG_Windows',
      multiLine: true,
      caseSensitive: true,
    );

    final cdn = findIrisWindowsCDN(irisVersionContent).cdn;

    String downloadNameFromCDN = '';
    if (downloadNameFromCDNRegExp.hasMatch(cdn)) {
      downloadNameFromCDN = downloadNameFromCDNRegExp.stringMatch(cdn) ?? '';
    }

    for (final line in sourceFileContentLines) {
      if (downloadUrlCMakeRegExp.hasMatch(line)) {
        modifiedFileContentLines.add('set(IRIS_SDK_DOWNLOAD_URL "$cdn")');
        continue;
      }

      if (downloadNameCMakeRegExp.hasMatch(line)) {
        modifiedFileContentLines
            .add('set(IRIS_SDK_DOWNLOAD_NAME "$downloadNameFromCDN")');
        continue;
      }

      modifiedFileContentLines.add(line);
    }

    return modifiedFileContentLines.join('\n');
  }

  String _modifiedVersFileContent(
    List<String> sourceFileContentLines,
    VersionLink Function() findNativeVersionLink,
    VersionLink Function() findIrisVersionLink,
    String regExp,
    String Function(String sourceLine) lineMapped,
  ) {
    List<String> modifiedFileContentLines = [];

    RegExp mavenRegExp = RegExp(
      regExp,
      caseSensitive: true,
      multiLine: true,
    );

    bool isAddedVersions = false;
    for (final line in sourceFileContentLines) {
      if (mavenRegExp.hasMatch(line)) {
        if (!isAddedVersions) {
          VersionLink irisVersionLink = findIrisVersionLink();
          VersionLink nativeVersionLink = findNativeVersionLink();

          final mavenOrCocoaPods = irisVersionLink.mavenOrCocoaPods
              .map((e) => lineMapped(e))
              .toList();
          mavenOrCocoaPods.addAll(
              nativeVersionLink.mavenOrCocoaPods.map((e) => lineMapped(e)));

          modifiedFileContentLines.addAll(mavenOrCocoaPods);

          isAddedVersions = true;
        }

        continue;
      }

      modifiedFileContentLines.add(line);
    }

    return modifiedFileContentLines.join('\n');
  }
}
