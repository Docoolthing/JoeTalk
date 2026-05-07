import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'debug_log_config.dart';
import 'debug_log_persist.dart';

/// Global debug capture: in-app list + file (VM) or ingest (web) when [enabled].
class DebugLogService extends ChangeNotifier {
  DebugLogService._();
  static final DebugLogService instance = DebugLogService._();

  static const int _maxEntries = 400;

  /// Master switch: when false, in-app history and external persist are off.
  /// Defaults to off so the log panel and persisted lines stay hidden until
  /// the user turns logging on; [debugPrint] still runs in [log] when
  /// [kDebugMode] is true.
  bool _enabled = false;
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) {
      return;
    }
    _enabled = value;
    notifyListeners();
  }

  final List<String> _lines = [];
  List<String> get lines => List.unmodifiable(_lines);

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  void log(
    String message, {
    String? location,
    String hypothesisId = 'A',
    Map<String, Object?>? data,
  }) {
    final ts = DateTime.now().toIso8601String();
    final text = '[$ts]${location != null ? ' $location' : ''} $message';
    final line = data != null && data.isNotEmpty
        ? '$text | ${_jsonOrString(data)}'
        : text;
    if (kDebugMode) {
      debugPrint('[JoeTalk] $line');
    }
    if (!_enabled) {
      return;
    }
    if (_lines.length >= _maxEntries) {
      _lines.removeAt(0);
    }
    _lines.add(line);
    notifyListeners();

    // #region agent log
    final payload = <String, Object?>{
      'sessionId': kDebugSessionId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': location ?? 'app',
      'message': message,
      'hypothesisId': hypothesisId,
      'data': data,
    };
    unawaited(persistDebugLogLine(jsonEncode(payload)));
    // #endregion
  }
}

String _jsonOrString(Map<String, Object?> data) {
  try {
    return jsonEncode(data);
  } catch (_) {
    return data.toString();
  }
}

/// Shortens strings for debug logs (console + in-app panel stay readable).
String clipDebugText(String text, {int maxChars = 500}) {
  final t = text.trim();
  if (t.isEmpty) {
    return '(empty)';
  }
  if (t.length <= maxChars) {
    return t;
  }
  return '${t.substring(0, maxChars)}… [${t.length} chars total]';
}
