import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:file/file.dart';
import 'package:hoe/src/base/base_command.dart';
import 'package:hoe/src/base/process_manager_ext.dart';
import 'package:hoe/src/common/default_file_downloader.dart';
import 'package:hoe/src/common/global_config.dart';
import 'package:hoe/src/common/ios_plist_config.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';

const String _agoraRtcWrapperPodSpecFileTemplate = '''
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint agora_rtc_engine.podspec` to validate before publishing.
#

Pod::Spec.new do |s|
  s.name             = 'AgoraRtcWrapper'
  s.version          = '3.6.2'
  s.summary          = 'A new flutter plugin project.'
  s.description      = 'project.description'
  s.homepage         = 'https://github.com/AgoraIO/Flutter-SDK'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Agora' => 'developer@agora.io' }
  s.source           = { :path => '.' }
  s.vendored_frameworks = '{{AGORA_RTC_WRAPPER}}', {{AGORA_RTC_ENGINE_LIBS}}
end
''';

class BuildAgoraRtcEngineExampleCommand extends BaseCommand {
  BuildAgoraRtcEngineExampleCommand({
    required FileSystem fileSystem,
    required ProcessManager processManager,
    required Logger logger,
  }) : super(fileSystem, processManager, logger) {
    argParser.addOption('platforms');
    argParser.addFlag('setup-local-dev');
    argParser.addOption('local-iris-path');
    argParser.addOption('iris-android-cdn-url');
    argParser.addOption('iris-macos-cdn-url');
    argParser.addOption('iris-ios-cdn-url');
    argParser.addOption('iris-windows-download-url');
    argParser.addFlag('process-build');
    argParser.addOption('apple-package-name');
    argParser.addOption('flutter-package-name');
    argParser.addOption('project-dir');
    argParser.addOption('artifacts-output-dir');
  }

  late final Directory _workspace;

  final GlobalConfig _globalConfig = GlobalConfig();

  @override
  String get description => 'Build agora_rtc_engine example';

  @override
  String get name => 'build-agora-flutter-example';

  @override
  Future<void> run() async {
    final String platforms = argResults?['platforms'] ?? '';
    final bool isSetupDev = argResults?['setup-local-dev'] ?? false;
    final String localIrisPath = argResults?['local-iris-path'] ?? '';
    final String irisAndroidCDNUrl = argResults?['iris-android-cdn-url'] ?? '';
    final String irisMacosCDNUrl = argResults?['iris-macos-cdn-url'] ?? '';
    final String irisIOSCDNUrl = argResults?['iris-ios-cdn-url'] ?? '';
    final String irisWindowsDownloadUrl =
        argResults?['iris-windows-download-url'] ?? '';
    final bool isProcessBuild = argResults?['process-build'] ?? false;
    final String applePackageName = argResults?['apple-package-name'] ?? '';
    final String flutterPackageName = argResults?['flutter-package-name'] ?? '';
    final String projectDir = argResults?['project-dir'] ?? '';
    final String artifactsOutputDir = argResults?['artifacts-output-dir'] ?? '';

    _workspace = fileSystem.directory(projectDir);
    stdout.writeln(_workspace.absolute.path);

    final originalScriptsPath = path.join(
        fileSystem
            .file(Platform.script.toFilePath(windows: Platform.isWindows))
            .parent
            .parent
            .parent
            .absolute
            .path,
        'scripts');

    final platformsList = platforms.split(',');
    for (final platform in platformsList) {
      switch (platform) {
        case 'ios':
          if (isSetupDev) {
            await _setupIOSDev(
                flutterPackageName, localIrisPath, irisIOSCDNUrl);
          }

          if (isProcessBuild) {
            await _processBuildIOS(applePackageName, flutterPackageName,
                originalScriptsPath, artifactsOutputDir);
          }
          break;
        case 'macos':
          if (isSetupDev) {
            await _setupMacOSDev(localIrisPath, irisMacosCDNUrl);
          }

          if (isProcessBuild) {
            await _processBuildMacOS(
                flutterPackageName, originalScriptsPath, artifactsOutputDir);
          }
          break;
        case 'android':
          if (isSetupDev) {
            await _setupAndroidDev(localIrisPath, irisAndroidCDNUrl);
          }

          if (isProcessBuild) {
            await _processBuildAndroid(
                flutterPackageName, originalScriptsPath, artifactsOutputDir);
          }
          break;
        case 'windows':
          if (isSetupDev) {
            await _setupWindowsDev(irisWindowsDownloadUrl, originalScriptsPath);
          }

          if (isProcessBuild) {
            await _processBuildWindows(
                flutterPackageName, originalScriptsPath, artifactsOutputDir);
          }
          break;

        default:
          throw Exception('Unsupported platform: $platform');
      }
    }
  }

