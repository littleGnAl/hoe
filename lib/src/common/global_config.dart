import 'dart:io';

class GlobalConfig {
  GlobalConfig() {
    // flutter build windows --dart-define TEST_APP_ID="$TEST_APP_ID" --dart-define TEST_TOKEN="$TEST_TOKEN" --dart-define TEST_CHANNEL_ID="$TEST_CHANNEL_ID"
    final envVarMap = Platform.environment;

    // _testAppId = envVarMap['TEST_APP_ID']!;
    // _testToken = envVarMap['TEST_TOKEN'] ?? '';
    // _testChannelId = envVarMap['TEST_CHANNEL_ID'] ?? 'testapi';
    // // stdout.writeln('user: $user');

    // _appleTeamIdTest = envVarMap['TEAM_TEST'] ?? '';
    // _appleCodeSignIdentityTest = envVarMap['CODE_SIGN_IDENTITY_TEST'] ?? '';

    // _appleTeamIdLab = envVarMap['TEAM_LAB'] ?? '';
    // _appleCodeSignIdentityLab = envVarMap['CODE_SIGN_IDENTITY_LAB'] ?? '';

    // _appleTeamIdQa = envVarMap['TEAM_QA'] ?? '';
    // _appleCodeSignIdentityQa = envVarMap['CODE_SIGN_IDENTITY_QA'] ?? '';
  }

  String get githubActionRunnerTemp => Platform.environment['RUNNER_TEMP']!;

  String get testAppId => Platform.environment['TEST_APP_ID']!;

  String get testToken => Platform.environment['TEST_TOKEN'] ?? '';

  String get testChannelId =>
      Platform.environment['TEST_CHANNEL_ID'] ?? 'testapi';

  String get musicCenterAppid => Platform.environment['MUSIC_CENTER_APPID']!;

  String get appleTeamIdTest => Platform.environment['TEAM_TEST'] ?? '';

  String get appleCodeSignIdentityTest =>
      Platform.environment['CODE_SIGN_IDENTITY_TEST'] ?? '';

  String get appleTeamIdLab => Platform.environment['TEAM_LAB'] ?? '';

  String get appleCodeSignIdentityLab =>
      Platform.environment['CODE_SIGN_IDENTITY_LAB'] ?? '';

  String get appleTeamIdQa => Platform.environment['TEAM_QA'] ?? '';

  String get appleCodeSignIdentityQa =>
      Platform.environment['CODE_SIGN_IDENTITY_QA'] ?? '';

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

  String get agoraArtifactoryUser =>
      Platform.environment['AGORA_ARTIFACTORY_USER']!;

  String get agoraArtifactoryPwd =>
      Platform.environment['AGORA_ARTIFACTORY_PWD']!;
}
