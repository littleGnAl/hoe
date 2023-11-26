import 'dart:io';
import 'package:file/file.dart' as fs;
import 'package:path/path.dart' as path;

void copyDirectory(
    fs.FileSystem fileSystem, Directory source, Directory destination) {
  if (!destination.existsSync()) {
    destination.createSync(recursive: true);
  }
  source.listSync(recursive: false).forEach((var entity) {
    if (entity is Directory) {
      var newDirectory = fileSystem.directory(
          path.join(destination.absolute.path, path.basename(entity.path)));
      newDirectory.createSync();

      copyDirectory(fileSystem, entity.absolute, newDirectory);
    } else if (entity is File) {
      entity.copySync(path.join(destination.path, path.basename(entity.path)));
    }
  });
}
