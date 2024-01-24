import 'package:cli_util/cli_logging.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:hoe/src/commands/update_agora_rtc_engine_native_versions_command.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

void main() {
  late UpdateAgoraRtcEngineNativeVersionsCommand command;

  late FileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    final processManager = const LocalProcessManager();

    final logger = Logger.standard();

    command = UpdateAgoraRtcEngineNativeVersionsCommand(
      fileSystem: fileSystem,
      processManager: processManager,
      logger: logger,
    );
  });

  group('findNativeAndroidMaven', () {
    test('findNativeAndroidMaven', () {
      final nativeSdkDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
Maven：
implementation 'io.agora.rtc:full-sdk:4.1.0-1'
implementation 'io.agora.rtc:agora-special-voice:4.0.1.9'
implementation 'io.agora.rtc:agora-special-full:4.0.1.9'
implementation 'io.agora.rtc:full-screen-sharing:4.0.1.9'
Cocoapods：
pod 'AgoraAudio_Special_iOS', '4.0.1.9'
pod 'AgoraRtcEngine_Special_iOS', '4.0.1.9'
''';

      final result =
          command.findNativeAndroidMaven(nativeSdkDependenciesContent);
      expect(result.mavenOrCocoaPods[0],
          "implementation 'io.agora.rtc:full-sdk:4.1.0-1'");
      expect(result.mavenOrCocoaPods[1],
          "implementation 'io.agora.rtc:agora-special-full:4.0.1.9'");
      expect(result.mavenOrCocoaPods[2],
          "implementation 'io.agora.rtc:full-screen-sharing:4.0.1.9'");
      expect(result.mavenOrCocoaPods[3],
          "implementation 'io.agora.rtc:agora-special-voice:4.0.1.9'");
    });

    test('findNativeAndroidMaven with audio only', () {
      final nativeSdkDependenciesContent = '''
implementation 'io.agora.rtc:voice-sdk:4.2.2'
pod 'AgoraAudio_iOS', '4.2.2'
''';

      final result =
          command.findNativeAndroidMaven(nativeSdkDependenciesContent);
      expect(result.mavenOrCocoaPods[0],
          "implementation 'io.agora.rtc:voice-sdk:4.2.2'");
    });

    test('findNativeAndroidMaven with mini video', () {
      final nativeSdkDependenciesContent = '''
implementation 'io.agora.rtc:agora-special-full:4.1.1.13.MINI.VIDEO'
pod 'AgoraRtcEngine_Special_iOS', '4.1.1.13.MINI.VIDEO'
''';

      final result =
          command.findNativeAndroidMaven(nativeSdkDependenciesContent);
      expect(result.mavenOrCocoaPods[0],
          "implementation 'io.agora.rtc:agora-special-full:4.1.1.13.MINI.VIDEO'");
    });

    test('findNativeAndroidMaven with single line input', () {
      final nativeSdkDependenciesContent =
          "implementation 'io.agora.rtc:agora-special-full:4.0.0.132.1'  implementation 'io.agora.rtc:full-screen-sharing:4.0.0.132.1'  pod 'AgoraRtcEngine_Special_iOS', '4.0.0.132.1'";

      final result =
          command.findNativeAndroidMaven(nativeSdkDependenciesContent);
      expect(result.mavenOrCocoaPods[0],
          "implementation 'io.agora.rtc:agora-special-full:4.0.0.132.1'");
      expect(result.mavenOrCocoaPods[1],
          "implementation 'io.agora.rtc:full-screen-sharing:4.0.0.132.1'");
    });

    test('findNativeAndroidMaven with single line input with *preview', () {
      final nativeSdkDependenciesContent =
          "implementation 'io.agora.rtc:agora-full-preview:4.2.0-dev.16'  implementation 'io.agora.rtc:full-screen-sharing-special:4.2.0-dev.16'  pod 'AgoraRtcEngine_Special_iOS', '4.0.0.132.1'";

      final result =
          command.findNativeAndroidMaven(nativeSdkDependenciesContent);
      expect(result.mavenOrCocoaPods[0],
          "implementation 'io.agora.rtc:agora-full-preview:4.2.0-dev.16'");
      expect(result.mavenOrCocoaPods[1],
          "implementation 'io.agora.rtc:full-screen-sharing-special:4.2.0-dev.16'");
    });
  });

  group('findNativeIOSPod', () {
    test('findNativeIOSPod', () {
      final nativeSdkDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
Maven：
implementation 'io.agora.rtc:full-sdk:4.1.0-1'
implementation 'io.agora.rtc:agora-special-voice:4.0.1.9'
implementation 'io.agora.rtc:agora-special-full:4.0.1.9'
implementation 'io.agora.rtc:full-screen-sharing:4.0.1.9'
Cocoapods：
pod 'AgoraRtcEngine_iOS', '4.1.0'
pod 'AgoraAudio_Special_iOS', '4.0.1.9'
pod 'AgoraRtcEngine_Special_iOS', '4.0.1.9'
''';

      final result = command.findNativeIOSPod(nativeSdkDependenciesContent);
      expect(result.mavenOrCocoaPods[0], "pod 'AgoraRtcEngine_iOS', '4.1.0'");
      expect(result.mavenOrCocoaPods[1],
          "pod 'AgoraRtcEngine_Special_iOS', '4.0.1.9'");
      expect(result.mavenOrCocoaPods[2],
          "pod 'AgoraAudio_Special_iOS', '4.0.1.9'");
    });

    test('findNativeIOSPod with audio only', () {
      final nativeSdkDependenciesContent = '''
implementation 'io.agora.rtc:voice-sdk:4.2.2'
pod 'AgoraAudio_iOS', '4.2.2'
''';

      final result = command.findNativeIOSPod(nativeSdkDependenciesContent);
      expect(result.mavenOrCocoaPods[0], "pod 'AgoraAudio_iOS', '4.2.2'");
    });

    test('findNativeIOSPod with mini video', () {
      final nativeSdkDependenciesContent = '''
implementation 'io.agora.rtc:agora-special-full:4.1.1.13.MINI.VIDEO'
pod 'AgoraRtcEngine_Special_iOS', '4.1.1.13.MINI.VIDEO'
''';

      final result = command.findNativeIOSPod(nativeSdkDependenciesContent);
      expect(result.mavenOrCocoaPods[0],
          "pod 'AgoraRtcEngine_Special_iOS', '4.1.1.13.MINI.VIDEO'");
    });

    test('findNativeIOSPod with single line input', () {
      final nativeSdkDependenciesContent =
          "implementation 'io.agora.rtc:agora-special-full:4.0.0.132.1'  implementation 'io.agora.rtc:full-screen-sharing:4.0.0.132.1'  pod 'AgoraRtcEngine_Special_iOS', '4.0.0.132.1'";

      final result = command.findNativeIOSPod(nativeSdkDependenciesContent);
      expect(result.mavenOrCocoaPods[0],
          "pod 'AgoraRtcEngine_Special_iOS', '4.0.0.132.1'");
    });

    test('findNativeIOSPod with single line input with *preview', () {
      final nativeSdkDependenciesContent =
          "implementation 'io.agora.rtc:agora-special-full:4.0.0.132.1'  implementation 'io.agora.rtc:full-screen-sharing:4.0.0.132.1'  pod 'AgoraRtcEngine_iOS_Preview', '4.2.0-dev.16'";

      final result = command.findNativeIOSPod(nativeSdkDependenciesContent);
      expect(result.mavenOrCocoaPods[0],
          "pod 'AgoraRtcEngine_iOS_Preview', '4.2.0-dev.16'");
    });
  });

  group('findNativeMacosPod', () {
    test('findNativeMacosPod', () {
      final nativeSdkDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
Maven：
implementation 'io.agora.rtc:full-sdk:4.1.0-1'
implementation 'io.agora.rtc:agora-special-voice:4.0.1.9'
implementation 'io.agora.rtc:agora-special-full:4.0.1.9'
implementation 'io.agora.rtc:full-screen-sharing:4.0.1.9'
Cocoapods：
pod 'AgoraRtcEngine_iOS', '4.1.0'
pod 'AgoraAudio_Special_iOS', '4.0.1.9'
pod 'AgoraRtcEngine_Special_iOS', '4.0.1.9'
pod 'AgoraRtcEngine_macOS', '4.1.0'
pod 'AgoraRtcEngine_Special_macOS', '4.1.1.1'
''';

      final result = command.findNativeMacosPod(nativeSdkDependenciesContent);
      expect(result.mavenOrCocoaPods[0], "pod 'AgoraRtcEngine_macOS', '4.1.0'");
      expect(result.mavenOrCocoaPods[1],
          "pod 'AgoraRtcEngine_Special_macOS', '4.1.1.1'");
    });

    test('findNativeMacosPod with single line input with *preview', () {
      final nativeSdkDependenciesContent =
          "implementation 'io.agora.rtc:agora-special-full:4.0.0.132.1'  implementation 'io.agora.rtc:full-screen-sharing:4.0.0.132.1'  pod 'AgoraRtcEngine_macOS_Preview', '4.2.0-dev.16'";

      final result = command.findNativeMacosPod(nativeSdkDependenciesContent);
      expect(result.mavenOrCocoaPods[0],
          "pod 'AgoraRtcEngine_macOS_Preview', '4.2.0-dev.16'");
    });
  });

  test('findNativeWindowsCDN', () {
    final nativeSdkDependenciesContent = '''
CDN：
https://download.agora.io/sdk/release/Agora_Native_SDK_for_iOS_rel.v4.0.1.9_62663_VOICE_20230308_1735_257723.zip
https://download.agora.io/sdk/release/Agora_Native_SDK_for_iOS_rel.v4.0.1.9_62662_FULL_20230308_1737_257722.zip
https://download.agora.io/sdk/release/Agora_Native_SDK_for_Windows_rel.v4.0.1.9_19521_FULL_20230308_1749_257724.zip
https://download.agora.io/sdk/release/Agora_Native_SDK_for_Android_rel.v4.0.1.9_47325_VOICE_20230308_1731_257719.zip
https://download.agora.io/sdk/release/Agora_Native_SDK_for_Android_rel.v4.0.1.9_47324_FULL_20230308_1740_257718.zip
Maven：
implementation 'io.agora.rtc:agora-special-voice:4.0.1.9'
implementation 'io.agora.rtc:agora-special-full:4.0.1.9'
implementation 'io.agora.rtc:full-screen-sharing:4.0.1.9'
Cocoapods：
pod 'AgoraAudio_Special_iOS', '4.0.1.9'
pod 'AgoraRtcEngine_Special_iOS', '4.0.1.9'
''';

    final result = command.findNativeWindowsCDN(nativeSdkDependenciesContent);
    expect(result.cdn,
        'https://download.agora.io/sdk/release/Agora_Native_SDK_for_Windows_rel.v4.0.1.9_19521_FULL_20230308_1749_257724.zip');
  });

  test('findNativeWindowsCDN without cdn info', () {
    final nativeSdkDependenciesContent = '''
CDN：
Maven：
implementation 'io.agora.rtc:agora-special-voice:4.0.1.9'
implementation 'io.agora.rtc:agora-special-full:4.0.1.9'
implementation 'io.agora.rtc:full-screen-sharing:4.0.1.9'
Cocoapods：
pod 'AgoraAudio_Special_iOS', '4.0.1.9'
pod 'AgoraRtcEngine_Special_iOS', '4.0.1.9'
''';

    final result = command.findNativeWindowsCDN(nativeSdkDependenciesContent);
    expect(result.cdn, '');
  });

  test('findIrisAndroidMaven', () {
    final irisDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_Android_Video_20230312_1116_Dummy text.zip
CDN:
https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_Android_Video_20230312_1116.zip
Maven:
implementation 'io.agora.rtc:iris-rtc:4.1.1.205-build.2'
''';

    final result = command.findIrisAndroidMaven(irisDependenciesContent);
    expect(result.cdn,
        'https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_Android_Video_20230312_1116.zip');
    expect(result.mavenOrCocoaPods[0],
        'implementation \'io.agora.rtc:iris-rtc:4.1.1.205-build.2\'');
  });

  test('findIrisAndroidMaven with empty content', () {
    final irisDependenciesContent = '';

    final result = command.findIrisMacosPod(irisDependenciesContent);
    expect(result.cdn, '');
    expect(result.mavenOrCocoaPods.length, 0);
  });

  test('findIrisIOSPod', () {
    final irisDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_Android_Video_20230312_1116_Dummy text.zip
CDN:
https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_iOS_Video_20230312_1116.zip
Cocoapods:
pod 'AgoraIrisRTC_iOS', '4.1.1.205-build.2'
''';

    final result = command.findIrisIOSPod(irisDependenciesContent);
    expect(result.cdn,
        'https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_iOS_Video_20230312_1116.zip');
    expect(result.mavenOrCocoaPods[0],
        'pod \'AgoraIrisRTC_iOS\', \'4.1.1.205-build.2\'');
  });

  test('findIrisIOSPod with empty content', () {
    final irisDependenciesContent = '';

    final result = command.findIrisMacosPod(irisDependenciesContent);
    expect(result.cdn, '');
    expect(result.mavenOrCocoaPods.length, 0);
  });

  test('findIrisMacosPod', () {
    final irisDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_Android_Video_20230312_1116_Dummy text.zip
CDN:
https://download.agora.io/sdk/release/iris_4.1.0_DCG_Mac_Video_20230105_0846.zip
Cocoapods:
pod 'AgoraIrisRTC_macOS', '4.1.0-rc.2'
''';

    final result = command.findIrisMacosPod(irisDependenciesContent);
    expect(result.cdn,
        'https://download.agora.io/sdk/release/iris_4.1.0_DCG_Mac_Video_20230105_0846.zip');
    expect(
        result.mavenOrCocoaPods[0], "pod 'AgoraIrisRTC_macOS', '4.1.0-rc.2'");
  });

  test('findIrisMacosPod with empty content', () {
    final irisDependenciesContent = '';

    final result = command.findIrisMacosPod(irisDependenciesContent);
    expect(result.cdn, '');
    expect(result.mavenOrCocoaPods.length, 0);
  });

  test('findIrisWindowsCDN', () {
    final irisDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_Android_Video_20230312_1116_Dummy text.zip
CDN:
https://download.agora.io/sdk/release/iris_4.1.1.205-build.1_DCG_Windows_Video_20230311_0918.zip
''';

    final result = command.findIrisWindowsCDN(irisDependenciesContent);
    expect(result.cdn,
        'https://download.agora.io/sdk/release/iris_4.1.1.205-build.1_DCG_Windows_Video_20230311_0918.zip');
  });

  test('findIrisWindowsCDN with empty content', () {
    final irisDependenciesContent = '';

    final result = command.findIrisMacosPod(irisDependenciesContent);
    expect(result.cdn, '');
    expect(result.mavenOrCocoaPods.length, 0);
  });

  test('modifiedAndroidGradleContent', () {
    final nativeSdkDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
Maven：
implementation 'io.agora.rtc:full-sdk:4.1.0-1'
implementation 'io.agora.rtc:agora-special-voice:4.0.1.9'
implementation 'io.agora.rtc:full-screen-sharing:4.0.1.9'
Cocoapods：
pod 'AgoraAudio_Special_iOS', '4.0.1.9'
pod 'AgoraRtcEngine_Special_iOS', '4.0.1.9'
''';

    final irisDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_Android_Video_20230312_1116_Dummy text.zip
CDN:
https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_Android_Video_20230312_1116.zip
Maven:
implementation 'io.agora.rtc:iris-rtc:4.1.1.205-build.2'
''';

    final fileContent = '''
group 'io.agora.agora_rtc_ng'
version '1.0-SNAPSHOT'

android {
    compileSdkVersion safeExtGet('compileSdkVersion', 31)

    defaultConfig {
        minSdkVersion safeExtGet('minSdkVersion', 16)

        consumerProguardFiles 'consumer-rules.pro'
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    sourceSets {
        if (isDev(project)) {
           main.jniLibs.srcDirs += 'libs'
        }
    }
}

dependencies {
  if (isDev(project)) {
    implementation fileTree(dir: "libs", include: ["*.jar"])
  } else {
    api 'io.agora.rtc:iris-rtc:4.1.0-rc.2'
    api 'io.agora.rtc:full-sdk:4.1.0'
    api 'io.agora.rtc:voice-sdk:4.1.0'
    implementation 'io.agora.rtc:full-screen-sharing:4.1.0-1'
  }
}
''';

    final expectedFileContent = '''
group 'io.agora.agora_rtc_ng'
version '1.0-SNAPSHOT'

android {
    compileSdkVersion safeExtGet('compileSdkVersion', 31)

    defaultConfig {
        minSdkVersion safeExtGet('minSdkVersion', 16)

        consumerProguardFiles 'consumer-rules.pro'
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    sourceSets {
        if (isDev(project)) {
           main.jniLibs.srcDirs += 'libs'
        }
    }
}

dependencies {
  if (isDev(project)) {
    implementation fileTree(dir: "libs", include: ["*.jar"])
  } else {
    api 'io.agora.rtc:iris-rtc:4.1.1.205-build.2'
    api 'io.agora.rtc:full-sdk:4.1.0-1'
    api 'io.agora.rtc:full-screen-sharing:4.0.1.9'
    api 'io.agora.rtc:agora-special-voice:4.0.1.9'
  }
}
''';

    final result = command.modifiedAndroidGradleContent(fileContent.split('\n'),
        nativeSdkDependenciesContent, irisDependenciesContent);
    expect(result, expectedFileContent);
  });

  test('modifiedAndroidGradleContent with empty content', () {
    final nativeSdkDependenciesContent = '';

    final irisDependenciesContent = '';

    final fileContent = '''
group 'io.agora.agora_rtc_ng'
version '1.0-SNAPSHOT'

android {
    compileSdkVersion safeExtGet('compileSdkVersion', 31)

    defaultConfig {
        minSdkVersion safeExtGet('minSdkVersion', 16)

        consumerProguardFiles 'consumer-rules.pro'
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    sourceSets {
        if (isDev(project)) {
           main.jniLibs.srcDirs += 'libs'
        }
    }
}

dependencies {
  if (isDev(project)) {
    implementation fileTree(dir: "libs", include: ["*.jar"])
  } else {
    api 'io.agora.rtc:iris-rtc:4.1.0-rc.2'
    api 'io.agora.rtc:full-sdk:4.1.0'
    api 'io.agora.rtc:voice-sdk:4.1.0'
    implementation 'io.agora.rtc:full-screen-sharing:4.1.0-1'
  }
}
''';

    final result = command.modifiedAndroidGradleContent(fileContent.split('\n'),
        nativeSdkDependenciesContent, irisDependenciesContent);
    expect(result, fileContent);
  });

  test('modifiedIOSPodspecContent', () {
    final nativeSdkDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
Maven：
implementation 'io.agora.rtc:full-sdk:4.1.0-1'
implementation 'io.agora.rtc:agora-special-voice:4.0.1.9'
implementation 'io.agora.rtc:full-screen-sharing:4.0.1.9'
Cocoapods：
pod 'AgoraRtcEngine_Special_iOS', '4.0.1.9'
pod 'AgoraAudio_Special_iOS', '4.1.1.3.BASIC'
''';

    final irisDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_Android_Video_20230312_1116_Dummy text.zip
CDN:
https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_iOS_Video_20230312_1116.zip
Cocoapods:
pod 'AgoraIrisRTC_iOS', '4.1.1.205-build.2'
''';

    final fileContent = '''
Pod::Spec.new do |s|
  s.name             = project.name
  s.version          = project.version
  s.summary          = 'A new flutter plugin project.'
  s.description      = project.description
  s.homepage         = 'https://github.com/AgoraIO/Flutter-SDK'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Agora' => 'developer@agora.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,mm,m,swift}'
  s.dependency 'Flutter'
  s.dependency 'AgoraIrisRTC_iOS', '4.1.0-rc.2'
  s.dependency 'AgoraRtcEngine_Special_iOS', '4.1.0.BASIC'
  s.dependency 'AgoraAudio_Special_iOS', '4.1.0.BASIC'
  # s.dependency 'AgoraRtcWrapper'
  s.platform = :ios, '9.0'
  s.swift_version = '5.0'
  s.libraries = 'stdc++'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
''';

    final expectedFileContent = '''
Pod::Spec.new do |s|
  s.name             = project.name
  s.version          = project.version
  s.summary          = 'A new flutter plugin project.'
  s.description      = project.description
  s.homepage         = 'https://github.com/AgoraIO/Flutter-SDK'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Agora' => 'developer@agora.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,mm,m,swift}'
  s.dependency 'Flutter'
  s.dependency 'AgoraIrisRTC_iOS', '4.1.1.205-build.2'
  s.dependency 'AgoraRtcEngine_Special_iOS', '4.0.1.9'
  s.dependency 'AgoraAudio_Special_iOS', '4.1.1.3.BASIC'
  # s.dependency 'AgoraRtcWrapper'
  s.platform = :ios, '9.0'
  s.swift_version = '5.0'
  s.libraries = 'stdc++'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
''';

    final result = command.modifiedIOSPodspecContent(fileContent.split('\n'),
        nativeSdkDependenciesContent, irisDependenciesContent);
    expect(result, expectedFileContent);
  });

  test('modifiedIOSPodspecContent with empty content', () {
    final nativeSdkDependenciesContent = '';

    final irisDependenciesContent = '';

    final fileContent = '''
Pod::Spec.new do |s|
  s.name             = project.name
  s.version          = project.version
  s.summary          = 'A new flutter plugin project.'
  s.description      = project.description
  s.homepage         = 'https://github.com/AgoraIO/Flutter-SDK'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Agora' => 'developer@agora.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,mm,m,swift}'
  s.dependency 'Flutter'
  s.dependency 'AgoraIrisRTC_iOS', '4.1.0-rc.2'
  s.dependency 'AgoraRtcEngine_Special_iOS', '4.1.0.BASIC'
  s.dependency 'AgoraAudio_Special_iOS', '4.1.0.BASIC'
  # s.dependency 'AgoraRtcWrapper'
  s.platform = :ios, '9.0'
  s.swift_version = '5.0'
  s.libraries = 'stdc++'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
''';

    final result = command.modifiedIOSPodspecContent(fileContent.split('\n'),
        nativeSdkDependenciesContent, irisDependenciesContent);
    expect(result, fileContent);
  });

  test('modifiedMacOSPodspecContent', () {
    final nativeSdkDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
Maven：
implementation 'io.agora.rtc:full-sdk:4.1.0-1'
implementation 'io.agora.rtc:agora-special-voice:4.0.1.9'
implementation 'io.agora.rtc:agora-special-full:4.0.1.9'
implementation 'io.agora.rtc:full-screen-sharing:4.0.1.9'
Cocoapods：
pod 'AgoraRtcEngine_iOS', '4.1.0'
pod 'AgoraAudio_Special_iOS', '4.0.1.9'
pod 'AgoraRtcEngine_Special_iOS', '4.0.1.9'
pod 'AgoraRtcEngine_macOS', '4.1.1'
''';

    final irisDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_Android_Video_20230312_1116_Dummy text.zip
CDN:
https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_Mac_Video_20230312_1116.zip
Cocoapods:
pod 'AgoraIrisRTC_macOS', '4.1.1'
''';

    final fileContent = '''
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint agora_rtc_ng.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'agora_rtc_engine'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,mm}', 'Classes/File.swift'
  s.dependency 'FlutterMacOS'
  #   s.dependency 'AgoraRtcWrapper'
  s.dependency 'AgoraRtcEngine_macOS', '4.1.0'
  s.dependency 'AgoraIrisRTC_macOS', '4.1.0-rc.2'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
''';

    final expectedFileContent = '''
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint agora_rtc_ng.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'agora_rtc_engine'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,mm}', 'Classes/File.swift'
  s.dependency 'FlutterMacOS'
  #   s.dependency 'AgoraRtcWrapper'
  s.dependency 'AgoraRtcEngine_macOS', '4.1.1'
  s.dependency 'AgoraIrisRTC_macOS', '4.1.1'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
''';

    final result = command.modifiedMacOSPodspecContent(fileContent.split('\n'),
        nativeSdkDependenciesContent, irisDependenciesContent);
    expect(result, expectedFileContent);
  });

  test('modifiedMacOSPodspecContent with empty content', () {
    final nativeSdkDependenciesContent = '';

    final irisDependenciesContent = '';

    final fileContent = '''
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint agora_rtc_ng.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'agora_rtc_engine'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,mm}', 'Classes/File.swift'
  s.dependency 'FlutterMacOS'
  #   s.dependency 'AgoraRtcWrapper'
  s.dependency 'AgoraRtcEngine_macOS', '4.1.0'
  s.dependency 'AgoraIrisRTC_macOS', '4.1.0-rc.2'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
''';

    final result = command.modifiedMacOSPodspecContent(fileContent.split('\n'),
        nativeSdkDependenciesContent, irisDependenciesContent);
    expect(result, fileContent);
  });

  test('modifiedWindowsCMakeContent', () {
    final irisDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_Android_Video_20230312_1116_Dummy text.zip
CDN:
https://download.agora.io/sdk/release/iris_4.1.1.205-build.1_DCG_Windows_Video_20230311_0918.zip
''';

    final fileContent = r'''
# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "agora_rtc_engine")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "agora_rtc_engine_plugin")

set(IRIS_SDK_DOWNLOAD_URL "https://download.agora.io/sdk/release/iris_4.1.0_DCG_Windows_Video_20221220_0216.zip")
set(IRIS_SDK_DOWNLOAD_NAME "iris_4.1.0_DCG_Windows")
set(RTC_SDK_DOWNLOAD_NAME "Agora_Native_SDK_for_Windows_FULL")
set(IRIS_SDK_VERSION "v3_6_2_fix.1")

# Add this project's cmake/ directory to the module path.
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(IRIS_DOWNLOAD_PATH "${CMAKE_CURRENT_SOURCE_DIR}/third_party/iris")
''';

    final expectedFileContent = r'''
# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "agora_rtc_engine")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "agora_rtc_engine_plugin")

set(IRIS_SDK_DOWNLOAD_URL "https://download.agora.io/sdk/release/iris_4.1.1.205-build.1_DCG_Windows_Video_20230311_0918.zip")
set(IRIS_SDK_DOWNLOAD_NAME "iris_4.1.1.205-build.1_DCG_Windows")
set(RTC_SDK_DOWNLOAD_NAME "Agora_Native_SDK_for_Windows_FULL")
set(IRIS_SDK_VERSION "v3_6_2_fix.1")

# Add this project's cmake/ directory to the module path.
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(IRIS_DOWNLOAD_PATH "${CMAKE_CURRENT_SOURCE_DIR}/third_party/iris")
''';

    final result = command.modifiedWindowsCMakeContent(
        fileContent.split('\n'), irisDependenciesContent);
    expect(result, expectedFileContent);
  });

  test('modifiedWindowsCMakeContent with empty content', () {
    final irisDependenciesContent = '';

    final fileContent = r'''
# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "agora_rtc_engine")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "agora_rtc_engine_plugin")

set(IRIS_SDK_DOWNLOAD_URL "https://download.agora.io/sdk/release/iris_4.1.0_DCG_Windows_Video_20221220_0216.zip")
set(IRIS_SDK_DOWNLOAD_NAME "iris_4.1.0_DCG_Windows")
set(RTC_SDK_DOWNLOAD_NAME "Agora_Native_SDK_for_Windows_FULL")
set(IRIS_SDK_VERSION "v3_6_2_fix.1")

# Add this project's cmake/ directory to the module path.
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(IRIS_DOWNLOAD_PATH "${CMAKE_CURRENT_SOURCE_DIR}/third_party/iris")
''';

    final result = command.modifiedWindowsCMakeContent(
        fileContent.split('\n'), irisDependenciesContent);
    expect(result, fileContent);
  });

  test('modifiedArtifactsVersionContent', () {
    final irisDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_Android_Video_20230312_1116_Dummy text.zip
CDN:
https://download.agora.io/sdk/release/iris_4.2.0-dev.6_DCG_Android_Video_20230412_0722.zip
https://download.agora.io/sdk/release/iris_4.2.0-dev.6_DCG_iOS_Video_20230412_0722.zip
https://download.agora.io/sdk/release/iris_4.2.0-dev.6_DCG_Mac_Video_20230412_0722.zip
https://download.agora.io/sdk/release/iris_4.2.0-dev.6_DCG_Windows_Video_20230412_0722.zip
''';

    final fileContent = r'''
set -e

export IRIS_CDN_URL_ANDROID="https://download.agora.io/sdk/release/iris_4.0.0-dev.6_DCG_Android_Video_20230412_0722.zip"
export IRIS_CDN_URL_IOS="https://download.agora.io/sdk/release/iris_4.0.0-dev.6_DCG_iOS_Video_20230412_0722.zip"
export IRIS_CDN_URL_MACOS="https://download.agora.io/sdk/release/iris_4.0.0-dev.6_DCG_Mac_Video_20230412_0722.zip"
export IRIS_CDN_URL_WINDOWS="https://download.agora.io/sdk/release/iris_4.0.0-dev.6_DCG_Windows_Video_20230412_0722.zip"
''';

    final expectedFileContent = r'''
set -e

export IRIS_CDN_URL_ANDROID="https://download.agora.io/sdk/release/iris_4.2.0-dev.6_DCG_Android_Video_20230412_0722.zip"
export IRIS_CDN_URL_IOS="https://download.agora.io/sdk/release/iris_4.2.0-dev.6_DCG_iOS_Video_20230412_0722.zip"
export IRIS_CDN_URL_MACOS="https://download.agora.io/sdk/release/iris_4.2.0-dev.6_DCG_Mac_Video_20230412_0722.zip"
export IRIS_CDN_URL_WINDOWS="https://download.agora.io/sdk/release/iris_4.2.0-dev.6_DCG_Windows_Video_20230412_0722.zip"
''';

    final result = command.modifiedArtifactsVersionContent(
        fileContent, irisDependenciesContent);
    expect(result, expectedFileContent);
  });

  test('modifiedArtifactsVersionContent with empty content', () {
    final irisDependenciesContent = '';

    final fileContent = r'''
set -e

export IRIS_CDN_URL_ANDROID="https://download.agora.io/sdk/release/iris_4.0.0-dev.6_DCG_Android_Video_20230412_0722.zip"
export IRIS_CDN_URL_IOS="https://download.agora.io/sdk/release/iris_4.0.0-dev.6_DCG_iOS_Video_20230412_0722.zip"
export IRIS_CDN_URL_MACOS="https://download.agora.io/sdk/release/iris_4.0.0-dev.6_DCG_Mac_Video_20230412_0722.zip"
export IRIS_CDN_URL_WINDOWS="https://download.agora.io/sdk/release/iris_4.0.0-dev.6_DCG_Windows_Video_20230412_0722.zip"
''';

    final result = command.modifiedArtifactsVersionContent(
        fileContent, irisDependenciesContent);
    expect(result, fileContent);
  });

  test('modifiedArtifactsVersionContent with android cdn url only', () {
    final irisDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
https://download.agora.io/sdk/release/iris_4.1.1.205-build.2_DCG_Android_Video_20230312_1116_Dummy text.zip
CDN:
https://download.agora.io/sdk/release/iris_4.2.0-dev.6_DCG_Android_Video_20230412_0722.zip
''';

    final fileContent = r'''
set -e

export IRIS_CDN_URL_ANDROID="https://download.agora.io/sdk/release/iris_4.0.0-dev.6_DCG_Android_Video_20230412_0722.zip"
export IRIS_CDN_URL_IOS="https://download.agora.io/sdk/release/iris_4.0.0-dev.6_DCG_iOS_Video_20230412_0722.zip"
export IRIS_CDN_URL_MACOS="https://download.agora.io/sdk/release/iris_4.0.0-dev.6_DCG_Mac_Video_20230412_0722.zip"
export IRIS_CDN_URL_WINDOWS="https://download.agora.io/sdk/release/iris_4.0.0-dev.6_DCG_Windows_Video_20230412_0722.zip"
''';

    final expectedFileContent = '''
set -e

export IRIS_CDN_URL_ANDROID="https://download.agora.io/sdk/release/iris_4.2.0-dev.6_DCG_Android_Video_20230412_0722.zip"
export IRIS_CDN_URL_IOS="https://download.agora.io/sdk/release/iris_4.0.0-dev.6_DCG_iOS_Video_20230412_0722.zip"
export IRIS_CDN_URL_MACOS="https://download.agora.io/sdk/release/iris_4.0.0-dev.6_DCG_Mac_Video_20230412_0722.zip"
export IRIS_CDN_URL_WINDOWS="https://download.agora.io/sdk/release/iris_4.0.0-dev.6_DCG_Windows_Video_20230412_0722.zip"
''';

    final result = command.modifiedArtifactsVersionContent(
        fileContent, irisDependenciesContent);
    expect(result, expectedFileContent);
  });

  test('modifiedPubspecContent', () {
    final fileContent = r'''
name: agora_rtc_engine
description: >-
  Flutter plugin of Agora RTC SDK, allow you to simply integrate Agora Video
  Calling or Live Video Streaming to your app with just a few lines of code.
version: 6.1.0
homepage: https://www.agora.io
repository: https://github.com/AgoraIO-Extensions/Agora-Flutter-SDK/tree/main
environment:
  sdk: '>=2.14.0 <3.0.0'
  flutter: '>=2.5.0'
''';

    final expectedFileContent = r'''
name: agora_rtc_engine
description: >-
  Flutter plugin of Agora RTC SDK, allow you to simply integrate Agora Video
  Calling or Live Video Streaming to your app with just a few lines of code.
version: 6.1.1-build.1
homepage: https://www.agora.io
repository: https://github.com/AgoraIO-Extensions/Agora-Flutter-SDK/tree/main
environment:
  sdk: '>=2.14.0 <3.0.0'
  flutter: '>=2.5.0'
''';

    final result = command.modifiedPubspecContent(fileContent, '6.1.1-build.1');
    expect(result, expectedFileContent);
  });

  test('modifiedExampleIOSPodfileContent', () {
    final nativeSdkDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
Maven：
implementation 'io.agora.rtc:full-sdk:4.1.0-1'
implementation 'io.agora.rtc:agora-special-voice:4.0.1.9'
implementation 'io.agora.rtc:full-screen-sharing:4.0.1.9'
Cocoapods：
pod 'AgoraRtcEngine_Special_iOS', '4.0.1.9'
''';

    final fileContent = '''
target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

#  pod 'iris_event_handler', :path => File.join('.symlinks', 'plugins', 'iris_event', 'ios')

  if plugin_dev != nil
    pod 'AgoraRtcWrapper', :path => File.join('.symlinks', 'plugins', 'agora_rtc_engine', 'ios')
    # pod 'iris_event_handler', :path => File.join('.symlinks', 'plugins', 'iris_event', 'ios')
  end
end

target 'ScreenSharing' do
  use_frameworks!
  use_modular_headers!
  
  if plugin_dev != nil
    pod 'AgoraRtcWrapper', :path => File.join('.symlinks', 'plugins', 'agora_rtc_engine', 'ios')
  else
    pod 'AgoraAudio_Special_iOS', '4.1.0.BASIC'
  end
end
''';

    final expectedFileContent = '''
target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

#  pod 'iris_event_handler', :path => File.join('.symlinks', 'plugins', 'iris_event', 'ios')

  if plugin_dev != nil
    pod 'AgoraRtcWrapper', :path => File.join('.symlinks', 'plugins', 'agora_rtc_engine', 'ios')
    # pod 'iris_event_handler', :path => File.join('.symlinks', 'plugins', 'iris_event', 'ios')
  end
end

target 'ScreenSharing' do
  use_frameworks!
  use_modular_headers!
  
  if plugin_dev != nil
    pod 'AgoraRtcWrapper', :path => File.join('.symlinks', 'plugins', 'agora_rtc_engine', 'ios')
  else
    pod 'AgoraRtcEngine_Special_iOS', '4.0.1.9'
  end
end
''';

    final result = command.modifiedExampleIOSPodfileContent(
        fileContent, nativeSdkDependenciesContent);
    expect(result, expectedFileContent);
  });

  test('modifiedExampleIOSPodfileContent with audio only', () {
    final nativeSdkDependenciesContent = '''
Iris:
Dummy text Dummy text Dummy text Dummy text Dummy text
Dummy text Dummy text Dummy text Dummy text Dummy text
Maven：
implementation 'io.agora.rtc:full-sdk:4.1.0-1'
implementation 'io.agora.rtc:agora-special-voice:4.0.1.9'
implementation 'io.agora.rtc:full-screen-sharing:4.0.1.9'
Cocoapods：
pod 'AgoraAudio_Special_iOS', '4.1.1.3.BASIC'
''';

    final fileContent = '''
target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

#  pod 'iris_event_handler', :path => File.join('.symlinks', 'plugins', 'iris_event', 'ios')

  if plugin_dev != nil
    pod 'AgoraRtcWrapper', :path => File.join('.symlinks', 'plugins', 'agora_rtc_engine', 'ios')
    # pod 'iris_event_handler', :path => File.join('.symlinks', 'plugins', 'iris_event', 'ios')
  end
end

target 'ScreenSharing' do
  use_frameworks!
  use_modular_headers!
  
  if plugin_dev != nil
    pod 'AgoraRtcWrapper', :path => File.join('.symlinks', 'plugins', 'agora_rtc_engine', 'ios')
  else
    pod 'AgoraAudio_Special_iOS', '4.1.0.BASIC'
  end
end
''';

    final expectedFileContent = '''
target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

#  pod 'iris_event_handler', :path => File.join('.symlinks', 'plugins', 'iris_event', 'ios')

  if plugin_dev != nil
    pod 'AgoraRtcWrapper', :path => File.join('.symlinks', 'plugins', 'agora_rtc_engine', 'ios')
    # pod 'iris_event_handler', :path => File.join('.symlinks', 'plugins', 'iris_event', 'ios')
  end
end

target 'ScreenSharing' do
  use_frameworks!
  use_modular_headers!
  
  if plugin_dev != nil
    pod 'AgoraRtcWrapper', :path => File.join('.symlinks', 'plugins', 'agora_rtc_engine', 'ios')
  else
    pod 'AgoraAudio_Special_iOS', '4.1.1.3.BASIC'
  end
end
''';

    final result = command.modifiedExampleIOSPodfileContent(
        fileContent, nativeSdkDependenciesContent);
    expect(result, expectedFileContent);
  });

  test('modifiedExampleIOSPodfileContent with empty content', () {
    final nativeSdkDependenciesContent = '';

    final fileContent = '''
target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

#  pod 'iris_event_handler', :path => File.join('.symlinks', 'plugins', 'iris_event', 'ios')

  if plugin_dev != nil
    pod 'AgoraRtcWrapper', :path => File.join('.symlinks', 'plugins', 'agora_rtc_engine', 'ios')
    # pod 'iris_event_handler', :path => File.join('.symlinks', 'plugins', 'iris_event', 'ios')
  end
end

target 'ScreenSharing' do
  use_frameworks!
  use_modular_headers!
  
  if plugin_dev != nil
    pod 'AgoraRtcWrapper', :path => File.join('.symlinks', 'plugins', 'agora_rtc_engine', 'ios')
  else
    pod 'AgoraAudio_Special_iOS', '4.1.0.BASIC'
  end
end
''';

    final result = command.modifiedExampleIOSPodfileContent(
        fileContent, nativeSdkDependenciesContent);
    expect(result, fileContent);
  });

  group('modifyIrisWebVersion', () {
    test('can modify iris-web cdn', () {
      final p = path.join(fileSystem.currentDirectory.absolute.path,
          'scripts/iris_web_version.js');
      final f = fileSystem.file(p);
      f.createSync(recursive: true);
      f.writeAsStringSync(r'''
// Share the iris web url to all the tests

// This url should be same as the url inside the `example/web/index.html`
const irisWebUrl = 'https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.2.0-build.1.js';
const irisWebFakeUrl = 'https://download.agora.io/staging/iris-web-rtc-fake_n423_w4182_0.2.0-build.1.js';
''');

      final exampleIndexPath = path.join(
          fileSystem.currentDirectory.absolute.path, 'example/web/index.html');
      final exampleIndexFile = fileSystem.file(exampleIndexPath);
      exampleIndexFile.createSync(recursive: true);
      exampleIndexFile.writeAsStringSync(r'''
<!DOCTYPE html>
<html>
<body>
  <!-- This script installs service_worker.js to provide PWA functionality to
       application. For more information, see:
       https://developers.google.com/web/fundamentals/primers/service-workers -->
  <script>
    var serviceWorkerVersion = null;
    } else {
      // Service workers not supported. Just drop the <script> tag.
      loadMainDartJs();
    }
  </script>
  <script src="https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.2.0-build.1.js"></script>
</body>
</html>
''');

      final readMeFilePath =
          path.join(fileSystem.currentDirectory.absolute.path, 'README.md');
      final readMeFile = fileSystem.file(readMeFilePath);
      readMeFile.createSync(recursive: true);
      readMeFile.writeAsStringSync(r'''
**Project structure**
```
<your-project>
|__web
   |__index.html
   |__iris-web-rtc_<x.y.z>.js
```

```html
<!-- <your-project>/web/index.html -->
<!DOCTYPE html>
<html>
...
<body>
  ...
  <script src="iris-web-rtc_<x.y.z>.js"></script>
</body>
</html>
```
Download: https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.3.0.js

**For Testing Purposes**

You can directly depend on the Agora CDN for testing purposes:
```html
<!-- <your-project>/web/index.html -->
<!DOCTYPE html>
<html>
...
<body>
  ...
  <script src="https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.3.0.js"></script>
</body>
</html>
```
''');

      final nativeDenpendenciesContent = '''
CDN:
https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.2.0-build.2.js
''';
      command.modifyIrisWebVersion(fileSystem.currentDirectory.absolute.path,
          nativeDenpendenciesContent);

      final expectedContent = r'''
// Share the iris web url to all the tests

// This url should be same as the url inside the `example/web/index.html`
const irisWebUrl = 'https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.2.0-build.2.js';
const irisWebFakeUrl = 'https://download.agora.io/staging/iris-web-rtc-fake_n423_w4182_0.2.0-build.1.js';
''';

      expect(f.readAsStringSync(), expectedContent);

      final expectedExampleIndexContent = r'''
<!DOCTYPE html>
<html>
<body>
  <!-- This script installs service_worker.js to provide PWA functionality to
       application. For more information, see:
       https://developers.google.com/web/fundamentals/primers/service-workers -->
  <script>
    var serviceWorkerVersion = null;
    } else {
      // Service workers not supported. Just drop the <script> tag.
      loadMainDartJs();
    }
  </script>
  <script src="https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.2.0-build.2.js"></script>
