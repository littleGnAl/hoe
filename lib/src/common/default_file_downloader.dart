import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'global_config.dart';

class DefaultFileDownloader {
  DefaultFileDownloader(this._globalConfig);
  final GlobalConfig _globalConfig;
  final Dio _dio = Dio();

  Future<Response> downloadFile(String url, String savePath) async {
    // final envVarMap = Platform.environment;
    final user = _globalConfig.agoraArtifactoryUser;
    // stdout.writeln('user: $user');

    final pwd = _globalConfig.agoraArtifactoryPwd;
    // stdout.writeln('pwd: $pwd');
    return _dio.download(url, savePath,
        options: Options(headers: {
          'Authorization': 'Basic ' +
              base64Encode(
                utf8.encode('$user:$pwd'),
              )
        }), onReceiveProgress: (int count, int total) {
      stdout.writeln(
          'Downloading $url --- ${((count / total) * 100).toStringAsFixed(1)}%');
    });
  }
}
