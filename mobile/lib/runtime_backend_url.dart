import 'runtime_backend_url_stub.dart'
    if (dart.library.js_interop) 'runtime_backend_url_web.dart' as rb;

/// Backend URL from [web/runtime-config.js] when running on web; otherwise null.
String? readRuntimeBackendBaseUrl() => rb.readRuntimeBackendBaseUrl();