</body>
</html>
''';
      expect(exampleIndexFile.readAsStringSync(), expectedExampleIndexContent);

      final expectedReadMeFileContent = r'''
**Project structure**
```
<your-project>
|__web
   |__index.html
   |__iris-web-rtc_<x.y.z>.js
```

```html
<!-- <your-project>/web/index.html -->
<!DOCTYPE html>
<html>
...
<body>
  ...
  <script src="iris-web-rtc_<x.y.z>.js"></script>
</body>
</html>
```
Download: https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.2.0-build.2.js

**For Testing Purposes**

You can directly depend on the Agora CDN for testing purposes:
```html
<!-- <your-project>/web/index.html -->
<!DOCTYPE html>
<html>
...
<body>
  ...
  <script src="https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.2.0-build.2.js"></script>
</body>
</html>
```
''';
      expect(readMeFile.readAsStringSync(), expectedReadMeFileContent);
    });

    test('can modify iris-web-fake cdn', () {
      final p = path.join(fileSystem.currentDirectory.absolute.path,
          'scripts/iris_web_version.js');
      final f = fileSystem.file(p);
      f.createSync(recursive: true);
      f.writeAsStringSync(r'''
// Share the iris web url to all the tests

// This url should be same as the url inside the `example/web/index.html`
const irisWebUrl = 'https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.2.0-build.1.js';
const irisWebFakeUrl = 'https://download.agora.io/staging/iris-web-rtc-fake_n423_w4182_0.2.0-build.1.js';
''');

      final nativeDenpendenciesContent = '''
