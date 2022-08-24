import 'dart:io';

class GlobalConfig {
  GlobalConfig() {
    // flutter build windows --dart-define TEST_APP_ID="$TEST_APP_ID" --dart-define TEST_TOKEN="$TEST_TOKEN" --dart-define TEST_CHANNEL_ID="$TEST_CHANNEL_ID"
    final envVarMap = Platform.environment;
    _testAppId = envVarMap['TEST_APP_ID']!;
    _testToken = envVarMap['TEST_TOKEN'] ?? '';
    _testChannelId = envVarMap['TEST_CHANNEL_ID'] ?? 'testapi';
    // stdout.writeln('user: $user');

    // final pwd = envVarMap[
    //     'AGORA_ARTIFACTORY_PWD']; //String.fromEnvironment('AGORA_ARTIFACTORY_PWD');
    // stdout.writeln('pwd: $pwd');
  }

  late final String _testAppId;
  String get testAppId => _testAppId;

  late final String _testToken;
  String get testToken => _testToken;

  late final String _testChannelId;
  String get testChannelId => _testChannelId;
}
