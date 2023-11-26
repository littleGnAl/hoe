import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'global_config.dart';

import 'package:path/path.dart' as path;
import 'package:file/file.dart';
import 'package:process/process.dart';
import 'package:hoe/src/base/process_manager_ext.dart';
import 'package:archive/archive_io.dart';

class DefaultFileDownloader {
  DefaultFileDownloader(this._globalConfig);
  final GlobalConfig _globalConfig;
  final Dio _dio = Dio();

  Future<Response> downloadFile(String url, String savePath) async {
    final user = _globalConfig.agoraArtifactoryUser;
    final pwd = _globalConfig.agoraArtifactoryPwd;

    Map<String, dynamic> headers = {};
    if (user.isNotEmpty && pwd.isNotEmpty) {
      headers = {
        ...{
          'Authorization': 'Basic ' +
              base64Encode(
                utf8.encode('$user:$pwd'),
              )
        }
      };
    }

    return _dio.download(url, savePath, options: Options(headers: headers),
        onReceiveProgress: (int count, int total) {
      stdout.writeln(
          'Downloading $url --- ${((count / total) * 100).toStringAsFixed(1)}%');
    });
  }
}

Future<String> downloadAndUnzip(
    ProcessManager processManager,
    FileSystem fileSystem,
    GlobalConfig globalConfig,
    String zipFileUrl,
    String unzipOutputPath,
    {bool isUnzipSymlinks = false}) async {
  final zipDownloadPath = path.join(unzipOutputPath, 'zip_download_path');
  final zipDownloadDir = fileSystem.directory(zipDownloadPath);
  zipDownloadDir.createSync();

  final zipFileBaseName = Uri.parse(zipFileUrl).pathSegments.last;

  final fileDownloader = DefaultFileDownloader(globalConfig);
  await fileDownloader.downloadFile(
    zipFileUrl,
    path.join(zipDownloadPath, zipFileBaseName),
  );

  if (isUnzipSymlinks) {
    _unzipSymlinks(processManager, path.join(zipDownloadPath, zipFileBaseName),
        zipDownloadPath);
  } else {
    _unzip(path.join(zipDownloadPath, zipFileBaseName), zipDownloadPath);
  }

  return zipDownloadPath;
}

void _unzipSymlinks(
    ProcessManager processManager, String zipFilePath, String outputPath) {
  // unzip iris_artifact/iris_artifact.zip -d iris_artifact
  processManager.runSyncWithOutput([
    'ditto',
    '-x',
    '-k',
    zipFilePath,
    outputPath,
  ]);
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

String getUnzipDir(
  FileSystem fileSystem,
  String zipFileUrl,
  String zipDownloadPath,
  String irisType, // DCG/RTM
  String platform, // iOS/Android/macOS/Windows
) {
  final zipDownloadDir = fileSystem.directory(zipDownloadPath);
  final zipFileBaseName = Uri.parse(zipFileUrl).pathSegments.last;

  final zipDirList = zipDownloadDir.listSync();
  bool hasWrapDir = false;

  for (final dir in zipDirList) {
    if (dir.path == zipFileBaseName) {
      hasWrapDir = true;
      break;
    }
  }

  // iris_4.1.0_DCG_Mac_Video_20221122_0724
  final version = zipFileBaseName.split('_')[1];

  if (hasWrapDir) {
    return path.join(
      zipDownloadPath,
      zipFileBaseName,
      'iris_${version}_${irisType}_$platform',
    );
  }

  return path.join(zipDownloadPath, 'iris_${version}_${irisType}_$platform');
}
