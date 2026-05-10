import 'dart:js_interop';

import 'package:flutter/foundation.dart' show debugPrint;

/// Reads [web/runtime-config.js], which sets `globalThis.__JOETALK_BACKEND_BASE_URL__`.
///
/// Uses a single dotted `@JS` binding so the compiler emits a direct property read on
/// `globalThis` (avoids extension-type projection edge cases on some web targets).
@JS('globalThis.__JOETALK_BACKEND_BASE_URL__')
external JSString? get _joetalkBackendBaseUrlJs;

String? readRuntimeBackendBaseUrl() {
  final j = _joetalkBackendBaseUrlJs;
  if (j == null) {
    return null;
  }
  final s = j.toDart.trim();
  if (s.isEmpty) {
    return null;
  }
  // Defence in depth: if Railway substitutes `<UNKNOWN>` for an unresolved
  // service-reference variable, `docker-entrypoint.sh` should already reject
  // it at container start. If a stale build slips through, never let a
  // non-URL value propagate to `POST <UNKNOWN>/api/chat`; fall back to the
  // compile-time `--dart-define=BACKEND_BASE_URL` instead.
  if (!s.startsWith('http://') && !s.startsWith('https://')) {
    debugPrint(
      'JoeTalk: ignoring runtime-config BACKEND_BASE_URL "$s" '
      '(not http/https). Check the BACKEND_BASE_URL variable on the web service.',
    );
    return null;
  }
  return s;
}
