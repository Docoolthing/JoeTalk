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

Default local URL: `http://localhost:3000`.

## Production (Railway)

This folder includes `railway.toml` (build, start, `/health` check).

1. Create a [Railway](https://railway.com/) project and connect this repository.
2. Set the service **root directory** to **`backend`**.
3. Add environment variables in Railway (same names as `.env.example`); **`GEMINI_API_KEY`** is required unless you use **OpenRouter** keys instead (see `src/services/gemini_service.ts`).
4. **Do not** set `PORT` in Railway; the platform provides it. The server binds to `0.0.0.0` and the assigned port.
5. After deploy, use the public **HTTPS** URL as `BACKEND_BASE_URL` for the Flutter app (`--dart-define=BACKEND_BASE_URL=...`).

Troubleshooting: if the build fails, run `npm ci && npm run build` locally in `backend/` and fix any errors. Health check path is `GET /health`.