  Future<void> _setupAndroidDev(
      String localIrisPath, String irisAndroidCDNUrl) async {
    final androidModulePath = path.join(_workspace.absolute.path, 'android');
    final devFilePath = path.join(androidModulePath, '.plugin_dev');
    final devFile = fileSystem.file(devFilePath);
    if (!devFile.existsSync()) {
      devFile.createSync();
    }

    final irisLibsPath = path.join(androidModulePath, 'libs');
    final irisLibsDir = fileSystem.directory(irisLibsPath);
    if (!irisLibsDir.existsSync()) {
      irisLibsDir.createSync();
    }

    if (localIrisPath.isNotEmpty) {
      final agoraWrapperJarPath =
          path.join(irisLibsPath, 'AgoraRtcWrapper.jar');
      final agoraWrapperJar = fileSystem.file(agoraWrapperJarPath);
      if (!agoraWrapperJar.existsSync()) {
        processManager.runSyncWithOutput(
          [
            'bash',
            'scripts/build-iris-android.sh',
            localIrisPath,
            'Release',
            'Agora_Native_SDK_for_Android_FULL',
          ],
          runInShell: true,
          workingDirectory: _workspace.absolute.path,
        );
      }
    } else if (irisAndroidCDNUrl.isNotEmpty) {
      final unzipFilePath =
          await _downloadAndUnzip(irisAndroidCDNUrl, androidModulePath, false);

      _copyDirectory(
          fileSystem.directory(path.join(unzipFilePath, 'DCG',
              'Agora_Native_SDK_for_Android_FULL', 'rtc', 'sdk')),
          fileSystem.directory(path.join(androidModulePath, 'libs')));

      fileSystem
          .file(path.join(unzipFilePath, 'ALL_ARCHITECTURE', 'Release',
              'AgoraRtcWrapper.jar'))
          .copySync(
              path.join(androidModulePath, 'libs', 'AgoraRtcWrapper.jar'));

      final abis = ['arm64-v8a', 'armeabi-v7a', 'x86_64'];
      for (final abi in abis) {
        fileSystem
            .file(path.join(unzipFilePath, 'ALL_ARCHITECTURE', 'Release', abi,
                'libAgoraRtcWrapper.so'))
            .copySync(path.join(
                androidModulePath, 'libs', abi, 'libAgoraRtcWrapper.so'));

        final irisTesterLibsAbiPath = path.join(_workspace.absolute.path,
            'test_shard', 'iris_tester', 'android', 'libs', abi);
        if (!fileSystem.directory(irisTesterLibsAbiPath).existsSync()) {
          fileSystem
              .directory(irisTesterLibsAbiPath)
              .createSync(recursive: true);
        }

        fileSystem
            .file(path.join(unzipFilePath, 'ALL_ARCHITECTURE', 'Release', abi,
                'libIrisDebugger.so'))
            .copySync(
              path.join(
                irisTesterLibsAbiPath,
                'libIrisDebugger.so',
              ),
            );
      }
    }
  }

  Future<void> _setupIOSDev(String flutterPackageName, String localIrisPath,
      String irisIOSCDNUrl) async {
    final iosModulePath = path.join(_workspace.absolute.path, 'ios');
    final iosModuleDir = fileSystem.directory(iosModulePath);

    if (localIrisPath.isNotEmpty) {
      final irisFrameworkPath =
          path.join(iosModulePath, 'AgoraRtcWrapper.xcframework');
      final irisFramework = fileSystem.directory(irisFrameworkPath);
      if (!irisFramework.existsSync()) {
        stdout.writeln('irisFrameworkPath not exist: $irisFrameworkPath');
        processManager.runSyncWithOutput(
          ['bash', 'scripts/build-iris-ios.sh', 'Release', localIrisPath],
          runInShell: true,
          workingDirectory: _workspace.absolute.path,
        );

        stdout.writeln('startWithOutput done');
      }
    }

    if (irisIOSCDNUrl.isNotEmpty) {
      final unzipFilePath =
          await _downloadAndUnzip(irisIOSCDNUrl, iosModulePath, true);

      fileSystem
          .directory(path.join(
            unzipFilePath,
            'DCG',
            'Agora_Native_SDK_for_iOS_FULL',
            'libs',
            'ALL_ARCHITECTURE',
          ))
          .deleteSync(recursive: true);

      processManager.runSyncWithOutput([
        'cp',
        '-RP',
        path.join(
          unzipFilePath,
          'DCG',
          'Agora_Native_SDK_for_iOS_FULL',
          'libs/',
        ),
        path.join(iosModulePath, 'libs')
      ]);

      processManager.runSyncWithOutput([
        'cp',
        '-RP',
        path.join(
          unzipFilePath,
          'ALL_ARCHITECTURE',
          'Release',
          'AgoraRtcWrapper.xcframework',
        ),
        iosModulePath
      ]);

      processManager.runSyncWithOutput([
        'cp',
        '-RP',
        path.join(
          unzipFilePath,
          'ALL_ARCHITECTURE',
          'Release',
          'Release',
          'IrisDebugger.xcframework',
        ),
        path.join(_workspace.absolute.path, 'test_shard', 'iris_tester', 'ios'),
      ]);
    }

    fileSystem.file(path.join(iosModulePath, '.plugin_dev')).createSync();

    final podspecFilePath =
        path.join(iosModulePath, '$flutterPackageName.podspec');
    _createAgoraRtcWrapperPodSpecFile(iosModuleDir, isXCFramework: true);
    _modifyPodSpecFile(podspecFilePath, true);

    _runFlutterPackagesGet(path.join(_workspace.absolute.path, 'example'));
    _runPodInstall(path.join(_workspace.absolute.path, 'example', 'ios'));
  }

