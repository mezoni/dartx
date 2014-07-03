dartx
==========

Dartx it is designed to run standalone command-line scripts at any place without requirements to pre-install these scripts. It can be used for writing a small batch files in Dart language.

Dartx does not have any dependencies and can be distributed with a command-line scripts.

Dartx supports the command-line scripts that contains `pubspec.yaml` files inside the source code of these scripts.

Example of `command-line script`:

```dart
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
```

This script can be executed by `dartx script.dart`.

Before executing script `dartx` creates temporary directory and tells `pub` to `get` dependencies into this temporary directory. 
Temporary directory will be deleted after the end of execution of command-line script. 
