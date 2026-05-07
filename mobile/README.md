# JoeTalk Mobile (Flutter)

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
   - `flutter run --dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000`

Backend URL behavior:

- If `BACKEND_BASE_URL` is provided, it is used.
- Otherwise defaults are:
  - Android: `http://10.0.2.2:3000`
  - iOS/macOS: `http://localhost:3000`

## Android production build

Use `flutter build appbundle` (Play Store) or `flutter build apk` after configuring signing. See [android/README.md](android/README.md) for `key.properties`, cleartext / HTTPS, and `BACKEND_BASE_URL` with `--dart-define`.

**Hosted backend (e.g. Railway):** your API must be **HTTPS** in release. Pass your deployed base URL with **no** trailing slash, for example:

`flutter build apk --release --dart-define=BACKEND_BASE_URL=https://your-app.up.railway.app`
