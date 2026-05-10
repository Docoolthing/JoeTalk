#!/bin/sh
set -e

# BACKEND_BASE_URL must be a real HTTPS (or HTTP, for local) URL. Reject empty
# values and Railway's `<UNKNOWN>` placeholder, which appears when a variable
# references a service that does not exist (e.g. `https://${{API.RAILWAY_PUBLIC_DOMAIN}}`
# but no service named `API`). Failing here is much clearer than letting the
# Flutter app POST to a garbage URL and surface "服務位址：<UNKNOWN>" in the UI.
url="${BACKEND_BASE_URL:-}"
if [ -z "$url" ]; then
  echo "JoeTalk web: BACKEND_BASE_URL is unset. Set it on the Railway *web* service (e.g. https://jobtalk-api-production.up.railway.app)." >&2
  exit 1
fi
case "$url" in
  http://*|https://*) ;;
  *)
    echo "JoeTalk web: BACKEND_BASE_URL is not a valid URL: '$url'" >&2
    echo "  - If you used a Railway reference like \${{API.RAILWAY_PUBLIC_DOMAIN}}, confirm that service exists and is deployed." >&2
    echo "  - The value must start with http:// or https:// (e.g. https://jobtalk-api-production.up.railway.app)." >&2
    exit 1
    ;;
esac

node -e "
const fs = require('fs');
const url = process.env.BACKEND_BASE_URL || '';
fs.writeFileSync(
  '/srv/web/runtime-config.js',
  'globalThis.__JOETALK_BACKEND_BASE_URL__=' + JSON.stringify(url) + ';\\n',
);
"
echo "JoeTalk web: runtime-config.js written with BACKEND_BASE_URL=$url"
exec serve -s web -l "tcp://0.0.0.0:${PORT:-8080}"
