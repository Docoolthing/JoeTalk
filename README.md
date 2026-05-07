# JoeTalk MVP

Chinese voice tutor mobile app using Flutter + Gemini (through a secure backend proxy).

## Structure

- `mobile/` Flutter app UI + voice flow
- `backend/` Node/TypeScript Gemini proxy API

## Backend (local)

1. Copy `backend/.env.example` to `backend/.env`.
2. Set `GEMINI_API_KEY`.
3. Run:
   - `npm --prefix backend install` (or `cd backend && npm install`)
   - `npm --prefix backend run dev`

Backend runs on `http://localhost:3000`.

## Mobile (local)

1. Install Flutter SDK on your machine.
2. In `mobile/`, run:
   - `flutter pub get`
   - `flutter run`

Android emulator talks to the dev machine backend via `http://10.0.2.2:3000` (see `mobile/lib/features/conversation/conversation_page.dart` defaults). Use `--dart-define=BACKEND_BASE_URL=...` to override.

## Railway (host the backend)

The Express API is ready to run on [Railway](https://railway.com/).

1. Push this repository to GitHub (or connect Railway to your Git provider).
2. **New project → Deploy from GitHub** (or the Railway CLI) and add a service.
3. In the service **Settings → Root directory**, set **`backend`**. (Or deploy only the `backend` folder; the `backend/railway.toml` file configures build and health checks.)
4. **Variables** (at minimum):
   - `GEMINI_API_KEY` — your Google AI Studio / Gemini key (mark as **secret**).
5. **Deploy** and wait for the build (`npm ci && npm run build`) and start (`npm start`). Railway sets **`PORT`**; do not set it manually in production.
6. Open the generated public URL; **`GET /health`** should return `{"ok":true,...}` and **`POST /api/chat`** with body `{"studentMessage":"hi"}` should return `{"reply":"..."}` (requires a valid `GEMINI_API_KEY` or `OPENROUTER_*` as in `gemini_service.ts`).

**Mobile app against production:** the release build defaults to `https` and blocks cleartext. Point the app at your Railway **HTTPS** base URL (no trailing slash), for example:

```bash
cd mobile
flutter run --dart-define=BACKEND_BASE_URL=https://your-service.up.railway.app
flutter build appbundle --dart-define=BACKEND_BASE_URL=https://your-service.up.railway.app
```

Use the same pattern for iOS, APK, and web. Details: `backend/README.md`, `mobile/README.md`, `mobile/android/README.md` (cleartext / store builds).
