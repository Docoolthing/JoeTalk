import 'package:http/http.dart' as http;

import 'debug_log_config.dart';

/// Sends one log entry to the debug ingest (browser / Flutter web).
Future<void> persistDebugLogLine(String line) async {
  // #region agent log
  try {
    await http
        .post(
          Uri.parse(kDebugIngestUrl),
          headers: {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': kDebugSessionId,
          },
          body: line,
        )
        .timeout(const Duration(seconds: 2));
  } catch (_) {}
  // #endregion
}