CDN:
https://download.agora.io/staging/iris-web-rtc-fake_n423_w4182_0.2.0-build.2.js
''';
      command.modifyIrisWebVersion(fileSystem.currentDirectory.absolute.path,
          nativeDenpendenciesContent);

      final expectedContent = r'''
// Share the iris web url to all the tests

// This url should be same as the url inside the `example/web/index.html`
const irisWebUrl = 'https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.2.0-build.1.js';
const irisWebFakeUrl = 'https://download.agora.io/staging/iris-web-rtc-fake_n423_w4182_0.2.0-build.2.js';
''';

      expect(f.readAsStringSync(), expectedContent);
    });

    test('can modify iris-web/iris-web-fake cdns', () {
      final p = path.join(fileSystem.currentDirectory.absolute.path,
          'scripts/iris_web_version.js');
      final f = fileSystem.file(p);
      f.createSync(recursive: true);
      f.writeAsStringSync(r'''
// Share the iris web url to all the tests

// This url should be same as the url inside the `example/web/index.html`
const irisWebUrl = 'https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.2.0-build.1.js';
const irisWebFakeUrl = 'https://download.agora.io/staging/iris-web-rtc-fake_n423_w4182_0.2.0-build.1.js';
''');

      final exampleIndexPath = path.join(
          fileSystem.currentDirectory.absolute.path, 'example/web/index.html');
      final exampleIndexFile = fileSystem.file(exampleIndexPath);
      exampleIndexFile.createSync(recursive: true);
      exampleIndexFile.writeAsStringSync(r'''
