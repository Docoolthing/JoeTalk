import 'dart:js_interop';

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
  final s = j.toDart;
  return s.isEmpty ? null : s;
}
