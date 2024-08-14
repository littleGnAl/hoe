import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:file/file.dart';
import 'package:hoe/src/base/base_command.dart';
import 'package:hoe/src/base/process_manager_ext.dart';
import 'package:hoe/src/common/default_file_downloader.dart';
import 'package:hoe/src/common/global_config.dart';
import 'package:hoe/src/common/ios_plist_config.dart';
import 'package:hoe/src/common/path_ext.dart';
import 'package:hoe/src/common/pubspec.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';

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
    argParser.addOption('iris-windows-cdn-url');
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
        argResults?['iris-windows-cdn-url'] ?? '';
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

        case 'web':
          if (isProcessBuild) {
            await _processBuildWeb(flutterPackageName, artifactsOutputDir);
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
      final zipDownloadPath = await downloadAndUnzip(
        processManager,
        fileSystem,
        _globalConfig,
        irisAndroidCDNUrl,
        androidModulePath,
        isUnzipSymlinks: false,
      );

      final unzipFilePath = getUnzipDir(
          fileSystem, irisAndroidCDNUrl, zipDownloadPath, 'DCG', 'Android');

      copyDirectory(
          fileSystem,
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

        final libIrisDebuggerSOPath = path.join(unzipFilePath,
            'ALL_ARCHITECTURE', 'Release', abi, 'libIrisDebugger.so');
        if (fileSystem.file(libIrisDebuggerSOPath).existsSync()) {
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

      final unzipRtmDirPath = getUnzipDir(
          fileSystem, irisAndroidCDNUrl, zipDownloadPath, 'RTM', 'Android');
      if (fileSystem.directory(unzipRtmDirPath).existsSync()) {
        for (final abi in abis) {
          fileSystem
              .file(path.join(unzipRtmDirPath, 'ALL_ARCHITECTURE', 'Release',
                  abi, 'libAgoraRtmWrapper.so'))
              .copySync(path.join(
                  androidModulePath, 'libs', abi, 'libAgoraRtmWrapper.so'));
        }
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
      final zipDownloadPath = await downloadAndUnzip(
        processManager,
        fileSystem,
        _globalConfig,
        irisIOSCDNUrl,
        iosModulePath,
        isUnzipSymlinks: true,
      );

      final unzipFilePath =
          getUnzipDir(fileSystem, irisIOSCDNUrl, zipDownloadPath, 'DCG', 'iOS');

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
        path.join(iosModulePath, 'libs')
      ]);

      final irisDebuggerXCframeworkPath = path.join(
        unzipFilePath,
        'ALL_ARCHITECTURE',
        'Release',
        'Release',
        'IrisDebugger.xcframework',
      );

      if (fileSystem.directory(irisDebuggerXCframeworkPath).existsSync()) {
        processManager.runSyncWithOutput([
          'cp',
          '-RP',
          irisDebuggerXCframeworkPath,
          path.join(
              _workspace.absolute.path, 'test_shard', 'iris_tester', 'ios'),
        ]);
      }

      final unzipRtmPath =
          getUnzipDir(fileSystem, irisIOSCDNUrl, zipDownloadPath, 'RTM', 'iOS');
      if (fileSystem.directory(unzipRtmPath).existsSync()) {
        processManager.runSyncWithOutput([
          'cp',
          '-RP',
          path.join(
            unzipRtmPath,
            'ALL_ARCHITECTURE',
            'Release',
            'AgoraRtmWrapper.xcframework',
          ),
          path.join(iosModulePath, 'libs')
        ]);
      }
    }

    fileSystem.file(path.join(iosModulePath, '.plugin_dev')).createSync();

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
      final zipDownloadPath = await downloadAndUnzip(
        processManager,
        fileSystem,
        _globalConfig,
        irisMacosCDNUrl,
        macosModulePath,
        isUnzipSymlinks: true,
      );
      final unzipFilePath = getUnzipDir(
          fileSystem, irisMacosCDNUrl, zipDownloadPath, 'DCG', 'MAC');

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
        path.join(macosModulePath, 'libs')
      ]);

      final irisDebuggerFrameworkPath = path.join(
        unzipFilePath,
        'MAC',
        'Release',
        'Release',
        'IrisDebugger.framework',
      );

      if (fileSystem.directory(irisDebuggerFrameworkPath).existsSync()) {
        processManager.runSyncWithOutput([
          'cp',
          '-RP',
          irisDebuggerFrameworkPath,
          path.join(
              _workspace.absolute.path, 'test_shard', 'iris_tester', 'macos'),
        ]);
      }

      final unzipRtmPath = getUnzipDir(
          fileSystem, irisMacosCDNUrl, zipDownloadPath, 'RTM', 'MAC');
      if (fileSystem.directory(unzipRtmPath).existsSync()) {
        processManager.runSyncWithOutput([
          'cp',
          '-RP',
          path.join(
            unzipRtmPath,
            'MAC',
            'Release',
            'AgoraRtmWrapper.framework',
          ),
          path.join(macosModulePath, 'libs')
        ]);
      }
    }

    fileSystem.file(path.join(macosModulePath, '.plugin_dev')).createSync();

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

      final unzipFilePath = await downloadAndUnzip(
        processManager,
        fileSystem,
        _globalConfig,
        irisWindowsDownloadUrl,
        windowsModulePath,
        isUnzipSymlinks: false,
      );

      copyDirectory(
          fileSystem,
          fileSystem.directory(path.join(
            windowsModulePath,
            'zip_download_path',
          )),
          thirdPartyIrisDir);

      // Release

      final irisDebuggerDllPath = path.join(
          unzipFilePath, 'x64', 'Release', 'Release', 'IrisDebugger.dll');
      if (fileSystem.file(irisDebuggerDllPath).existsSync()) {
        fileSystem.file(irisDebuggerDllPath).copySync(
              path.join(
                _workspace.absolute.path,
                'test_shard',
                'iris_tester',
                'windows',
                'IrisDebugger.dll',
              ),
            );
      }
    }

    final devFilePath = path.join(windowsModulePath, '.plugin_dev');
    final devFile = fileSystem.file(devFilePath);
    if (!devFile.existsSync()) {
      devFile.createSync();
    }
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
    copyDirectory(
        fileSystem,
        fileSystem.directory(
            path.join(macosArtifactPath, '${flutterPackageName}_example.app')),
        fileSystem.directory(
            path.join(archiveDirPath, '${flutterPackageName}_example.app')));

    fileSystem.directory(path.join(archiveDirPath, 'dSYMs')).createSync();
    final macosPluginDsymsDir = fileSystem.directory(path.join(
        macosArtifactPath,
        flutterPackageName,
        '$flutterPackageName.framework.dSYM'));
    copyDirectory(
        fileSystem,
        macosPluginDsymsDir,
        fileSystem.directory(path.join(
            archiveDirPath, 'dSYMs', '$flutterPackageName.framework.dSYM')));

    final macosAppDsymsDir = fileSystem.directory(
        path.join(macosArtifactPath, '${flutterPackageName}_example.app.dSYM'));
    copyDirectory(
        fileSystem,
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

    copyDirectory(
        fileSystem,
        fileSystem.directory(path.join(_workspace.absolute.path, 'example',
            'build', 'windows', 'x64', 'runner', 'Release')),
        fileSystem.directory(archiveDirPath));

    final pluginsDir = fileSystem.directory(path.join(
        _workspace.absolute.path, 'example', 'build', 'windows', 'plugins'));
    for (final pluginEntity in pluginsDir.listSync()) {
      final pluginReleaseDir = fileSystem
          .directory(path.join(pluginEntity.absolute.path, 'Release'));
      if (pluginReleaseDir.existsSync()) {
        for (final pluginArtifactEntity in pluginReleaseDir.listSync()) {
          if (pluginArtifactEntity.absolute.path.endsWith('.pdb')) {
            final dstFilePath =
                path.join(archiveDirPath, pluginArtifactEntity.basename);
            if (fileSystem.file(dstFilePath).existsSync()) {
              break;
            }

            stdout.writeln(
                'Copy ${pluginArtifactEntity.basename} to $dstFilePath');
            fileSystem
                .file(pluginArtifactEntity.absolute.path)
                .copySync(dstFilePath);

            break;
          }
        }
      }
    }

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
    final pubspecFilePath = path.join(_workspace.absolute.path, 'pubspec.yaml');
    final pubspec =
        Pubspec.load(fileSystem.file(pubspecFilePath).readAsStringSync());

    final today = DateTime.now();
    String dateSlug =
        "${today.year.toString()}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}${today.hour.toString().padLeft(2, '0')}${today.minute.toString().padLeft(2, '0')}${today.second.toString().padLeft(2, '0')}";
    final internalTestingArtifactsWindowsZipBaseName =
        '${flutterPackageName}_${platform}_${pubspec.version}_$dateSlug.zip';
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
        'INTERNAL_TESTING=true',
        '--dart-define',
        'MUSIC_CENTER_APPID=${_globalConfig.musicCenterAppid}',
        '--dart-define',
        'RTM_APP_ID=${_globalConfig.testAppId}',
        '--dart-define',
        'RTM_TOKEN=${_globalConfig.testAppId}',
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

    copyDirectory(
        fileSystem,
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

  Future<void> _processBuildWeb(
    String flutterPackageName,
    String artifactsOutputDirPath,
  ) async {
    _runFlutterClean(path.join(_workspace.absolute.path, 'example'));
    _runFlutterPackagesGet(path.join(_workspace.absolute.path, 'example'));

    final archiveDirPath =
        _createArchiveOutputDir(_workspace.absolute.path, 'web');

    _flutterBuild(path.join(_workspace.absolute.path, 'example'), 'web');

    copyDirectory(
        fileSystem,
        fileSystem.directory(
            path.join(_workspace.absolute.path, 'example', 'build', 'web')),
        fileSystem.directory(archiveDirPath));

    final artifactsOutputDir = fileSystem.directory(artifactsOutputDirPath);
    if (!artifactsOutputDir.existsSync()) {
      artifactsOutputDir.createSync(recursive: true);
    }

    final outputZipPath = path.join(artifactsOutputDirPath,
        _createOutputZipPath(flutterPackageName, 'web'));

    await _zipDirs([archiveDirPath], outputZipPath);

    stdout.writeln('Created $outputZipPath');
  }
}
