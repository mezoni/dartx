dartx
==========

The main purpose of `dartx` is that it allows easy to execute special standalone command-line scripts at any place. These scripts can to require for their operation other packages (uses import directives). They will be executed without requirements manually to install these dependent packages.

Dartx does not have any dependencies and can be distributed with a command-line scripts.

Dartx supports the command-line scripts that contains `pubspec.yaml` files inside the source code of these scripts.

Example of `command-line script` (example/serve.dart):

```dart
/*
@pubspec.yaml
name: serve
description: A sample static server
dependencies:
  shelf: any
  shelf_static: any
*/

import "dart:async";
import "dart:io";
import 'package:shelf/shelf_io.dart' as shelf_io;
import "package:shelf_static/shelf_static.dart";

void main() {
  var path = Directory.current.path;
  var handler = createStaticHandler(path, defaultDocument: "index.html");
  var port = 8080;
  var address = InternetAddress.LOOPBACK_IP_V4;
  shelf_io.serve(handler, address, port).then((server) {
    var address = server.address.address;
    var port = server.port;
    var url = "http://$address:$port";
    print("Static web server (shelf)");
    print("Url: $url");
    print("Path: $path");
    Timer.run(() => runBrowser(url));
  });
}

void runBrowser(String url) {
  var fail = false;
  switch (Platform.operatingSystem) {
    case "linux":
      Process.run("x-www-browser", [url]);
      break;
    case "macos":
      Process.run("open", [url]);
      break;
    case "windows":
      Process.run("explorer", [url]);
      break;
    default:
      fail = true;
      break;
  }

  if (!fail) {
    print("Start browsing...");
  }
}
```

To see it in action perform the following steps:

1. Go to the `dartx/example` directory.
2. Run command `$DART_SDK/bin/dart ../bin/dartx.dart serve.dart`.

Static web server will be executed even it uses `shelf` and `shelf_static` packages but `dartx` package does not declare in its `pubspec.yaml` these dependencies.

Principle of operation is very simple:

Before executing script `dartx` creates temporary directory and tells `pub` to `get` dependencies into this temporary directory.

Temporary directory will be deleted after the end of execution of command-line script. 
