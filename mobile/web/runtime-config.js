// Overwritten at container start from BACKEND_BASE_URL (see docker-entrypoint.sh).
// Sync-loaded before Flutter bootstrap so globalThis is set early.
globalThis.__JOETALK_BACKEND_BASE_URL__ = 'https://jobtalk-api.up.railway.app/';