  Future<void> _setupMacOSDev(
    String localIrisPath,
    String irisMacosCDNUrl,
  ) async {
    final macosModulePath = path.join(_workspace.absolute.path, 'macos');
    final macosModuleDir = fileSystem.directory(macosModulePath);

    if (localIrisPath.isNotEmpty) {
      final irisFrameworkPath =
          path.join(macosModulePath, 'AgoraRtcWrapper.framework');
      final irisFramework = fileSystem.directory(irisFrameworkPath);
      if (!irisFramework.existsSync()) {
        processManager.runSyncWithOutput(
          [
            'bash',
            'scripts/build-iris-macos.sh',
            localIrisPath,
            'Release',
            'Agora_Native_SDK_for_Mac_FULL',
          ],
          runInShell: true,
          workingDirectory: _workspace.absolute.path,
        );
      }
    }

    if (irisMacosCDNUrl.isNotEmpty) {
      final unzipFilePath =
          await _downloadAndUnzip(irisMacosCDNUrl, macosModulePath, true);

      processManager.runSyncWithOutput([
        'cp',
        '-RP',
        path.join(
          unzipFilePath,
          'DCG',
          'Agora_Native_SDK_for_Mac_FULL',
          'libs/',
        ),
        path.join(macosModulePath, 'libs')
      ]);
      processManager.runSyncWithOutput([
        'cp',
        '-RP',
        path.join(
          unzipFilePath,
          'MAC',
          'Release',
          'AgoraRtcWrapper.framework',
        ),
        macosModulePath
      ]);
      processManager.runSyncWithOutput([
        'cp',
        '-RP',
        path.join(
          unzipFilePath,
          'MAC',
          'Release',
          'Release',
          'IrisDebugger.framework',
        ),
        path.join(
            _workspace.absolute.path, 'test_shard', 'iris_tester', 'macos'),
      ]);
    }

    fileSystem.file(path.join(macosModulePath, '.plugin_dev')).createSync();

    final podspecFilePath =
        path.join(macosModulePath, 'agora_rtc_engine.podspec');
    _createAgoraRtcWrapperPodSpecFile(macosModuleDir);
    _modifyPodSpecFile(podspecFilePath, true);

    _runFlutterPackagesGet(path.join(_workspace.absolute.path, 'example'));
    _runPodInstall(path.join(_workspace.absolute.path, 'example', 'macos'));
  }

  Future<void> _setupWindowsDev(
      String irisWindowsDownloadUrl, String originalScriptsPath) async {
    // final downloadWindowsScriptPath =
    //     path.join(originalScriptsPath, 'download-iris-windows.sh');
    final windowsModulePath = path.join(
      _workspace.absolute.path,
      'windows',
    );

    if (irisWindowsDownloadUrl.isNotEmpty) {
      final thirdPartyDir =
          fileSystem.directory(path.join(windowsModulePath, 'third_party'));
      if (thirdPartyDir.existsSync()) {
        thirdPartyDir.deleteSync(recursive: true);
      }

      thirdPartyDir.createSync();
      final thirdPartyIrisDir =
          fileSystem.directory(path.join(thirdPartyDir.absolute.path, 'iris'));
      thirdPartyIrisDir.createSync();

      final unzipFilePath = await _downloadAndUnzip(
          irisWindowsDownloadUrl, windowsModulePath, true);
    }

// iris_windows
//     final irisWindowsPath = path.join(windowsModulePath, 'iris_windows');
//     final irisWindowsDir = fileSystem.directory(irisWindowsPath);
//     final irisWindowsTmpDir =
//         fileSystem.directory(path.join(irisWindowsPath, 'tmp'));
//     final irisWindowsIrisSDKDir = fileSystem.directory(
//         path.join(irisWindowsPath, 'Agora_Native_SDK_for_Windows_IRIS'));
//     if (irisWindowsDir.existsSync()) {
//       irisWindowsDir.deleteSync(recursive: true);
//     }

//     irisWindowsDir.createSync();
//     irisWindowsIrisSDKDir.createSync();
//     irisWindowsTmpDir.createSync();

//     final irisWindowsZipFile = fileSystem
//         .file(path.join(irisWindowsDir.absolute.path, 'iris_windows.zip'));
//     final fileDownloader = DefaultFileDownloader(_globalConfig);
//     await fileDownloader.downloadFile(
//       irisWindowsDownloadUrl,
//       irisWindowsZipFile.absolute.path,
//     );

// // Use an InputFileStream to access the zip file without storing it in memory.
//     final inputStream = InputFileStream(irisWindowsZipFile.absolute.path);
// // Decode the zip from the InputFileStream. The archive will have the contents of the
// // zip, without having stored the data in memory.
//     final archive = ZipDecoder().decodeBuffer(inputStream);
//     extractArchiveToDisk(archive, irisWindowsTmpDir.absolute.path);
//     inputStream.close();

//     inputStream.close();

//     // final tmpDir = fileSystem.directory(path.join(irisWindowsPath, 'tmp'));
//     final extractPath = irisWindowsTmpDir.listSync()[0].path;
//     _copyDirectory(fileSystem.directory(extractPath), irisWindowsIrisSDKDir);

//     irisWindowsZipFile.deleteSync(recursive: true);
//     irisWindowsTmpDir.deleteSync(recursive: true);

//     final thirdPartyDir =
//         fileSystem.directory(path.join(windowsModulePath, 'third_party'));
//     if (thirdPartyDir.existsSync()) {
//       thirdPartyDir.deleteSync(recursive: true);
//     }

//     thirdPartyDir.createSync();
//     final thirdPartyIrisDir =
//         fileSystem.directory(path.join(thirdPartyDir.absolute.path, 'iris'));
//     thirdPartyIrisDir.createSync();

//     _copyDirectory(irisWindowsDir, thirdPartyIrisDir);
//     irisWindowsDir.deleteSync(recursive: true);

    final devFilePath = path.join(windowsModulePath, '.plugin_dev');
    final devFile = fileSystem.file(devFilePath);
    if (!devFile.existsSync()) {
      devFile.createSync();
    }

    // final irisArctifactsPath = path.join(windowsModulePath, 'third_party',
    //     'iris', 'Agora_Native_SDK_for_Windows_IRIS');

    // final irisArctifactsDir = fileSystem.directory(irisArctifactsPath);
    // if (irisArctifactsDir.existsSync()) {
    //   irisArctifactsDir.deleteSync(recursive: true);
    // }

    // processManager.runSyncWithOutput(
    //   ['bash', downloadWindowsScriptPath, irisWindowsDownloadUrl],
    //   runInShell: true,
    //   includeParentEnvironment: true,
    //   workingDirectory: _workspace.absolute.path,
    // );
  }

