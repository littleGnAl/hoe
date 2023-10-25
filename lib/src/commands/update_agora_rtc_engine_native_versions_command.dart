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

  String firstOrEmpty() {
    return isNotEmpty ? first : '';
  }
}

class UpdateAgoraRtcEngineNativeVersionsCommand extends BaseCommand {
  UpdateAgoraRtcEngineNativeVersionsCommand({
    required FileSystem fileSystem,
    required ProcessManager processManager,
    required Logger logger,
  }) : super(fileSystem, processManager, logger) {
    argParser.addOption('project-dir');
    argParser.addOption('pubspec-version');
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
    final String pubspecVersion = argResults?['pubspec-version'] ?? '';
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
    final artifactsVersionFilePath =
        path.join(_workspace.absolute.path, 'scripts', 'artifacts_version.sh');
    final pubspecFilePath = path.join(_workspace.absolute.path, 'pubspec.yaml');
    final exampleIOSPodfileFilePath =
        path.join(_workspace.absolute.path, 'example', 'ios', 'Podfile');

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

    final artifactsVersionFile = fileSystem.file(artifactsVersionFilePath);
    if (artifactsVersionFile.existsSync()) {
      artifactsVersionFile.writeAsStringSync(modifiedArtifactsVersionContent(
        artifactsVersionFile.readAsStringSync(),
        irisDenpendenciesContent,
      ));
    }

    if (pubspecVersion.isNotEmpty) {
      final pubspecFile = fileSystem.file(pubspecFilePath);
      pubspecFile.writeAsStringSync(modifiedPubspecContent(
        pubspecFile.readAsStringSync(),
        pubspecVersion,
      ));
    }

    if (nativeSdkDependenciesContent.isNotEmpty) {
      final exampleIOSPodfileFile = fileSystem.file(exampleIOSPodfileFilePath);
      exampleIOSPodfileFile.writeAsStringSync(modifiedExampleIOSPodfileContent(
        exampleIOSPodfileFile.readAsStringSync(),
        nativeSdkDependenciesContent,
      ));
    }

    modifyIrisWebVersion(_workspace.absolute.path, irisDenpendenciesContent);
  }

  List<String> _findByRegExp(List<String> regExps, String input) {
    List<String> outputs = [];

    if (input.isEmpty) {
      return outputs;
    }

    for (final reg in regExps) {
      RegExp regExp = RegExp(
        reg,
        caseSensitive: true,
        multiLine: true,
      );
      if (regExp.hasMatch(input)) {
        outputs.add(regExp.stringMatch(input) ?? '');
      }
    }

    return outputs;
  }

  VersionLink findNativeAndroidMaven(String nativeSdkDependenciesContent) {
    List<String> mavens = _findByRegExp(
      [
        r"implementation[\s]*'io.agora.rtc:full-sdk:[0-9a-zA-Z\.-]+'",
        r"implementation[\s]*'io.agora.rtc:agora-special-full:[0-9a-zA-Z\.-]+'",
        r"implementation[\s]*'io.agora.rtc:agora-full-preview:[0-9a-zA-Z\.-]+'",
        r"implementation[\s]*'io.agora.rtc:full-screen-sharing:[0-9a-zA-Z\.-]+'",
        r"implementation[\s]*'io.agora.rtc:full-screen-sharing-special:[0-9a-zA-Z\.-]+'",
        r"implementation[\s]*'io.agora.rtc:agora-special-voice:[0-9a-zA-Z\.-]+'",
        r"^[\s]*(implementation|api) 'io.agora.rtc:voice-[a-z-]+:[0-9a-zA-Z\.-]+'",
      ],
      nativeSdkDependenciesContent,
    );

    return VersionLink('', mavens);
  }

  VersionLink findNativeIOSPod(String nativeSdkDependenciesContent) {
    List<String> cocoapods = _findByRegExp(
      [
        r"pod[\s]*'AgoraRtcEngine_iOS',[\s]*'[0-9a-z.-]+'",
        r"pod[\s]*'AgoraRtcEngine_iOS_Preview',[\s]*'[0-9a-zA-Z.-]+'",
        r"pod[\s]*'AgoraRtcEngine_Special_iOS',[\s]*'[0-9a-zA-Z.-]+'",
        r"pod[\s]*'AgoraAudio_Special_iOS',[\s]*'[0-9a-zA-Z.-]+'",
        r"pod[\s]*'AgoraAudio_iOS',[\s]*'[0-9a-zA-Z.-]+'",
      ],
      nativeSdkDependenciesContent,
    );

    return VersionLink('', cocoapods);
  }

