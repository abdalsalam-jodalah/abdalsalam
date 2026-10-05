// lib/features/sync/services/adb_locator.dart — finds the adb executable on PATH or in the usual install folders.

import 'dart:io';

import '../../../core/constants/adb_constants.dart';
import 'process_runner.dart';

typedef FileExistsCheck = bool Function(String path);

class AdbLocator {
  final ProcessRunner runner;
  final FileExistsCheck _fileExists;
  final String? _homeDirectory;

  AdbLocator({required this.runner, FileExistsCheck? fileExists, String? homeDirectory})
    : _fileExists = fileExists ?? ((path) => File(path).existsSync()),
      _homeDirectory = homeDirectory ?? Platform.environment[AdbConstants.homeEnvironmentKey];

  Future<String?> locate() async {
    final fromPath = await _locateOnPath();
    if (fromPath != null) {
      return fromPath;
    }
    for (final candidate in _candidatePaths) {
      if (_fileExists(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  List<String> get _candidatePaths {
    final home = _homeDirectory;
    return <String>[
      ...AdbConstants.absoluteSearchPaths,
      if (home != null && home.isNotEmpty) '$home${AdbConstants.pathSeparator}${AdbConstants.homeRelativeSearchPath}',
    ];
  }

  Future<String?> _locateOnPath() async {
    try {
      final outcome = await runner.run(AdbConstants.whichExecutable, const <String>[AdbConstants.adbExecutable]);
      final path = outcome.stdout.trim();
      return outcome.isSuccess && path.isNotEmpty ? path : null;
    } catch (_) {
      return null;
    }
  }
}
