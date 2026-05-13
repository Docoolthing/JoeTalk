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

Default server URL: `http://localhost:3000`.
