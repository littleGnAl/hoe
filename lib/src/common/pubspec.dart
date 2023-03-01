import 'package:yaml/yaml.dart';

/// Information of pubspec.yaml
class Pubspec {
  const Pubspec._(this.name, this.version);
  factory Pubspec.load(String pubspecFileContent) {
    var doc = loadYaml(pubspecFileContent);

    return Pubspec._(doc['hoe'], doc['version']);
  }

  final String name;
  final String version;
}
