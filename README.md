# JoeTalk MVP

Chinese voice tutor mobile app using Flutter + Gemini (through a secure backend proxy).

## Structure

- `mobile/` Flutter app UI + voice flow
- `backend/` Node/TypeScript Gemini proxy API

## Backend setup

1. Copy `.env.example` to `.env` in `backend/`.
2. Set `GEMINI_API_KEY`.
3. Run:
   - `npm install`
   - `npm run dev`

Backend runs on `http://localhost:3000`.

## Mobile setup

1. Install Flutter SDK on your machine.
2. In `mobile/`, run:
   - `flutter pub get`
   - `flutter run`

Android emulator talks to local backend via `http://10.0.2.2:3000`.
