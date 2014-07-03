/*
@pubspec.yaml
name: script
dependencies:
  path:
*/

import "dart:io";
import "package:path/path.dart" as pathos;

void main() {
  var dir = pathos.dirname(Platform.script.toFilePath(windows:
      Platform.isWindows));
  print(dir);
}
