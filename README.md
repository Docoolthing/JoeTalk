# JoeTalk MVP

Chinese voice tutor mobile app using Flutter + Gemini (through a secure backend proxy).

**Repository:** [github.com/Docoolthing/JoeTalk](https://github.com/Docoolthing/JoeTalk)

## Structure

- `mobile/` Flutter app UI + voice flow
- `backend/` Node/TypeScript Gemini proxy API

## Backend (local)

1. Copy `backend/.env.example` to `backend/.env`.
2. Set `GEMINI_API_KEY`.
3. Run:
   - `npm --prefix backend install` (or `cd backend && npm install`)
   - `npm --prefix backend run dev`

The server uses **`process.env.PORT`** when set (**Railway always sets this**). For local `npm run dev` without `PORT`, see `localDevPortFallback` in `backend/src/server.ts`.

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

Each service gets **`https://…up.railway.app`**. Use that origin only—**never append the container `PORT`** to the public URL. Railway maps HTTPS to `$PORT` inside the container automatically.

### Deploy the API

1. **New project** on [Railway](https://railway.com/) → **Deploy from GitHub** → add a service.
2. **Settings → Root directory:** `backend`.
3. **Variables:** at least `GEMINI_API_KEY` (secret).
4. Optional: `ALLOWED_ORIGINS` set to your **web** app’s `https://…up.railway.app` origin after the web service exists (comma-separated; omit for permissive CORS while testing).
5. Deploy → **Networking → public URL**. Production API for this project: **`https://jobtalk-api.up.railway.app`** (no trailing slash)—use as **`BACKEND_BASE_URL`** for mobile/web clients.

Verify: `GET https://jobtalk-api.up.railway.app/health`, `POST …/api/chat` with `{"studentMessage":"hi"}`.

### Deploy the Flutter web app

1. **Add service** (same project) → same repository.
2. **Root directory:** `mobile`.
3. **Variables:** **`BACKEND_BASE_URL`** = `https://jobtalk-api.up.railway.app` (required at container **runtime** for Docker; trailing slash optional).
4. Deploy → public URL for the site. If you use `ALLOWED_ORIGINS` on the API, set it to this web URL and redeploy the API.

Templates: `backend/.env.example`, `mobile/env.deploy.example`.

### Local Flutter web (no Docker)

```bash
cd mobile
flutter build web --release --dart-define=BACKEND_BASE_URL=https://jobtalk-api.up.railway.app
```

### Troubleshooting Railway

- **Status bar shows `服務位址：<UNKNOWN>` and backend never responds.** The web service's `BACKEND_BASE_URL` is set to a Railway service reference (e.g. `https://${{api.RAILWAY_PUBLIC_DOMAIN}}`) whose target service does not exist or is renamed. Railway substitutes the literal placeholder `<UNKNOWN>`. Fix in the web service's **Variables**: either set `BACKEND_BASE_URL` to a literal HTTPS URL like `https://jobtalk-api.up.railway.app`, or correct the referenced service name. After the next deploy, `https://<web>.up.railway.app/runtime-config.js` should contain your real URL. The container entrypoint now rejects empty / non-URL values up front so this fails fast instead of shipping a broken site.
- **API hostname returns 404 from Railway's edge.** That's "no service answering on this hostname", not your app. Check the API service has a healthy latest deploy and a public domain attached, then copy that exact `*.up.railway.app` URL into the web service's `BACKEND_BASE_URL`. Verify with `curl https://<api>.up.railway.app/health` → `{"ok":true,…}`.
- **`/api/chat` returns 502 with `Tutor API key rejected`.** Upstream key invalid; see `backend/README.md`.

### One Railway service for both

Possible with a custom image (e.g. Express serving `build/web`), but not how this repo is set up out of the box.

**Mobile / store builds** use **`BACKEND_BASE_URL`** via `--dart-define`:

```bash
cd mobile
flutter run --dart-define=BACKEND_BASE_URL=https://jobtalk-api.up.railway.app
flutter build appbundle --dart-define=BACKEND_BASE_URL=https://jobtalk-api.up.railway.app
```

More detail: `backend/README.md`, `mobile/README.md`, `mobile/android/README.md`.
