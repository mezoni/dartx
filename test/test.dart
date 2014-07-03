import "dart:io";
import "package:path/path.dart" as pathos;

void main() {
  var curDir = Directory.current.path;
  var rootDir = pathos.dirname(curDir);
  var dartx = pathos.join(rootDir, "bin", "dartx.dart");
  var args = [dartx, "script.dart"];
  var result = Process.runSync(Platform.executable, args);
  if(result.exitCode != 0) {
    throw "Test failed\n" + result.stdout;
  } else {
    var string = "${result.stdout}";
    if(!string.startsWith(curDir)) {
      throw "Test failed";
    }
  }
}