<!DOCTYPE html>
<html>
<body>
  <!-- This script installs service_worker.js to provide PWA functionality to
       application. For more information, see:
       https://developers.google.com/web/fundamentals/primers/service-workers -->
  <script>
    var serviceWorkerVersion = null;
    } else {
      // Service workers not supported. Just drop the <script> tag.
      loadMainDartJs();
    }
  </script>
  <script src="https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.2.0-build.1.js"></script>
</body>
</html>
''');

      final nativeDenpendenciesContent = '''
CDN:
https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.2.0-build.2.js
CDN:
https://download.agora.io/staging/iris-web-rtc-fake_n423_w4182_0.2.0-build.2.js
''';
      command.modifyIrisWebVersion(fileSystem.currentDirectory.absolute.path,
          nativeDenpendenciesContent);

      final expectedContent = r'''
// Share the iris web url to all the tests

// This url should be same as the url inside the `example/web/index.html`
const irisWebUrl = 'https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.2.0-build.2.js';
const irisWebFakeUrl = 'https://download.agora.io/staging/iris-web-rtc-fake_n423_w4182_0.2.0-build.2.js';
''';

      expect(f.readAsStringSync(), expectedContent);

      final expectedExampleIndexContent = r'''
<!DOCTYPE html>
<html>
<body>
  <!-- This script installs service_worker.js to provide PWA functionality to
       application. For more information, see:
       https://developers.google.com/web/fundamentals/primers/service-workers -->
  <script>
    var serviceWorkerVersion = null;
    } else {
      // Service workers not supported. Just drop the <script> tag.
      loadMainDartJs();
    }
  </script>
  <script src="https://download.agora.io/staging/iris-web-rtc_n423_w4182_0.2.0-build.2.js"></script>
</body>
</html>
''';
      expect(exampleIndexFile.readAsStringSync(), expectedExampleIndexContent);
    });
  });
}
