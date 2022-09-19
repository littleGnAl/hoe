import 'dart:io';

class GlobalConfig {
  GlobalConfig() {
    // flutter build windows --dart-define TEST_APP_ID="$TEST_APP_ID" --dart-define TEST_TOKEN="$TEST_TOKEN" --dart-define TEST_CHANNEL_ID="$TEST_CHANNEL_ID"
    final envVarMap = Platform.environment;

    _testAppId = envVarMap['TEST_APP_ID']!;
    _testToken = envVarMap['TEST_TOKEN'] ?? '';
    _testChannelId = envVarMap['TEST_CHANNEL_ID'] ?? 'testapi';
    // stdout.writeln('user: $user');

    _appleTeamIdTest = envVarMap['TEAM_TEST'] ?? '';
    _appleCodeSignIdentityTest = envVarMap['CODE_SIGN_IDENTITY_TEST'] ?? '';

    _appleTeamIdLab = envVarMap['TEAM_LAB'] ?? '';
    _appleCodeSignIdentityLab = envVarMap['CODE_SIGN_IDENTITY_LAB'] ?? '';

    _appleTeamIdQa = envVarMap['TEAM_QA'] ?? '';
    _appleCodeSignIdentityQa = envVarMap['CODE_SIGN_IDENTITY_QA'] ?? '';
  }

  String get githubActionRunnerTemp => Platform.environment['RUNNER_TEMP']!;

  late final String _testAppId;
  String get testAppId => _testAppId;

  late final String _testToken;
  String get testToken => _testToken;

  late final String _testChannelId;
  String get testChannelId => _testChannelId;

  String get musicCenterAppid => Platform.environment['MUSIC_CENTER_APPID']!;

  late final String _appleTeamIdTest;
  String get appleTeamIdTest => _appleTeamIdTest;

  late final String _appleCodeSignIdentityTest;
  String get appleCodeSignIdentityTest => _appleCodeSignIdentityTest;

  late final String _appleTeamIdLab;
  String get appleTeamIdLab => _appleTeamIdLab;

  late final String _appleCodeSignIdentityLab;
  String get appleCodeSignIdentityLab => _appleCodeSignIdentityLab;

  late final String _appleTeamIdQa;
  String get appleTeamIdQa => _appleTeamIdQa;

  late final String _appleCodeSignIdentityQa;
  String get appleCodeSignIdentityQa => _appleCodeSignIdentityQa;

  String get agoralab2020PPGpgPwd =>
      Platform.environment['AGORALAB2020_PP_GPG_PWD']!;

  String get agoralab2020P12Base64 =>
      Platform.environment['AGORALAB2020_P12_BASE64']!;

  String get agoralab2020P12Pwd =>
      Platform.environment['AGORALAB2020_P12_PWD']!;

  String get agoralab2020KeychainPassword =>
      Platform.environment['AGORALAB2020_KEYCHAIN_PASSWORD']!;

  String get agoraqa2021PPGpgPwd =>
      Platform.environment['AGORAQA2021_PP_GPG_PWD']!;

  String get agoraqa2021P12Base64 =>
      Platform.environment['AGORAQA2021_P12_BASE64']!;

  String get agoraqa2021P12Pwd => Platform.environment['AGORAQA2021_P12_PWD']!;

  String get agoraqa2021KeychainPassword =>
      Platform.environment['AGORAQA2021_KEYCHAIN_PASSWORD']!;

  String get agoratest2020PPGpgPwd =>
      Platform.environment['AGORATEST2020_PP_GPG_PWD']!;

  String get agoratest2020P12Base64 =>
      Platform.environment['AGORATEST2020_P12_BASE64']!;

  String get agoratest2020P12Pwd =>
      Platform.environment['AGORATEST2020_P12_PWD']!;

  String get agoratest2020KeychainPassword =>
      Platform.environment['AGORATEST2020_KEYCHAIN_PASSWORD']!;
}
