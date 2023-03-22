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

extension VersionLinkExt on VersionLink {
  bool noVersionLink() {
    return cdn.isEmpty && mavenOrCocoaPods.every((element) => element.isEmpty);
  }
}

extension StringRegExpListExt on List<String> {
  bool hasMatch(String content) {
    bool isMatch = false;
    for (final r in this) {
      RegExp theRegExp = RegExp(
        r,
        caseSensitive: true,
        multiLine: true,
      );

      isMatch |= theRegExp.hasMatch(content);
    }

    return isMatch;
  }
}

class UpdateAgoraRtcEngineNativeVersionsCommand extends BaseCommand {
  UpdateAgoraRtcEngineNativeVersionsCommand({
    required FileSystem fileSystem,
    required ProcessManager processManager,
    required Logger logger,
  }) : super(fileSystem, processManager, logger) {
    argParser.addOption('project-dir');
    argParser.addOption('native-sdk-dependencies-content');
    argParser.addOption('iris-dependencies-content');
  }

  late final Directory _workspace;

  @override
  String get description => 'Update agora flutter sdks native dependencies';

  @override
  String get name => 'update-agora-flutter-native-dependencies';

  @override
  Future<void> run() async {
    final String projectDir = argResults?['project-dir'] ?? '';
    final String nativeSdkDependenciesContent =
        argResults?['native-sdk-dependencies-content'] ?? '';
    final String irisDenpendenciesContent =
        argResults?['iris-dependencies-content'] ?? '';

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
      nativeSdkDependenciesContent,
      irisDenpendenciesContent,
    ));

    final iosPodspecFile = fileSystem.file(iosPodspecFilePath);
    iosPodspecFile.writeAsStringSync(modifiedIOSPodspecContent(
      iosPodspecFile.readAsLinesSync(),
      nativeSdkDependenciesContent,
      irisDenpendenciesContent,
    ));

    final macosPodspecFile = fileSystem.file(macosPodspecFilePath);
    macosPodspecFile.writeAsStringSync(modifiedMacOSPodspecContent(
      macosPodspecFile.readAsLinesSync(),
      nativeSdkDependenciesContent,
      irisDenpendenciesContent,
    ));

    final windowsCMakeFile = fileSystem.file(windowsCMakeFilePath);
    windowsCMakeFile.writeAsStringSync(modifiedWindowsCMakeContent(
      windowsCMakeFile.readAsLinesSync(),
      irisDenpendenciesContent,
    ));
  }

  VersionLink findNativeAndroidMaven(String nativeSdkDependenciesContent) {
    List<String> mavens = [];

    RegExp mavenFullRegExp = RegExp(
      r"implementation[\s]*'io.agora.rtc:full-sdk:[0-9a-z\.-]+'",
      caseSensitive: true,
      multiLine: true,
    );
    if (mavenFullRegExp.hasMatch(nativeSdkDependenciesContent)) {
      mavens
          .add(mavenFullRegExp.stringMatch(nativeSdkDependenciesContent) ?? '');
    }

    RegExp mavenSpecialRegExp = RegExp(
      r"implementation[\s]*'io.agora.rtc:agora-special-full:[0-9a-z\.-]+'",
      caseSensitive: true,
      multiLine: true,
    );
    if (mavenSpecialRegExp.hasMatch(nativeSdkDependenciesContent)) {
      mavens.add(
          mavenSpecialRegExp.stringMatch(nativeSdkDependenciesContent) ?? '');
    }

    RegExp mavenFullScreenSharingRegExp = RegExp(
      r"implementation[\s]*'io.agora.rtc:full-screen-sharing:[0-9a-z\.-]+'",
      caseSensitive: true,
      multiLine: true,
    );
    if (mavenFullScreenSharingRegExp.hasMatch(nativeSdkDependenciesContent)) {
      mavens.add(mavenFullScreenSharingRegExp
              .stringMatch(nativeSdkDependenciesContent) ??
          '');
    }

    return VersionLink('', mavens);
  }

  VersionLink findNativeIOSPod(String nativeSdkDependenciesContent) {
    List<String> cocoapods = [];

    RegExp cocoapodsFullRegExp = RegExp(
      r"pod[\s]*'AgoraRtcEngine_iOS',[\s]*'[0-9a-z.-]+'",
      caseSensitive: true,
      multiLine: true,
    );
    if (cocoapodsFullRegExp.hasMatch(nativeSdkDependenciesContent)) {
      cocoapods.add(
          cocoapodsFullRegExp.stringMatch(nativeSdkDependenciesContent) ?? '');
    }

    RegExp cocoapodsSpecialRegExp = RegExp(
      r"pod[\s]*'AgoraRtcEngine_Special_iOS',[\s]*'[0-9a-z.-]+'",
      caseSensitive: true,
      multiLine: true,
    );
    if (cocoapodsSpecialRegExp.hasMatch(nativeSdkDependenciesContent)) {
      cocoapods.add(
          cocoapodsSpecialRegExp.stringMatch(nativeSdkDependenciesContent) ??
              '');
    }

    return VersionLink('', cocoapods);
  }

  VersionLink findNativeMacosPod(String nativeSdkDependenciesContent) {
    List<String> cocoapods = [];

    RegExp cocoapodsFullRegExp = RegExp(
      r"pod[\s]*'AgoraRtcEngine_macOS',[\s]*'[0-9a-z.-]+'",
      caseSensitive: true,
      multiLine: true,
    );
    if (cocoapodsFullRegExp.hasMatch(nativeSdkDependenciesContent)) {
      cocoapods.add(
          cocoapodsFullRegExp.stringMatch(nativeSdkDependenciesContent) ?? '');
    }

    RegExp cocoapodsSpecialRegExp = RegExp(
      r"pod[\s]*'AgoraRtcEngine_Special_macOS',[\s]*'[0-9a-z.-]+'",
      caseSensitive: true,
      multiLine: true,
    );
    if (cocoapodsSpecialRegExp.hasMatch(nativeSdkDependenciesContent)) {
      cocoapods.add(
          cocoapodsSpecialRegExp.stringMatch(nativeSdkDependenciesContent) ??
              '');
    }

    return VersionLink('', cocoapods);
  }

  VersionLink findNativeWindowsCDN(String nativeSdkDependenciesContent) {
    String cdn = '';
    RegExp cdnRegExp = RegExp(
      r'https:\/\/download.agora.io\/sdk\/release\/Agora_Native_SDK_for_Windows_rel.v[0-9a-z\.-_]+_FULL_[0-9_]+\.zip',
      caseSensitive: true,
      multiLine: true,
    );
    if (cdnRegExp.hasMatch(nativeSdkDependenciesContent)) {
      cdn = cdnRegExp.stringMatch(nativeSdkDependenciesContent) ?? '';
    }

    return VersionLink(cdn, []);
  }

  VersionLink findIrisAndroidMaven(String irisDenpendenciesContent) {
    String cdn = '';
    String maven = '';

    RegExp cdnRegExp = RegExp(
      r'https:\/\/download\.agora\.io\/sdk\/release\/iris_[0-9a-z\.-]+_DCG_Android_Video_[0-9]+_[0-9]+\.zip',
      caseSensitive: true,
      multiLine: true,
    );
    if (cdnRegExp.hasMatch(irisDenpendenciesContent)) {
      cdn = cdnRegExp.stringMatch(irisDenpendenciesContent) ?? '';
    }

    RegExp mavenRegExp = RegExp(
      r"implementation 'io.agora.rtc:iris-rtc:[0-9a-z\.-]+'",
      caseSensitive: true,
      multiLine: true,
    );
    if (mavenRegExp.hasMatch(irisDenpendenciesContent)) {
      maven = mavenRegExp.stringMatch(irisDenpendenciesContent) ?? '';
    }

    return VersionLink(cdn, [maven]);
  }

  VersionLink findIrisIOSPod(String irisDenpendenciesContent) {
    String cdn = '';
    String cocoapods = '';

    RegExp cdnRegExp = RegExp(
      r'https:\/\/download\.agora\.io\/sdk\/release\/iris_[0-9a-z\.-]+_DCG_iOS_Video_[0-9]+_[0-9]+\.zip',
      caseSensitive: true,
      multiLine: true,
    );
    if (cdnRegExp.hasMatch(irisDenpendenciesContent)) {
      cdn = cdnRegExp.stringMatch(irisDenpendenciesContent) ?? '';
    }

    RegExp cocoapodsRegExp = RegExp(
      r"pod[\s]*'AgoraIrisRTC_iOS',[\s]*'[0-9a-z.-]+'",
      caseSensitive: true,
      multiLine: true,
    );
    if (cocoapodsRegExp.hasMatch(irisDenpendenciesContent)) {
      cocoapods = cocoapodsRegExp.stringMatch(irisDenpendenciesContent) ?? '';
    }

    return VersionLink(cdn, [cocoapods]);
  }

  VersionLink findIrisMacosPod(String irisDenpendenciesContent) {
    String cdn = '';
    String cocoapods = '';

    RegExp cdnRegExp = RegExp(
      r'https:\/\/download\.agora\.io\/sdk\/release\/iris_[0-9a-z\.-]+_DCG_Mac_Video_[0-9]+_[0-9]+\.zip$',
      caseSensitive: true,
      multiLine: true,
    );
    if (cdnRegExp.hasMatch(irisDenpendenciesContent)) {
      cdn = cdnRegExp.stringMatch(irisDenpendenciesContent) ?? '';
    }

    RegExp cocoapodsRegExp = RegExp(
      r"pod[\s]*'AgoraIrisRTC_macOS',[\s]*'[0-9a-z.-]+'",
      caseSensitive: true,
      multiLine: true,
    );
    if (cocoapodsRegExp.hasMatch(irisDenpendenciesContent)) {
      cocoapods = cocoapodsRegExp.stringMatch(irisDenpendenciesContent) ?? '';
    }

    return VersionLink(cdn, [cocoapods]);
  }

  VersionLink findIrisWindowsCDN(String irisDenpendenciesContent) {
    String cdn = '';

    RegExp cdnRegExp = RegExp(
      r'https:\/\/download\.agora\.io\/sdk\/release\/iris_[0-9a-z\.-]+_DCG_Windows_Video_[0-9]+_[0-9]+\.zip',
      caseSensitive: true,
      multiLine: true,
    );
    if (cdnRegExp.hasMatch(irisDenpendenciesContent)) {
      cdn = cdnRegExp.stringMatch(irisDenpendenciesContent) ?? '';
    }

    return VersionLink(cdn, []);
  }

  String modifiedAndroidGradleContent(
    List<String> sourceFileContentLines,
    String nativeSdkDependenciesContent,
    String irisDenpendenciesContent,
  ) {
    final tab = '    ';

    return _modifiedVersFileContent(
      sourceFileContentLines,
      () => findNativeAndroidMaven(nativeSdkDependenciesContent),
      () => findIrisAndroidMaven(irisDenpendenciesContent),
      [
        r"^[\s]*(implementation|api) 'io.agora.rtc:agora[a-z-]+:[0-9a-zA-Z\.-]+'",
        r"^[\s]*(implementation|api) 'io.agora.rtc:full-[a-z-]+:[0-9a-zA-Z\.-]+'"
      ],
      [
        r"^[\s]*(implementation|api) 'io.agora.rtc:iris[a-z-]+:[0-9a-zA-Z\.-]+'"
      ],
      (sourceLine) => '$tab${sourceLine.replaceFirst('implementation', 'api')}',
    );
  }

  String modifiedIOSPodspecContent(
    List<String> sourceFileContentLines,
    String nativeSdkDependenciesContent,
    String irisDenpendenciesContent,
  ) {
    return _modifiedVersFileContent(
      sourceFileContentLines,
      () => findNativeIOSPod(nativeSdkDependenciesContent),
      () => findIrisIOSPod(irisDenpendenciesContent),
      [r"^[\s]*s.dependency 'AgoraRtc[a-zA-Z-_]+', '[0-9a-zA-Z\.-]+'"],
      [r"^[\s]*s.dependency 'AgoraIris[a-zA-Z-_]+', '[0-9a-zA-Z\.-]+'"],
      (e) {
        return '  ${e.replaceFirst('pod', 's.dependency')}';
      },
    );
  }

  String modifiedMacOSPodspecContent(
    List<String> sourceFileContentLines,
    String nativeSdkDependenciesContent,
    String irisDenpendenciesContent,
  ) {
    return _modifiedVersFileContent(
      sourceFileContentLines,
      () => findNativeMacosPod(nativeSdkDependenciesContent),
      () => findIrisMacosPod(irisDenpendenciesContent),
      [r"^[\s]*s.dependency 'AgoraRtc[a-zA-Z-_]+', '[0-9a-zA-Z\.-]+'"],
      [r"^[\s]*s.dependency 'AgoraIris[a-zA-Z-_]+', '[0-9a-zA-Z\.-]+'"],
      (e) {
        return '  ${e.replaceFirst('pod', 's.dependency')}';
      },
    );
  }

  String modifiedWindowsCMakeContent(
    List<String> sourceFileContentLines,
    String irisDenpendenciesContent,
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

    final cdn = findIrisWindowsCDN(irisDenpendenciesContent).cdn;
    if (cdn.isEmpty) {
      return sourceFileContentLines.join('\n');
    }

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
    List<String> nativeSDKRegExps,
    List<String> irisRegExps,
    String Function(String sourceLine) lineMapped,
  ) {
    List<String> modifiedFileContentLines = [];

    VersionLink irisVersionLink = findIrisVersionLink();
    VersionLink nativeVersionLink = findNativeVersionLink();

    bool isAddedNativeSDKVersions = false;
    bool isAddedIrisVersions = false;
    for (final line in sourceFileContentLines) {
      if (nativeSDKRegExps.hasMatch(line) &&
          !nativeVersionLink.noVersionLink()) {
        if (!isAddedNativeSDKVersions) {
          final mavenOrCocoaPods = nativeVersionLink.mavenOrCocoaPods
              .map((e) => lineMapped(e))
              .toList();

          modifiedFileContentLines.addAll(mavenOrCocoaPods);

          isAddedNativeSDKVersions = true;
        }

        continue;
      }

      if (irisRegExps.hasMatch(line) && !irisVersionLink.noVersionLink()) {
        if (!isAddedIrisVersions) {
          final mavenOrCocoaPods = irisVersionLink.mavenOrCocoaPods
              .map((e) => lineMapped(e))
              .toList();

          modifiedFileContentLines.addAll(mavenOrCocoaPods);

          isAddedIrisVersions = true;
        }

        continue;
      }

      modifiedFileContentLines.add(line);
    }

    return modifiedFileContentLines.join('\n');
  }
}
