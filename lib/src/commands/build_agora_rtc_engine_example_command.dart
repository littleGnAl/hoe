import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:file/file.dart';
import 'package:hoe/src/base/base_command.dart';
import 'package:hoe/src/base/process_manager_ext.dart';
import 'package:hoe/src/common/default_file_downloader.dart';
import 'package:hoe/src/common/global_config.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';
import 'package:archive/archive.dart';

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
    argParser.addOption('iris-windows-download-url');
    argParser.addFlag('process-build');
    argParser.addOption('apple-package-name');
    argParser.addOption('flutter-package-name');
    argParser.addOption('project-dir');
    argParser.addOption('artifacts-output-dir');

    // _workspace = fileSystem.currentDirectory;
  }

  late final Directory _workspace;

  @override
  String get description => 'Build agora_rtc_engine example';

  @override
  String get name => 'build-agora-flutter-example';

  @override
  Future<void> run() async {
    final String platforms = argResults?['platforms'] ?? '';
    final bool isSetupDev = argResults?['setup-local-dev'] ?? false;
    final String localIrisPath = argResults?['local-iris-path'] ?? '';
    final String irisWindowsDownloadUrl =
        argResults?['iris-windows-download-url'] ?? '';
    final bool isProcessBuild = argResults?['process-build'] ?? false;
    final String applePackageName = argResults?['apple-package-name'] ?? '';
    final String flutterPackageName = argResults?['flutter-package-name'] ?? '';
    final String projectDir = argResults?['project-dir'] ?? '';
    final String artifactsOutputDir = argResults?['artifacts-output-dir'] ?? '';

    _workspace = fileSystem.directory(projectDir);

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
            await _setupIOSDev(flutterPackageName, localIrisPath);
          }

          if (isProcessBuild) {
            await _processBuildIOS(
              applePackageName,
              flutterPackageName,
              originalScriptsPath,
            );
          }
          break;
        case 'macos':
          if (isSetupDev) {
            await _setupMacOSDev(localIrisPath);
          }

          if (isProcessBuild) {
            await _processBuildMacOS(flutterPackageName, originalScriptsPath);
          }
          break;
        case 'android':
          if (isSetupDev) {
            await _setupAndroidDev(localIrisPath);
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
            await _processBuildWindows(flutterPackageName, originalScriptsPath);
          }
          break;

        default:
          throw Exception('Unsupported platform: $platform');
      }
    }

    // if (isProcessBuild) {
    //   _outputUploadLog();
    // }
  }

  Future<void> _setupAndroidDev(String localIrisPath) async {
    final androidModulePath =
        path.join(fileSystem.currentDirectory.absolute.path, 'android');
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
    final agoraWrapperJarPath = path.join(irisLibsPath, 'AgoraRtcWrapper.jar');
    final agoraWrapperJar = fileSystem.file(agoraWrapperJarPath);
    if (!agoraWrapperJar.existsSync()) {
      processManager.runSyncWithOutput(
        ['bash', 'scripts/build-iris-android.sh', localIrisPath, 'Debug'],
        runInShell: true,
        workingDirectory: _workspace.absolute.path,
      );
    }
  }

  Future<void> _setupIOSDev(
      String flutterPackageName, String localIrisPath) async {
    final iosModulePath = path.join(_workspace.absolute.path, 'ios');
    final iosModuleDir = fileSystem.directory(iosModulePath);

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

    final podspecFilePath =
        path.join(iosModulePath, '$flutterPackageName.podspec');
    _createAgoraRtcWrapperPodSpecFile(iosModuleDir, isXCFramework: true);
    _modifyPodSpecFile(podspecFilePath, true);
    _modifyPodFile(
      path.join(_workspace.absolute.path, 'example', 'ios', 'Podfile'),
      true,
    );
    _modifyPodFile(
      path.join(
          _workspace.absolute.path, 'integration_test_app', 'ios', 'Podfile'),
      true,
    );

    _runFlutterPackagesGet(path.join(_workspace.absolute.path, 'example'));
    _runPodInstall(path.join(_workspace.absolute.path, 'example', 'ios'));
    _runFlutterPackagesGet(
        path.join(_workspace.absolute.path, 'integration_test_app'));
    _runPodInstall(
        path.join(_workspace.absolute.path, 'integration_test_app', 'ios'));
  }

  Future<void> _setupMacOSDev(String localIrisPath) async {
    final iosModulePath = path.join(_workspace.absolute.path, 'macos');
    final iosModuleDir = fileSystem.directory(iosModulePath);

    final irisFrameworkPath =
        path.join(iosModulePath, 'AgoraRtcWrapper.framework');
    final irisFramework = fileSystem.directory(irisFrameworkPath);
    if (!irisFramework.existsSync()) {
      processManager.runSyncWithOutput(
        ['bash', 'scripts/build-iris-macos.sh', 'Release', localIrisPath],
        runInShell: true,
        workingDirectory: _workspace.absolute.path,
      );
    }

    final podspecFilePath =
        path.join(iosModulePath, 'agora_rtc_engine.podspec');
    _createAgoraRtcWrapperPodSpecFile(iosModuleDir);
    _modifyPodSpecFile(podspecFilePath, true);
    _modifyPodFile(
      path.join(_workspace.absolute.path, 'example', 'macos', 'Podfile'),
      true,
    );
    _modifyPodFile(
      path.join(
          _workspace.absolute.path, 'integration_test_app', 'macos', 'Podfile'),
      true,
    );

    _runFlutterPackagesGet(path.join(_workspace.absolute.path, 'example'));
    _runPodInstall(path.join(_workspace.absolute.path, 'example', 'macos'));
    _runFlutterPackagesGet(
        path.join(_workspace.absolute.path, 'integration_test_app'));
    _runPodInstall(
        path.join(_workspace.absolute.path, 'integration_test_app', 'macos'));
  }

  Future<void> _setupWindowsDev(
      String irisWindowsDownloadUrl, String originalScriptsPath) async {
    final downloadWindowsScriptPath =
        path.join(originalScriptsPath, 'download-iris-windows.sh');
    final windowsModulePath = path.join(
      _workspace.absolute.path,
      'windows',
    );

// iris_windows
    final irisWindowsPath = path.join(windowsModulePath, 'iris_windows');
    final irisWindowsDir = fileSystem.directory(irisWindowsPath);
    final irisWindowsTmpDir =
        fileSystem.directory(path.join(irisWindowsPath, 'tmp'));
    final irisWindowsIrisSDKDir = fileSystem.directory(
        path.join(irisWindowsPath, 'Agora_Native_SDK_for_Windows_IRIS'));
    if (irisWindowsDir.existsSync()) {
      irisWindowsDir.deleteSync(recursive: true);
    }

    irisWindowsDir.createSync();
    irisWindowsIrisSDKDir.createSync();
    irisWindowsTmpDir.createSync();

    final irisWindowsZipFile = fileSystem
        .file(path.join(irisWindowsDir.absolute.path, 'iris_windows.zip'));
    final fileDownloader = DefaultFileDownloader();
    await fileDownloader.downloadFile(
      irisWindowsDownloadUrl,
      irisWindowsZipFile.absolute.path,
    );

// Use an InputFileStream to access the zip file without storing it in memory.
    final inputStream = InputFileStream(irisWindowsZipFile.absolute.path);
// Decode the zip from the InputFileStream. The archive will have the contents of the
// zip, without having stored the data in memory.
    final archive = ZipDecoder().decodeBuffer(inputStream);
    extractArchiveToDisk(archive, irisWindowsTmpDir.absolute.path);
    inputStream.close();

    inputStream.close();

    // final tmpDir = fileSystem.directory(path.join(irisWindowsPath, 'tmp'));
    final extractPath = irisWindowsTmpDir.listSync()[0].path;
    _copyDirectory(fileSystem.directory(extractPath), irisWindowsIrisSDKDir);

    irisWindowsZipFile.deleteSync(recursive: true);
    irisWindowsTmpDir.deleteSync(recursive: true);

    final thirdPartyDir =
        fileSystem.directory(path.join(windowsModulePath, 'third_party'));
    if (thirdPartyDir.existsSync()) {
      thirdPartyDir.deleteSync(recursive: true);
    }

    thirdPartyDir.createSync();
    final thirdPartyIrisDir =
        fileSystem.directory(path.join(thirdPartyDir.absolute.path, 'iris'));
    thirdPartyIrisDir.createSync();

    _copyDirectory(irisWindowsDir, thirdPartyIrisDir);
    irisWindowsDir.deleteSync(recursive: true);

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
    for (final line in lines) {
      final trimLine = line.trim();

      if (forDev) {
        if (trimLine.startsWith('s.dependency \'AgoraIrisRTC')) {
          newOutput.writeln('  # $line');
          newOutput.writeln('  s.dependency \'AgoraRtcWrapper\'');
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
  ) async {
    _runFlutterClean(path.join(_workspace.absolute.path, 'example'));
    _runFlutterPackagesGet(path.join(_workspace.absolute.path, 'example'));
    final buildScriptPath = path.join(
      originalScriptsPath,
      'build-internal-testing-ios.sh',
    );

    final plistDirPath =
        path.join(_workspace.absolute.path, 'example', 'ios', 'plists');
    final plistDir = fileSystem.directory(plistDirPath);
    if (plistDir.existsSync()) {
      plistDir.deleteSync(recursive: true);
    }
    plistDir.createSync();

    List<File> plistFiles = [];

    plistFiles.add(_createPList(
      '${applePackageName}Test',
      'AgoraTest2020',
      path.join(plistDirPath, '${flutterPackageName}_test.plist'),
    ));
    plistFiles.add(_createPList(
      '${applePackageName}Lab',
      'AgoraLab2020',
      path.join(plistDirPath, '${flutterPackageName}_lab.plist'),
    ));
    plistFiles.add(_createPList(
      '${applePackageName}QA',
      'AgoraQA2021',
      path.join(plistDirPath, '${flutterPackageName}_qa.plist'),
    ));

    processManager.runSyncWithOutput(
      [
        'bash',
        buildScriptPath,
        flutterPackageName,
        '${applePackageName}Test',
        '${applePackageName}Lab',
        '${applePackageName}QA',
        applePackageName,
      ],
      runInShell: true,
      workingDirectory: _workspace.absolute.path,
    );

    for (final f in plistFiles) {
      f.deleteSync(recursive: true);
    }
  }

  /// bash $MY_PATH/build-internal-testing-macos.sh agora_rtc_engine_example
  Future<void> _processBuildMacOS(
    String flutterPackageName,
    String originalScriptsPath,
  ) async {
    _runFlutterClean(path.join(_workspace.absolute.path, 'example'));
    _runFlutterPackagesGet(path.join(_workspace.absolute.path, 'example'));
    final buildScriptPath = path.join(
      originalScriptsPath,
      'build-internal-testing-macos.sh',
    );
    processManager.runSyncWithOutput(
      ['bash', buildScriptPath, flutterPackageName],
      runInShell: true,
      workingDirectory: _workspace.absolute.path,
    );
  }

  Future<void> _processBuildWindows(
    String flutterPackageName,
    String originalScriptsPath,
  ) async {
    _runFlutterClean(path.join(_workspace.absolute.path, 'example'));
    _runFlutterPackagesGet(path.join(_workspace.absolute.path, 'example'));
    // final buildScriptPath = path.join(
    //   originalScriptsPath,
    //   'build-internal-testing-windows.sh',
    // );
    // processManager.runSyncWithOutput(
    //   ['bash', buildScriptPath],
    //   runInShell: true,
    //   workingDirectory: _workspace.absolute.path,
    // );

    _flutterBuild(_workspace.absolute.path, 'windows');

    final internalTestingArtifactsDir = fileSystem.directory(
      path.join(
        _workspace.absolute.path,
        'example',
        'build',
        'internal_testing_artifacts',
      ),
    );

    final internalTestingArtifactsWindowsDir = fileSystem.directory(
      path.join(internalTestingArtifactsDir.absolute.path, 'windows'),
    );

// dt=$(date '+%Y%m%d%H%M%S')
    final today = DateTime.now();
    String dateSlug =
        "${today.year.toString()}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}${today.hour.toString().padLeft(2, '0')}${today.minute.toString().padLeft(2, '0')}${today.second.toString().padLeft(2, '0')}";
    final internalTestingArtifactsWindowsZipBaseName =
        '${flutterPackageName}_windows_$dateSlug.zip';

    // Zip a directory to out.zip using the zipDirectory convenience method
    var encoder = ZipFileEncoder();
    encoder.create(path.join(internalTestingArtifactsDir.absolute.path,
        internalTestingArtifactsWindowsZipBaseName));
    await encoder.addDirectory(internalTestingArtifactsWindowsDir);
    // encoder.zipDirectory(internalTestingArtifactsWindowsDir,
    //     filename: internalTestingArtifactsWindowsZipBaseName);

    encoder.close();

    // processManager.runSyncWithOutput(
    //   [
    //     'bash',
    //     path.join(originalScriptsPath, 'upload-jenkins.sh'),
    //     path.join(
    //       internalTestingArtifactsDir.absolute.path,
    //       internalTestingArtifactsWindowsZipBaseName,
    //     )
    //   ],
    //   runInShell: true,
    //   includeParentEnvironment: true,
    //   workingDirectory: _workspace.absolute.path,
    // );

    // // notify-wecom.sh
    // processManager.runSyncWithOutput(
    //   [
    //     'bash',
    //     path.join(originalScriptsPath, 'notify-wecom.sh'),
    //     internalTestingArtifactsWindowsZipBaseName
    //   ],
    //   runInShell: true,
    //   includeParentEnvironment: true,
    //   workingDirectory: _workspace.absolute.path,
    // );
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
    String platform,
  ) {
    // flutter build windows --dart-define TEST_APP_ID="$TEST_APP_ID" --dart-define TEST_TOKEN="$TEST_TOKEN" --dart-define TEST_CHANNEL_ID="$TEST_CHANNEL_ID"
    final globalConfig = GlobalConfig();
    processManager.runSyncWithOutput(
      [
        'flutter',
        'build',
        platform,
        '--dart-define',
        'TEST_APP_ID="${globalConfig.testAppId}"',
        '--dart-define',
        'TEST_TOKEN="${globalConfig.testToken}"',
        '--dart-define',
        'TEST_CHANNEL_ID="${globalConfig.testChannelId}"'
      ],
      runInShell: true,
      // includeParentEnvironment: false,
      workingDirectory: workingDirectory,
    );
  }
}