  VersionLink findNativeMacosPod(String nativeSdkDependenciesContent) {
    List<String> cocoapods = _findByRegExp(
      [
        r"pod[\s]*'AgoraRtcEngine_macOS',[\s]*'[0-9a-z.-]+'",
        r"pod[\s]*'AgoraRtcEngine_macOS_Preview',[\s]*'[0-9a-z.-]+'",
        r"pod[\s]*'AgoraRtcEngine_Special_macOS',[\s]*'[0-9a-z.-]+'"
      ],
      nativeSdkDependenciesContent,
    );

    return VersionLink('', cocoapods);
  }

  VersionLink findNativeWindowsCDN(String nativeSdkDependenciesContent) {
    final cdns = _findByRegExp(
      [
        r'https:\/\/download.agora.io\/sdk\/release\/Agora_Native_SDK_for_Windows_rel.v[0-9a-z\.-_]+_FULL_[0-9_]+\.zip',
      ],
      nativeSdkDependenciesContent,
    );

    return VersionLink(cdns.firstOrEmpty(), []);
  }

  VersionLink findIrisAndroidMaven(String irisDenpendenciesContent) {
    final cdns = _findByRegExp(
      [
        r'https:\/\/download\.agora\.io\/sdk\/release\/iris_[0-9a-z\.-]+_DCG_Android_Video_[0-9]+_[0-9]+\.zip',
      ],
      irisDenpendenciesContent,
    );

    final mavens = _findByRegExp(
      [
        r"implementation 'io.agora.rtc:iris-rtc:[0-9a-z\.-]+'",
      ],
      irisDenpendenciesContent,
    );

    return VersionLink(cdns.firstOrEmpty(), mavens);
  }

  VersionLink findIrisIOSPod(String irisDenpendenciesContent) {
    final cdns = _findByRegExp(
      [
        r'https:\/\/download\.agora\.io\/sdk\/release\/iris_[0-9a-z\.-]+_DCG_iOS_Video_[0-9]+_[0-9]+\.zip',
      ],
      irisDenpendenciesContent,
    );

    final cocoapods = _findByRegExp(
      [
        r"pod[\s]*'AgoraIrisRTC_iOS',[\s]*'[0-9a-z.-]+'",
      ],
      irisDenpendenciesContent,
    );

    return VersionLink(cdns.firstOrEmpty(), cocoapods);
  }

  VersionLink findIrisMacosPod(String irisDenpendenciesContent) {
    final cdns = _findByRegExp(
      [
        r'https:\/\/download\.agora\.io\/sdk\/release\/iris_[0-9a-z\.-]+_DCG_Mac_Video_[0-9]+_[0-9]+\.zip',
      ],
      irisDenpendenciesContent,
    );

    final cocoapods = _findByRegExp(
      [
        r"pod[\s]*'AgoraIrisRTC_macOS',[\s]*'[0-9a-z.-]+'",
      ],
      irisDenpendenciesContent,
    );

    return VersionLink(cdns.firstOrEmpty(), cocoapods);
  }

  VersionLink findIrisWindowsCDN(String irisDenpendenciesContent) {
    final cdns = _findByRegExp(
      [
        r'https:\/\/download\.agora\.io\/sdk\/release\/iris_[0-9a-z\.-]+_DCG_Windows_Video_[0-9]+_[0-9]+\.zip',
      ],
      irisDenpendenciesContent,
    );

    return VersionLink(cdns.firstOrEmpty(), []);
  }

