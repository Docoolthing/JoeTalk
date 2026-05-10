#!/bin/sh
set -e
if [ -z "${BACKEND_BASE_URL:-}" ]; then
  echo "JoeTalk web: set BACKEND_BASE_URL (Railway Variables). Runtime injection writes web/runtime-config.js." >&2
  exit 1
fi
node -e "
const fs = require('fs');
const url = process.env.BACKEND_BASE_URL || '';
fs.writeFileSync(
  '/srv/web/runtime-config.js',
  'globalThis.__JOETALK_BACKEND_BASE_URL__=' + JSON.stringify(url) + ';\\n',
);
"
exec serve -s web -l "tcp://0.0.0.0:${PORT:-8080}"
