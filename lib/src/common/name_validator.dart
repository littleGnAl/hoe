// Borrow from flutter create command

// A valid Dart identifier that can be used for a package, i.e. no
// capital letters.
// https://dart.dev/guides/language/language-tour#important-concepts
final RegExp _identifierRegExp = RegExp('[a-z_][a-z0-9_]*');

// non-contextual dart keywords.
//' https://dart.dev/guides/language/language-tour#keywords
const Set<String> _keywords = <String>{
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'inout',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'native',
  'new',
  'null',
  'of',
  'on',
  'operator',
  'out',
  'part',
  'patch',
  'required',
  'rethrow',
  'return',
  'set',
  'show',
  'source',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'while',
  'with',
  'yield',
};

const Set<String> _packageDependencies = <String>{
  'collection',
  'flutter',
  'flutter_test',
  'meta',
};

/// Whether [name] is a valid Pub package or variable.
bool isValidPackageOrVariableName(String name) {
  final match = _identifierRegExp.matchAsPrefix(name);
  return match != null && match.end == name.length && !_keywords.contains(name);
}

// Return null if the project name is legal. Return a validation message if
// we should disallow the project name.
String? validateProjectName(String projectName) {
  if (!isValidPackageOrVariableName(projectName)) {
    return '"$projectName" is not a valid Dart package name.\n\n'
        'See https://dart.dev/tools/pub/pubspec#name for more information.';
  }
  if (_packageDependencies.contains(projectName)) {
    return "Invalid project name: '$projectName' - this will conflict with Flutter "
        'package dependencies.';
  }
  return null;
}
