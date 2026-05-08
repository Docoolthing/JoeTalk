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

The server binds to `process.env.PORT` if set; otherwise it uses the dev fallback in `backend/src/server.ts` (see `listenFallback`).

## Mobile (local)

1. Install Flutter SDK on your machine.
2. In `mobile/`, run:
   - `flutter pub get`
   - `flutter run`

Android emulator → host machine uses the private alias in `conversation_page.dart`. Override the full URL with `--dart-define=BACKEND_BASE_URL=...` or only the host port with `--dart-define=BACKEND_DEV_PORT=...` (must match your local Node listen port from `server.ts`).

## Railway: two services (same repo)

Use **one Railway project** and **two services**, both pointing at this repository:

| Service | Root directory | Config |
|--------|----------------|--------|
| **API** | `backend` | `backend/railway.toml` — Nixpacks, `npm run build` / `npm start` |
| **Web** | `mobile` | `mobile/railway.toml` — Dockerfile, Flutter web + `serve` |

Each service gets its own **`https://…up.railway.app`** URL. Clients use that **HTTPS origin only** (no host port in the URL). Railway sets **`PORT`** inside each container; do **not** set **`PORT`** in the dashboard.

### Deploy the API

1. **New project** on [Railway](https://railway.com/) → **Deploy from GitHub** → add a service.
2. **Settings → Root directory:** `backend`.
3. **Variables:** at least `GEMINI_API_KEY` (secret).
4. Optional: `ALLOWED_ORIGINS=https://your-web.up.railway.app` (comma-separated; omit for permissive CORS while testing).
5. Deploy → **Networking → public URL** → save as **`API_URL`** (no trailing slash).

Verify: `GET <API_URL>/health`, `POST <API_URL>/api/chat` with `{"studentMessage":"hi"}`.

### Deploy the Flutter web app

1. **Add service** (same project) → same repository.
2. **Root directory:** `mobile`.
3. **Variables:** **`BACKEND_BASE_URL`** = **`API_URL`** (required at Docker **build** time).
4. Deploy → public URL for the site. If you use `ALLOWED_ORIGINS` on the API, set it to this web URL and redeploy the API.

Templates: `backend/.env.example`, `mobile/env.deploy.example`.

### Local Flutter web (no Docker)

```bash
cd mobile
flutter build web --release --dart-define=BACKEND_BASE_URL=https://YOUR-API.up.railway.app
```

### One Railway service for both

Possible with a custom image (e.g. Express serving `build/web`), but not how this repo is set up out of the box.

**Mobile / store builds** use **`API_URL`** via `--dart-define`:

```bash
cd mobile
flutter run --dart-define=BACKEND_BASE_URL=https://your-api.up.railway.app
flutter build appbundle --dart-define=BACKEND_BASE_URL=https://your-api.up.railway.app
```

More detail: `backend/README.md`, `mobile/README.md`, `mobile/android/README.md`.