  VersionLink findIrisWebCDN(
    String irisDenpendenciesContent,
    String urlRegExp,
  ) {
    final cdn = _findByRegExp(
      [urlRegExp],
      irisDenpendenciesContent,
    );

    return VersionLink(cdn.firstOrEmpty(), []);
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
        r"^[\s]*(implementation|api) 'io.agora.rtc:full-[a-z-]+:[0-9a-zA-Z\.-]+'",
        r"^[\s]*(implementation|api) 'io.agora.rtc:voice-[a-z-]+:[0-9a-zA-Z\.-]+'",
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
      [
        r"^[\s]*s.dependency 'AgoraRtc[a-zA-Z-_]+', '[0-9a-zA-Z\.-]+'",
        r"^[\s]*s.dependency 'AgoraAudio[a-zA-Z-_]+', '[0-9a-zA-Z\.-]+'",
      ],
      [r"^[\s]*s.dependency 'AgoraIris[a-zA-Z-_]+', '[0-9a-zA-Z\.-]+'"],
      (e) {
        return '  ${e.replaceFirst('pod', 's.dependency')}';
      },
    );
  }

  String modifiedExampleIOSPodfileContent(
    String sourceFileContent,
    String nativeSdkDependenciesContent,
  ) {
    final iosCocoaPods =
        findNativeIOSPod(nativeSdkDependenciesContent).mavenOrCocoaPods;
    String modifiedContent = sourceFileContent;

    final nativeSdkPattern = [
      r"[^\S\r\n]*pod\s'AgoraRtc[a-zA-Z-_]+', '[0-9a-zA-Z\.-]+'",
      r"[^\S\r\n]*pod\s'AgoraAudio[a-zA-Z-_]+', '[0-9a-zA-Z\.-]+'",
    ];

    if (iosCocoaPods.isNotEmpty) {
      for (final p in nativeSdkPattern) {
        modifiedContent = modifiedContent.replaceFirst(
          RegExp(p, multiLine: true, caseSensitive: true),
          '    ${iosCocoaPods[0]}',
        );
      }
    }

    return modifiedContent;
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

  String modifiedArtifactsVersionContent(
    String sourceFileContent,
    String irisDenpendenciesContent,
  ) {
    final androidCDN = findIrisAndroidMaven(irisDenpendenciesContent).cdn;
    final iosCDN = findIrisIOSPod(irisDenpendenciesContent).cdn;
    final macOSCDN = findIrisMacosPod(irisDenpendenciesContent).cdn;
    final windowsCDN = findIrisWindowsCDN(irisDenpendenciesContent).cdn;

    String modifiedContent = sourceFileContent;
    if (androidCDN.isNotEmpty) {
      modifiedContent = modifiedContent.replaceFirst(
        RegExp(r'export IRIS_CDN_URL_ANDROID=\"(.*)\"',
            multiLine: true, caseSensitive: true),
        'export IRIS_CDN_URL_ANDROID="$androidCDN"',
      );
    }

    if (iosCDN.isNotEmpty) {
      modifiedContent = modifiedContent.replaceFirst(
        RegExp(r'export IRIS_CDN_URL_IOS=\"(.*)\"',
            multiLine: true, caseSensitive: true),
        'export IRIS_CDN_URL_IOS="$iosCDN"',
      );
    }

    if (macOSCDN.isNotEmpty) {
      modifiedContent = modifiedContent.replaceFirst(
        RegExp(r'export IRIS_CDN_URL_MACOS=\"(.*)\"',
            multiLine: true, caseSensitive: true),
        'export IRIS_CDN_URL_MACOS="$macOSCDN"',
      );
    }

    if (windowsCDN.isNotEmpty) {
      modifiedContent = modifiedContent.replaceFirst(
        RegExp(r'export IRIS_CDN_URL_WINDOWS=\"(.*)\"',
            multiLine: true, caseSensitive: true),
        'export IRIS_CDN_URL_WINDOWS="$windowsCDN"',
      );
    }

    return modifiedContent;
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

  String modifiedPubspecContent(
    String sourceFileContent,
    String version,
  ) {
    if (version.isEmpty) {
      return version;
    }

    String modifiedContent = sourceFileContent;
    modifiedContent = modifiedContent.replaceFirst(
      RegExp(r'version\:\s[a-zA-Z0-9\.-]+',
          multiLine: true, caseSensitive: true),
      'version: $version',
    );

    return modifiedContent;
  }

  void modifyIrisWebVersion(
    String workspacePath,
    String nativeDenpendenciesContent,
  ) {
    if (nativeDenpendenciesContent.isEmpty) {
      logger.stdout('`nativeDenpendenciesContent` is empty, skip...');
      return;
    }

    // scripts/iris_web_version.js
    final irisWebVersionFilePath =
        path.join(workspacePath, 'scripts', 'iris_web_version.js');

    final irisWebVersionFile = fileSystem.file(irisWebVersionFilePath);
    if (!irisWebVersionFile.existsSync()) {
      logger.stdout('$irisWebVersionFilePath not found, skip...');
      return;
    }

    String irisWebVersionFileContent = irisWebVersionFile.readAsStringSync();

    // r'https:\/\/download\.agora\.io\/[a-z\/]+\/iris-web-rtc-[0-9a-z\.-]+\.js',
    final irisWebCdn = findIrisWebCDN(
      nativeDenpendenciesContent,
      r'https:\/\/download\.agora\.io\/[a-z\/]+\/iris-web-rtc_[0-9a-z]+_[0-9a-z]+_[0-9a-z\.-]+\.js',
    ).cdn;
    if (irisWebCdn.isEmpty) {
      logger.stdout(
          'Can not find the iris-web cdn in\n$nativeDenpendenciesContent,skip...');
    } else {
      // const irisWebUrl = 'https://download.agora.io/staging/iris-web-rtc_0.1.2-dev.2.js';
      RegExp irisWebUrlRegExp = RegExp(
        r"const irisWebUrl = \'https:\/\/download\.agora\.io\/[a-z\/]+\/iris-web-rtc_[0-9a-z]+_[0-9a-z]+_[0-9a-z\.-]+\.js\';",
        caseSensitive: true,
        multiLine: true,
      );
      irisWebVersionFileContent = irisWebVersionFileContent.replaceFirstMapped(
          irisWebUrlRegExp, (match) => 'const irisWebUrl = \'$irisWebCdn\';');
      irisWebVersionFile.writeAsStringSync(irisWebVersionFileContent);

      // example/web/index.html
      final exampleWebIndexFilePath =
          path.join(workspacePath, 'example', 'web', 'index.html');

      final exampleWebIndexFile = fileSystem.file(exampleWebIndexFilePath);
      if (exampleWebIndexFile.existsSync()) {
        String exampleWebIndexFileContent =
            exampleWebIndexFile.readAsStringSync();

        final irisWebUrlRegExp = RegExp(
          r'<script src="https:\/\/download\.agora\.io\/[a-z\/]+\/iris-web-rtc_[0-9a-z]+_[0-9a-z]+_[0-9a-z\.-]+\.js"></script>',
          caseSensitive: true,
          multiLine: true,
        );
        exampleWebIndexFileContent =
            exampleWebIndexFileContent.replaceFirstMapped(irisWebUrlRegExp,
                (match) => '<script src="$irisWebCdn"></script>');
        exampleWebIndexFile.writeAsStringSync(exampleWebIndexFileContent);
      } else {
        logger.stdout('$exampleWebIndexFilePath not found, skip...');
      }
    }

    // r'https:\/\/download\.agora\.io\/[a-z\/]+\/iris-web-rtc-fake_[0-9a-z\.-]+\.js',
    final irisWebFakeCdn = findIrisWebCDN(
      nativeDenpendenciesContent,
      r'https:\/\/download\.agora\.io\/[a-z\/]+\/iris-web-rtc-fake_[0-9a-z]+_[0-9a-z]+_[0-9a-z\.-]+\.js',
    ).cdn;
    if (irisWebFakeCdn.isEmpty) {
      logger.stdout(
          'Can not find the iris-web-fake cdn in\n$nativeDenpendenciesContent\nskip...');
    } else {
      RegExp irisWebFakeUrlRegExp = RegExp(
        r"const irisWebFakeUrl = \'https:\/\/download\.agora\.io\/[a-z\/]+\/iris-web-rtc-fake_[0-9a-z]+_[0-9a-z]+_[0-9a-z\.-]+\.js\';",
        caseSensitive: true,
        multiLine: true,
      );
      irisWebVersionFileContent = irisWebVersionFileContent.replaceFirstMapped(
          irisWebFakeUrlRegExp,
          (match) => 'const irisWebFakeUrl = \'$irisWebFakeCdn\';');
      irisWebVersionFile.writeAsStringSync(irisWebVersionFileContent);
    }
  }
}