  void _modifyPodSpecFile(String podspecFilePath, bool forDev) {
    final podspecFile = fileSystem.file(podspecFilePath);
    final lines = podspecFile.readAsLinesSync();
    final newOutput = StringBuffer();
    bool meetAgoraDependency = false;
    for (final line in lines) {
      final trimLine = line.trim();

      if (forDev) {
        if (trimLine.startsWith('s.dependency \'Agora')) {
          if (!meetAgoraDependency) {
            newOutput.writeln('  s.dependency \'AgoraRtcWrapper\'');
          }

          meetAgoraDependency = true;
          newOutput.writeln('  # $line');

          continue;
        }
      } else {
        if (trimLine.startsWith('# s.dependency \'AgoraIrisRTC')) {
          newOutput.writeln(line.replaceAll('# ', ''));
          continue;
        }
        if (trimLine.startsWith('s.dependency \'AgoraRtcWrapper\'')) {
          continue;
        }
      }

      newOutput.writeln(line);
    }

    podspecFile.writeAsStringSync(newOutput.toString());
  }

  void _modifyPodFile(String podFilePath, bool forDev) {
    const agoraRtcWrapperPodLine = 'pod \'AgoraRtcWrapper\', :path => ';
    final podFile = fileSystem.file(podFilePath);
    final lines = podFile.readAsLinesSync();
    final newOutput = StringBuffer();
    for (final line in lines) {
      final trimLine = line.trim();

      if (forDev) {
        if (trimLine.startsWith('# $agoraRtcWrapperPodLine')) {
          newOutput.writeln(line.replaceAll('# ', ''));
          continue;
        }
      } else {
        if (trimLine.startsWith(agoraRtcWrapperPodLine)) {
          newOutput.writeln('# $agoraRtcWrapperPodLine');
          continue;
        }
      }

      newOutput.writeln(line);
    }

    podFile.writeAsStringSync(newOutput.toString());
  }

  void _createAgoraRtcWrapperPodSpecFile(Directory iosModuleDir,
      {bool isXCFramework = false}) {
    final agoraRtcWrapperPodspecFilePath =
        path.join(iosModuleDir.absolute.path, 'AgoraRtcWrapper.podspec');
    final agoraRtcWrapperPodspecFile =
        fileSystem.file(agoraRtcWrapperPodspecFilePath);
    if (!agoraRtcWrapperPodspecFile.existsSync()) {
      agoraRtcWrapperPodspecFile.createSync(recursive: true);
    }
    final agoraRtcLibsPath = path.join(iosModuleDir.absolute.path, 'libs');
    final agoraRtcLibsDir = fileSystem.directory(agoraRtcLibsPath);
    final agoraRtcLibList = [];
    agoraRtcLibsDir.listSync().forEach((element) {
      agoraRtcLibList.add('\'libs/${element.basename}\'');
    });

    final agoraRtcEngineVendoredFrameworks = agoraRtcLibList.join(', ');
    String agoraRtcWrapperPodSpecFileContent =
        _agoraRtcWrapperPodSpecFileTemplate.replaceAll(
            '{{AGORA_RTC_ENGINE_LIBS}}', agoraRtcEngineVendoredFrameworks);
    agoraRtcWrapperPodSpecFileContent =
        agoraRtcWrapperPodSpecFileContent.replaceAll(
            '{{AGORA_RTC_WRAPPER}}',
            isXCFramework
                ? 'AgoraRtcWrapper.xcframework'
                : 'AgoraRtcWrapper.framework');
    agoraRtcWrapperPodspecFile
        .writeAsStringSync(agoraRtcWrapperPodSpecFileContent);
  }

  void _runPodInstall(String iosProjectPath) {
    processManager.runSyncWithOutput(
      ['pod', 'install'],
      runInShell: true,
      workingDirectory: iosProjectPath,
    );
  }

  /// bash $MY_PATH/build-internal-testing-android.sh agora_rtc_engine_example
  Future<void> _processBuildAndroid(String flutterPackageName,
      String originalScriptsPath, String artifactsOutputDirPath) async {
    _runFlutterClean(path.join(_workspace.absolute.path, 'example'));
    _runFlutterPackagesGet(path.join(_workspace.absolute.path, 'example'));

    final archiveDirPath =
        _createArchiveOutputDir(_workspace.absolute.path, 'android');

    _flutterBuild(path.join(_workspace.absolute.path, 'example'), 'apk');

    final flutterApk = fileSystem.file(path.join(
        _workspace.absolute.path,
        'example',
        'build',
        'app',
        'outputs',
        'flutter-apk',
        'app-release.apk'));
    flutterApk.copySync(path.join(archiveDirPath, '$flutterPackageName.apk'));

    final artifactsOutputDir = fileSystem.directory(artifactsOutputDirPath);
    if (!artifactsOutputDir.existsSync()) {
      artifactsOutputDir.createSync(recursive: true);
    }

    final outputZipPath = path.join(artifactsOutputDirPath,
        _createOutputZipPath(flutterPackageName, 'android'));

    await _zipDirs([archiveDirPath], outputZipPath);

    stdout.writeln('Created $outputZipPath');
  }

  String _createArchiveOutputDir(String projectDir, String platform) {
    final outputDir = fileSystem.directory(path.join(_workspace.absolute.path,
        'example', 'build', 'internal_testing_artifacts', platform));
    if (outputDir.existsSync()) {
      outputDir.deleteSync(recursive: true);
    }

    outputDir.createSync(recursive: true);

    return outputDir.absolute.path;
  }

