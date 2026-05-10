import 'dart:js_interop';

extension type _GlobalConfig(JSObject _) implements JSObject {
  @JS('__JOETALK_BACKEND_BASE_URL__')
  external JSString? get joetalkBackendBaseUrl;
}

@JS('globalThis')
external _GlobalConfig get _globalThis;

/// Backend URL injected via [web/runtime-config.js] (e.g. Docker entrypoint).
String? readRuntimeBackendBaseUrl() {
  final s = _globalThis.joetalkBackendBaseUrl?.toDart ?? '';
  if (s.isEmpty) {
    return null;
  }
  return s;
}
