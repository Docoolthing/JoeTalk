# JoeTalk Backend Proxy (Node + TypeScript)

Backend proxy skeleton for Gemini tutor responses.

## Current Scope

- Express server in `src/server.ts`
- Chat route in `src/routes/chat.ts`
- Tutor prompt template in `src/prompts/tutor_prompt.ts`
- Gemini service adapter in `src/services/gemini_service.ts`

## Local Run

1. Copy `.env.example` to `.env`.
2. Set `GEMINI_API_KEY`.
3. Install and run:
   - `npm install`
   - `npm run dev`

Local URL: `http://127.0.0.1:<port>` where `<port>` is `process.env.PORT` or the dev fallback in `src/server.ts`.

## Production (Railway)

This folder includes `railway.toml` (build, start, `/health` check).

1. Create a [Railway](https://railway.com/) project and connect this repository.
2. Set the service **root directory** to **`backend`**.
3. Add environment variables in Railway (same names as `.env.example`); **`GEMINI_API_KEY`** is required unless you use **OpenRouter** keys instead (see `src/services/gemini_service.ts`).
4. **Do not** set `PORT` in Railway; the platform provides it. The server binds to `0.0.0.0` and the assigned port.
5. After deploy, copy the public **HTTPS** URL (no trailing slash) and use it as **`BACKEND_BASE_URL`** for the Flutter web/API client (`--dart-define` or the web service variable described in the repo root `README.md`).
6. Optional: set **`ALLOWED_ORIGINS`** to your Flutter web origin (comma-separated) so only that site can call the API from the browser. Leave unset in dev to allow all origins (`cors()` default).

Troubleshooting: if the build fails, run `npm ci && npm run build` locally in `backend/` and fix any errors. Health check path is `GET /health`.

If the mobile app reaches the backend but `/api/chat` returns **502** with `Tutor API key rejected`, the upstream key is invalid or expired (e.g. OpenRouter **401** "User not found"). Set a working **`GEMINI_API_KEY`** or **`GOOGLE_API_KEY`**, or replace **`OPENROUTER_API_KEY`** in `.env`.