  File _createPList(
    String applePackageName,
    String profileName,
    String outputFilePath,
  ) {
    final plistTemplate = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>development</string>
	<key>compileBitcode</key>
	<true/>
	<key>provisioningProfiles</key>
	<dict>
		<key>{{PACKAGE_NAME}}</key>
		<string>{{PROFILE_NAME}}</string>
    <key>{{PACKAGE_NAME2}}</key>
		<string>{{PROFILE_NAME2}}</string>
	</dict>
</dict>
</plist>
''';
    final output = plistTemplate
        .replaceAll('{{PACKAGE_NAME}}', applePackageName)
        .replaceAll('{{PROFILE_NAME}}', profileName)
        .replaceAll('{{PACKAGE_NAME2}}', '$applePackageName.ScreenSharing')
        .replaceAll('{{PROFILE_NAME2}}', profileName);
    File file = fileSystem.file(outputFilePath);
    file.writeAsStringSync(output);
    return file;
  }

  /// bash $MY_PATH/build-internal-testing-ios.sh agora_rtc_engine_example io.agora.agoraRtcEngineExampleTest io.agora.agoraRtcEngineExampleLab io.agora.agoraRtcEngineExampleQA io.agora.agoraRtcEngineExample
  Future<void> _processBuildIOS(
      String applePackageName,
      String flutterPackageName,
      String originalScriptsPath,
      String artifactsOutputDirPath) async {
    _runFlutterClean(path.join(_workspace.absolute.path, 'example'));
    _runFlutterPackagesGet(path.join(_workspace.absolute.path, 'example'));
    final examplePath = path.join(_workspace.absolute.path, 'example');
    // final globalConfig = GlobalConfig();

    // final plistDirPath =
    //     path.join(_workspace.absolute.path, 'example', 'ios', 'plists');
    // final plistDir = fileSystem.directory(plistDirPath);
    // if (plistDir.existsSync()) {
    //   plistDir.deleteSync(recursive: true);
    // }
    // plistDir.createSync();

    final archiveDirPath =
        _createArchiveOutputDir(_workspace.absolute.path, 'ios');

    processManager.runSyncWithOutput(['pod', 'repo', 'update']);

    _installAppleCertificate(
        p12OutputPath: path.join(
          _globalConfig.githubActionRunnerTemp,
          'agoratest2020.p12',
        ),
        provisionOutputPath: path.join(
          _globalConfig.githubActionRunnerTemp,
          'agoratest2020_pp.mobileprovision',
        ),
        keychainOutputPath: path.join(
          _globalConfig.githubActionRunnerTemp,
          'agoratest2020-app-signing.keychain-db',
        ),
        gpgProvisionName: 'AgoraTest2020.mobileprovision.gpg',
        gpgProvisionPwd: _globalConfig.agoratest2020PPGpgPwd,
        p12Base64: _globalConfig.agoratest2020P12Base64,
        p12Pwd: _globalConfig.agoratest2020P12Pwd,
        keychainPwd: _globalConfig.agoratest2020KeychainPassword);

    final pListConfigTest =
        PListConfig('${applePackageName}Test', 'AgoraTest2020');
    _buildIOSIpa(
        examplePath,
        flutterPackageName,
        path.join(examplePath, 'ios', 'Runner.xcodeproj'),
        pListConfigTest.applePackageName,
        _globalConfig.appleTeamIdTest,
        pListConfigTest.profileName,
        _globalConfig.appleCodeSignIdentityTest,
        false,
        pListConfigTest,
        {
          'Runner': '${applePackageName}Test',
          'ScreenSharing': '${applePackageName}Test.ScreenSharing',
        },
        archiveDirPath);

    _installAppleCertificate(
        p12OutputPath: path.join(
          _globalConfig.githubActionRunnerTemp,
          'agoralab2020.p12',
        ),
        provisionOutputPath: path.join(
          _globalConfig.githubActionRunnerTemp,
          'agoralab2020_pp.mobileprovision',
        ),
        keychainOutputPath: path.join(
          _globalConfig.githubActionRunnerTemp,
          'agoralab2020-app-signing.keychain-db',
        ),
        gpgProvisionName: 'AgoraLab2020.mobileprovision.gpg',
        gpgProvisionPwd: _globalConfig.agoralab2020PPGpgPwd,
        p12Base64: _globalConfig.agoralab2020P12Base64,
        p12Pwd: _globalConfig.agoralab2020P12Pwd,
        keychainPwd: _globalConfig.agoralab2020KeychainPassword);

    final pListConfigLab =
        PListConfig('${applePackageName}Lab', 'AgoraLab2020');
    _buildIOSIpa(
        examplePath,
        flutterPackageName,
        path.join(examplePath, 'ios', 'Runner.xcodeproj'),
        pListConfigLab.applePackageName,
        _globalConfig.appleTeamIdLab,
        pListConfigLab.profileName,
        _globalConfig.appleCodeSignIdentityLab,
        false,
        pListConfigLab,
        {
          'Runner': '${applePackageName}Lab',
          'ScreenSharing': '${applePackageName}Lab.ScreenSharing',
        },
        archiveDirPath);

    _installAppleCertificate(
        p12OutputPath: path.join(
          _globalConfig.githubActionRunnerTemp,
          'agoraqa2021.p12',
        ),
        provisionOutputPath: path.join(
          _globalConfig.githubActionRunnerTemp,
          'agoraqa2021_pp.mobileprovision',
        ),
        keychainOutputPath: path.join(
          _globalConfig.githubActionRunnerTemp,
          'agoraqa2021-app-signing.keychain-db',
        ),
        gpgProvisionName: 'AgoraQA2021.mobileprovision.gpg',
        gpgProvisionPwd: _globalConfig.agoraqa2021PPGpgPwd,
        p12Base64: _globalConfig.agoraqa2021P12Base64,
        p12Pwd: _globalConfig.agoraqa2021P12Pwd,
        keychainPwd: _globalConfig.agoraqa2021KeychainPassword);

    final pListConfigQA = PListConfig('${applePackageName}QA', 'AgoraQA2021');
    _buildIOSIpa(
        examplePath,
        flutterPackageName,
        path.join(examplePath, 'ios', 'Runner.xcodeproj'),
        pListConfigQA.applePackageName,
        _globalConfig.appleTeamIdQa,
        pListConfigQA.profileName,
        _globalConfig.appleCodeSignIdentityQa,
        false,
        pListConfigQA,
        {
          'Runner': '${applePackageName}QA',
          'ScreenSharing': '${applePackageName}QA.ScreenSharing',
        },
        archiveDirPath);

    final artifactsOutputDir = fileSystem.directory(artifactsOutputDirPath);
    if (!artifactsOutputDir.existsSync()) {
      artifactsOutputDir.createSync(recursive: true);
    }

    final outputZipPath = path.join(artifactsOutputDirPath,
        _createOutputZipPath(flutterPackageName, 'ios'));

    await _zipDirs([archiveDirPath], outputZipPath);

    stdout.writeln('Created $outputZipPath');
  }

  Future<void> _processBuildMacOS(
    String flutterPackageName,
    String originalScriptsPath,
    String artifactsOutputDirPath,
  ) async {
    _runFlutterClean(path.join(_workspace.absolute.path, 'example'));
    _runFlutterPackagesGet(path.join(_workspace.absolute.path, 'example'));

    final archiveDirPath =
        _createArchiveOutputDir(_workspace.absolute.path, 'macos');

    processManager.runSyncWithOutput(['pod', 'repo', 'update']);

    _flutterBuild(path.join(_workspace.absolute.path, 'example'), 'macos');

    final macosArtifactPath = path.join(_workspace.absolute.path, 'example',
        'build', 'macos', 'Build', 'Products', 'Release');

    fileSystem
        .directory(
            path.join(archiveDirPath, '${flutterPackageName}_example.app'))
        .createSync();
    _copyDirectory(
        fileSystem.directory(
            path.join(macosArtifactPath, '${flutterPackageName}_example.app')),
        fileSystem.directory(
            path.join(archiveDirPath, '${flutterPackageName}_example.app')));

    fileSystem.directory(path.join(archiveDirPath, 'dSYMs')).createSync();
    final macosPluginDsymsDir = fileSystem.directory(path.join(
        macosArtifactPath,
        flutterPackageName,
        '$flutterPackageName.framework.dSYM'));
    _copyDirectory(
        macosPluginDsymsDir,
        fileSystem.directory(path.join(
            archiveDirPath, 'dSYMs', '$flutterPackageName.framework.dSYM')));

    final macosAppDsymsDir = fileSystem.directory(
        path.join(macosArtifactPath, '${flutterPackageName}_example.app.dSYM'));
    _copyDirectory(
        macosAppDsymsDir,
        fileSystem.directory(path.join(archiveDirPath, 'dSYMs',
            '${flutterPackageName}_example.app.dSYM')));

    final artifactsOutputDir = fileSystem.directory(artifactsOutputDirPath);
    if (!artifactsOutputDir.existsSync()) {
      artifactsOutputDir.createSync(recursive: true);
    }

    final libPath = path.join(
        fileSystem
            .file(Platform.script.toFilePath(windows: Platform.isWindows))
            .parent
            .parent
            .absolute
            .path,
        'lib');

    final zipFileBaseName = _createOutputZipPath(flutterPackageName, 'macos');
    final outputZipPath = path.join(archiveDirPath, zipFileBaseName);

    // _zipDirs will cause the mac app not runnable after decompress, so use base `zip` command here
    processManager.runSyncWithOutput(
      [
        'bash',
        path.join(libPath, 'bash', 'zip-file.sh'),
        fileSystem.file(archiveDirPath).parent.absolute.path,
        outputZipPath,
        'macos/',
      ],
      runInShell: true,
      workingDirectory: fileSystem.file(archiveDirPath).parent.absolute.path,
    );

    fileSystem
        .file(outputZipPath)
        .copySync(path.join(artifactsOutputDirPath, zipFileBaseName));

    stdout.writeln(
        'Created ${path.join(artifactsOutputDirPath, zipFileBaseName)}');
  }

  Future<void> _processBuildWindows(
    String flutterPackageName,
    String originalScriptsPath,
    String artifactsOutputDirPath,
  ) async {
    _runFlutterClean(path.join(_workspace.absolute.path, 'example'));
    _runFlutterPackagesGet(path.join(_workspace.absolute.path, 'example'));

    final archiveDirPath =
        _createArchiveOutputDir(_workspace.absolute.path, 'windows');

    _flutterBuild(path.join(_workspace.absolute.path, 'example'), 'windows');

    _copyDirectory(
        fileSystem.directory(path.join(_workspace.absolute.path, 'example',
            'build', 'windows', 'runner', 'Release')),
        fileSystem.directory(archiveDirPath));

    final artifactsOutputDir = fileSystem.directory(artifactsOutputDirPath);
    if (!artifactsOutputDir.existsSync()) {
      artifactsOutputDir.createSync(recursive: true);
    }

    final outputZipPath = path.join(artifactsOutputDirPath,
        _createOutputZipPath(flutterPackageName, 'windows'));

    await _zipDirs([archiveDirPath], outputZipPath);

    stdout.writeln('Created $outputZipPath');
  }

  Future<String> _zipDir(
      String zipPath, String flutterPackageName, String platform) async {
    final today = DateTime.now();
    String dateSlug =
        "${today.year.toString()}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}${today.hour.toString().padLeft(2, '0')}${today.minute.toString().padLeft(2, '0')}${today.second.toString().padLeft(2, '0')}";
    final internalTestingArtifactsWindowsZipBaseName =
        '${flutterPackageName}_${platform}_$dateSlug.zip';

    final outputZipPath =
        path.join(zipPath, internalTestingArtifactsWindowsZipBaseName);

    // Zip a directory to out.zip using the zipDirectory convenience method
    var encoder = ZipFileEncoder();
    encoder.create(outputZipPath);
    await encoder.addDirectory(fileSystem.directory(zipPath));
    // encoder.zipDirectory(internalTestingArtifactsWindowsDir,
    //     filename: internalTestingArtifactsWindowsZipBaseName);

    encoder.close();

    return outputZipPath;
  }

  String _createOutputZipPath(String flutterPackageName, String platform) {
    final today = DateTime.now();
    String dateSlug =
        "${today.year.toString()}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}${today.hour.toString().padLeft(2, '0')}${today.minute.toString().padLeft(2, '0')}${today.second.toString().padLeft(2, '0')}";
    final internalTestingArtifactsWindowsZipBaseName =
        '${flutterPackageName}_${platform}_$dateSlug.zip';
    return internalTestingArtifactsWindowsZipBaseName;
  }

  Future<void> _zipDirs(List<String> zipDirPaths, String outputZipPath) async {
    // Zip a directory to out.zip using the zipDirectory convenience method
    var encoder = ZipFileEncoder();
    encoder.create(outputZipPath);
    for (final p in zipDirPaths) {
      await encoder.addDirectory(fileSystem.directory(p));
    }

    // encoder.zipDirectory(internalTestingArtifactsWindowsDir,
    //     filename: internalTestingArtifactsWindowsZipBaseName);

    encoder.close();

    // return outputZipPath;
  }

  Future<void> _unzip(String zipFilePath, String outputPath) async {
    // Use an InputFileStream to access the zip file without storing it in memory.
    final inputStream = InputFileStream(zipFilePath);
// Decode the zip from the InputFileStream. The archive will have the contents of the
// zip, without having stored the data in memory.
    final archive = ZipDecoder().decodeBuffer(inputStream);
    extractArchiveToDisk(archive, outputPath);
    inputStream.close();
  }

  void _unzipSymlinks(String zipFilePath, String outputPath) {
    // unzip iris_artifact/iris_artifact.zip -d iris_artifact
    processManager.runSyncWithOutput([
      'ditto',
      '-x',
      '-k',
      zipFilePath,
      outputPath,
    ]);

    // Use an InputFileStream to access the zip file without storing it in memory.
//     final inputStream = InputFileStream(zipFilePath);
// // Decode the zip from the InputFileStream. The archive will have the contents of the
// // zip, without having stored the data in memory.
//     final archive = ZipDecoder().decodeBuffer(inputStream);
//     extractArchiveToDisk(archive, outputPath);
//     inputStream.close();
  }

  Future<String> _downloadAndUnzip(
      String zipFileUrl, String unzipOutputPath, bool isUnzipSymlinks) async {
    final zipDownloadPath = path.join(unzipOutputPath, 'zip_download_path');
    final zipDownloadDir = fileSystem.directory(zipDownloadPath);
    zipDownloadDir.createSync();

    final zipFileBaseName = Uri.parse(zipFileUrl).pathSegments.last;

    final fileDownloader = DefaultFileDownloader(_globalConfig);
    await fileDownloader.downloadFile(
      zipFileUrl,
      path.join(zipDownloadPath, zipFileBaseName),
    );

    if (isUnzipSymlinks) {
      _unzipSymlinks(
          path.join(zipDownloadPath, zipFileBaseName), zipDownloadPath);
    } else {
      _unzip(path.join(zipDownloadPath, zipFileBaseName), zipDownloadPath);
    }

    // fileSystem.file(path.join(zipDownloadPath, zipFileBaseName)).deleteSync();

    // iris_4.0.0_DCG_Mac_20220905_1020

    final unzipFilePath = zipDownloadDir
        .listSync()
        .firstWhere((element) => !element.absolute.path.endsWith('.zip'))
        .absolute
        .path;

    // _copyDirectory(fileSystem.directory(unzipFilePath),
    //     fileSystem.directory(unzipOutputPath));

    // fileSystem.directory(zipDownloadPath).deleteSync(recursive: true);

    return unzipFilePath;
  }

  void _runFlutterPackagesGet(String packagePath) {
    processManager.runSyncWithOutput(
      ['flutter', 'packages', 'get'],
      runInShell: true,
      workingDirectory: packagePath,
    );
  }

  void _runFlutterClean(String cleanPackagePath) {
    processManager.runSyncWithOutput(
      ['flutter', 'clean'],
      runInShell: true,
      workingDirectory: cleanPackagePath,
    );
  }

  void _outputUploadLog() {
    // build/internal_testing_artifacts/upload_result.txt
    final file = fileSystem.file(
        path.join(_workspace.absolute.path, 'example', 'upload_result.txt'));
    stdout.writeln(file.readAsStringSync());
    file.deleteSync();
  }

  void _copyDirectory(Directory source, Directory destination) {
    if (!destination.existsSync()) {
      destination.createSync(recursive: true);
    }
    source.listSync(recursive: false).forEach((var entity) {
      if (entity is Directory) {
        var newDirectory = fileSystem.directory(
            path.join(destination.absolute.path, path.basename(entity.path)));
        newDirectory.createSync();

        _copyDirectory(entity.absolute, newDirectory);
      } else if (entity is File) {
        entity
            .copySync(path.join(destination.path, path.basename(entity.path)));
      }
    });
  }

  void _flutterBuild(
    String workingDirectory,
    String platform, {
    List<String> extraArgs = const [],
  }) {
    // flutter build windows --dart-define TEST_APP_ID="$TEST_APP_ID" --dart-define TEST_TOKEN="$TEST_TOKEN" --dart-define TEST_CHANNEL_ID="$TEST_CHANNEL_ID"
    processManager.runSyncWithOutput(
      [
        'flutter',
        'build',
        platform,
        '--dart-define',
        'TEST_APP_ID=${_globalConfig.testAppId}',
        '--dart-define',
        'TEST_TOKEN=${_globalConfig.testToken}',
        '--dart-define',
        'TEST_CHANNEL_ID=${_globalConfig.testChannelId}',
        '--dart-define',
        'MUSIC_CENTER_APPID=${_globalConfig.musicCenterAppid}',
        ...extraArgs,
      ],
      runInShell: true,
      // includeParentEnvironment: false,
      workingDirectory: workingDirectory,
    );
  }

  void _buildIOSIpa(
    String workingDirectory,
    String flutterPackageName,
    String xcodeprojPath,
    String bundleIdentifier,
    String teamId,
    String profileName,
    String codeSignIdentity,
    bool automaticSigning,
    PListConfig pListConfig,
    Map<String, String> targetsRunners,
    String outputPath,
  ) {
    final plistFile = _createPList(
      pListConfig.applePackageName,
      pListConfig.profileName,
      path.join(workingDirectory, '${pListConfig.profileName}.plist'),
    );

    stdout.writeln(plistFile.absolute.path);
// flutter build ipa --dart-define TEST_APP_ID="$TEST_APP_ID" --dart-define TEST_TOKEN="$TEST_TOKEN" --dart-define TEST_CHANNEL_ID="$TEST_CHANNEL_ID" --export-options-plist $exportPList
    _updateCodeSigningSettings(
      path.join(workingDirectory, 'ios'),
      xcodeprojPath,
      bundleIdentifier,
      teamId,
      profileName,
      codeSignIdentity,
      automaticSigning,
      targetsRunners,
    );
    stdout.writeln('Building ipa ${plistFile.absolute.path}');
    _flutterBuild(
      workingDirectory,
      'ipa',
      extraArgs: ['--export-options-plist', plistFile.absolute.path],
    );

    final iosArtifactPath = path.join(workingDirectory, 'build', 'ios', 'ipa');

    fileSystem.directory(path.join(outputPath, profileName)).createSync();

    // ${PACKAGE_NAME}_example.ipa
    stdout.writeln('Copying ipa');
    fileSystem
        .file(path.join(iosArtifactPath, '${flutterPackageName}_example.ipa'))
        .copySync(path.join(
            outputPath, profileName, '${flutterPackageName}_example.ipa'));
    // _copyDirectory(
    //     fileSystem.directory(
    //         path.join(iosArtifactPath, '${flutterPackageName}_example.ipa')),
    //     fileSystem.directory(path.join(
    //         outputPath, profileName, '${flutterPackageName}_example.ipa')));

    _copyDirectory(
        fileSystem.directory(path.join(
          workingDirectory,
          'build',
          'ios',
          'archive',
          'Runner.xcarchive',
          'dSYMs',
        )),
        fileSystem.directory(path.join(outputPath, profileName)));
  }

  void _updateCodeSigningSettings(
    String workingDirectory,
    String xcodeprojPath,
    String bundleIdentifier,
    String teamId,
    String profileName,
    String codeSignIdentity,
    bool automaticSigning,
    Map<String, String> targetsRunners,
  ) {
    // fastlane run update_code_signing_settings use_automatic_signing:$(boolean "${automatic_signing}") path:"$EXAMPLE_PATH/ios/Runner.xcodeproj" bundle_identifier:"$bundle_identifier" team_id:"$team_id" profile_name:"$profile_name" code_sign_identity:"$code_sign_identity" targets:"$targets_runner"
    for (final target in targetsRunners.keys) {
      final bi = targetsRunners[target]!;
      processManager.runSyncWithOutput(
        [
          'fastlane',
          'run',
          'update_code_signing_settings',
          'use_automatic_signing:$automaticSigning',
          'path:$xcodeprojPath',
          'bundle_identifier:$bi',
          'team_id:$teamId',
          'profile_name:$profileName',
          'code_sign_identity:$codeSignIdentity',
          'targets:$target',
        ],
        runInShell: true,
        workingDirectory: workingDirectory,
      );
    }
  }

  void _installAppleCertificate({
    required String p12OutputPath,
    required String provisionOutputPath,
    required String keychainOutputPath,
    required String gpgProvisionName,
    required String gpgProvisionPwd,
    required String p12Base64,
    required String p12Pwd,
    required String keychainPwd,
  }) {
    final libPath = path.join(
        fileSystem
            .file(Platform.script.toFilePath(windows: Platform.isWindows))
            .parent
            .parent
            .absolute
            .path,
        'lib');
    final certPath = path.join(libPath, 'cert');

    processManager.runSyncWithOutput([
      'bash',
      path.join(certPath, 'decrypt_secret.sh'),
      provisionOutputPath,
      path.join(certPath, gpgProvisionName),
      gpgProvisionPwd
    ]);

    processManager.runSyncWithOutput([
      'bash',
      path.join(certPath, 'install_apple_certificate.sh'),
      p12Base64,
      p12Pwd,
      p12OutputPath,
      provisionOutputPath,
      keychainOutputPath,
      keychainPwd,
    ]);
  }
}
