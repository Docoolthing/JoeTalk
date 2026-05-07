import 'dart:io';

import 'package:path/path.dart' as p;

/// Appends one NDJSON line to the session log file (VM / desktop / mobile).
Future<void> persistDebugLogLine(String line) async {
  // #region agent log
  try {
    final cwd = Directory.current.path;
    final isMobileSubdir = p.basename(cwd) == 'mobile';
    final path = isMobileSubdir
        ? p.normalize(p.join(cwd, '..', 'debug-224550.log'))
        : p.normalize(p.join(cwd, 'debug-224550.log'));
    final f = File(path);
    await f.writeAsString(
      line.endsWith('\n') ? line : '$line\n',
      mode: FileMode.append,
      flush: true,
    );
  } catch (_) {}
  // #endregion
}
