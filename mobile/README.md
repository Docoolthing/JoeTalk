# JoeTalk Mobile (Flutter)

Flutter app skeleton for the Chinese tutor MVP conversation flow.

## Current Scope

- App entry point in `lib/main.dart`
- Conversation feature scaffold in `lib/features/conversation/`
- Voice service scaffolds in `lib/services/`

## Local Run

1. Install Flutter SDK.
2. From `mobile/` initialize native platform folders if needed:
   - `flutter create --platforms=android,ios --project-name joe_talk_mobile --overwrite .`
3. Then run:
   - `flutter pub get`
   - `flutter run --dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000`

Backend URL behavior:

- If `BACKEND_BASE_URL` is provided, it is used.
- Otherwise defaults are:
  - Android: `http://10.0.2.2:3000`
  - iOS/macOS: `http://localhost:3000`
