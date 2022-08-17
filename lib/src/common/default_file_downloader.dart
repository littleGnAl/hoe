import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

class DefaultFileDownloader {
  final Dio _dio = Dio();

  Future<Response> downloadFile(String url, String savePath) async {
    // final envVarMap = Platform.environment;
    // final user = envVarMap['AGORA_ARTIFACTORY_USER'];
    // stdout.writeln('user: $user');

    // final pwd = envVarMap[
    //     'AGORA_ARTIFACTORY_PWD']; //String.fromEnvironment('AGORA_ARTIFACTORY_PWD');
    // stdout.writeln('pwd: $pwd');
    return _dio.download(url, savePath,
        // options: Options(headers: {
        //   'Authorization': 'Basic ' +
        //       base64Encode(
        //         utf8.encode('$user:$pwd'),
        //       )
        // }),
        );
  }
}
