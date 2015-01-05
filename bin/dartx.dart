import "dart:async";
import "dart:io";

void main(List<String> args) {
  new DartX().run(args).then((exitCode) {
    exit(exitCode);
  });
}

class DartX {
  List<String> _arguments;
  String _dartSdk;
  int _exitCode;
  String _pubspec;
  String _script;
  String _temporaryDirectory;
  bool _verbose;
  String _workingDirectory;

  Future<int> run(List<String> arguments) {
    return _run(arguments);
  }

  void _createLinkToLibDirectory() {
    var directory = new Directory("lib");
    if (directory.existsSync()) {
      var link = new Link(_temporaryDirectory + "/lib");
      link.createSync(directory.absolute.path);
    }
  }

  void _createPubspecFile() {
    var file = new File(_temporaryDirectory + "/pubspec.yaml");
    file.writeAsStringSync(_pubspec);
  }

  void _createTemporaryDirectory() {
    _temporaryDirectory = Directory.systemTemp.createTempSync().path;
  }

  void _deleteTemporaryDirectory() {
    var directory = new Directory(_temporaryDirectory);
    for (var file in directory.listSync(recursive: true, followLinks: false)) {
      if (file is Link) {
        try {
          file.deleteSync();
        } catch (s) {
        }
      }
    }

    directory.deleteSync(recursive: true);
  }

  void _findDartSdk() {
    var executable = Platform.executable;
    var s = Platform.pathSeparator;
    if (!executable.contains(s)) {
      if (Platform.isLinux) {
        executable = new Link("/proc/$pid/exe").resolveSymbolicLinksSync();
      }
    }

    var file = new File(executable);
    if (file.existsSync()) {
      var parent = file.absolute.parent;
      parent = parent.parent;
      var path = parent.path;
      var dartAPI = "$path${s}include${s}dart_api.h";
      if (new File(dartAPI).existsSync()) {
        _dartSdk = path;
        return;
      }
    }

    if (_dartSdk == null) {
      print("Dart SDK not found.");
      _exitCode = -1;
      return;
    }
  }

  void _parseArguments(List<String> arguments) {
    for (var argument in arguments) {
      if (_arguments != null) {
        _arguments.add(argument);
      } else {
        if (argument.startsWith("--")) {
          switch (argument) {
            case "--verbose":
              _verbose = true;
              break;
            default:
              _printUsage();
              _exitCode = -1;
              break;
          }

        } else {
          _script = argument;
          _arguments = new List<String>();
        }
      }
    }

    if (_script == null) {
      _printUsage();
      _exitCode = -1;
      return;
    }
  }

  void _parseScript() {
    var file = new File(_script);
    if (!file.existsSync()) {
      print("File not found: $_script");
      _exitCode = -1;
      return;
    }

    var lines = file.readAsLinesSync();
    var length = lines.length;
    var result = <String>[];
    for (var i = 0; i < length && _pubspec == null; i++) {
      var line = lines[i];
      if (line.trimRight() == "/*") {
        if (i + 1 < length) {
          line = lines[++i];
          if (line.trimRight() == "@pubspec.yaml") {
            for (i++; i < length; i++) {
              var line = lines[i];
              if (line.trimRight() == r"*/") {
                _pubspec = result.join("\n");
                break;
              } else {
                result.add(line);
              }
            }
          }
        }
      }
    }

    if (_pubspec == null) {
      print("pubspec.yaml not found in: $_script");
      _exitCode = -1;
    }
  }

  void _printUsage() {
    print("dartx [options] script.dart [arguments]");
    print("Options:");
    print("  --verbose: Verbose pub output.");
  }

  ProcessResult _pubGet() {
    var arguments = <String>["get"];
    return _runPub(arguments, workingDirectory: _temporaryDirectory);
  }

  void _reset() {
    _arguments = null;
    _exitCode = 0;
    _pubspec = null;
    _script = null;
    _temporaryDirectory = null;
    _verbose = false;
    _workingDirectory = Directory.current.path;
  }

  Future<int> _run(List<String> arguments) {
    if (arguments.isEmpty) {
      _printUsage();
      return new Future.value(0);
    }

    _reset();
    _parseArguments(arguments);
    if (_exitCode != 0) {
      return new Future.value(_exitCode);
    }

    _findDartSdk();
    if (_exitCode != 0) {
      return new Future.value(_exitCode);
    }

    _parseScript();
    if (_exitCode != 0) {
      return new Future.value(_exitCode);
    }

    _createTemporaryDirectory();
    _createLinkToLibDirectory();
    _createPubspecFile();
    var result = _pubGet();
    if (_verbose || result.exitCode != 0) {
      print(result.stderr);
      print(result.stdout);
      if (result.exitCode != 0) {
        _exitCode = -1;
        return new Future.value(_exitCode);
      }
    }

    return _runScript().then((result) {
      _deleteTemporaryDirectory();
      _exitCode = result;
      return _exitCode;
    });
  }

  ProcessResult _runPub(List<String> arguments, {String workingDirectory}) {
    var executable = _dartSdk + "/bin/pub";
    return Process.runSync(executable, arguments, runInShell: true,
        workingDirectory: workingDirectory);
  }

  Future<int> _runScript() {
    var vmArguments = <String>[];
    vmArguments.add("--checked");
    vmArguments.addAll(["--package-root=$_temporaryDirectory/packages"]);
    vmArguments.add(_script);
    vmArguments.addAll(_arguments);
    return Process.start(Platform.executable, vmArguments, workingDirectory:
        _workingDirectory).then((process) {
      process.stderr.pipe(stderr);
      process.stdout.pipe(stdout);
      stdin.pipe(process.stdin);
      return process.exitCode.then((exitCode) {
        return exitCode;
      });
    });
  }
}
