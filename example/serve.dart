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
    print("Press <ENTER> to exit");
    stdin.listen((data) {
      server.close(force: true);
      exit(0);
    });

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
