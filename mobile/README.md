# JoeTalk Mobile (Flutter)

Monorepo root: [github.com/Docoolthing/JoeTalk](https://github.com/Docoolthing/JoeTalk).

Flutter app skeleton for the Chinese tutor MVP conversation flow.

## Current Scope

- App entry point in `lib/main.dart`
- Conversation feature scaffold in `lib/features/conversation/`
- Voice service scaffolds in `lib/services/`

## Local Run

1. Install Flutter SDK.
2. From `mobile/` the Android project is in `android/` (regenerate with `flutter create --platforms=android --project-name joe_talk_mobile .` if it is missing).
3. Then run:
   - `flutter pub get`
   - `flutter run` (uses dev defaults in `conversation_page.dart` unless you set `--dart-define`)

Backend URL behavior:

- If `BACKEND_BASE_URL` is set (`--dart-define` or build-time for web), it is used.
- Otherwise local defaults use `127.0.0.1` / `10.0.2.2` and **`BACKEND_DEV_PORT`** (`--dart-define=BACKEND_DEV_PORT=...`), matching the Node fallback in `backend/src/server.ts` when neither defines `PORT`.
- Production web (Railway Docker): set **`BACKEND_BASE_URL`** as a **runtime** variable on the web service (entrypoint writes `runtime-config.js`). Optional `--dart-define` still works; see repo root README.

## Android production build

Use `flutter build appbundle` (Play Store) or `flutter build apk` after configuring signing. See [android/README.md](android/README.md) for `key.properties`, cleartext / HTTPS, and `BACKEND_BASE_URL` with `--dart-define`.

**Hosted backend (jobtalk-api on Railway):** use **HTTPS** with **no** trailing slash:

`flutter build apk --release --dart-define=BACKEND_BASE_URL=https://jobtalk-api.up.railway.app`

## Flutter web on Railway

The **`mobile/Dockerfile`** builds the web bundle and serves it with **`serve`**. **`BACKEND_BASE_URL`** is injected when the container starts (no Docker build-arg required). On Railway, add a second service with root **`mobile`**, set **`BACKEND_BASE_URL`** to your backend public URL, and deploy. See repo root **`README.md`** (Railway section) and **`mobile/env.deploy.example`**.
