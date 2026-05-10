import 'dotenv/config';

import cors from 'cors';
import express from 'express';

import { chatRouter } from './routes/chat.js';
import { ttsRouter } from './routes/tts.js';

/** Local dev only when `PORT` is unset (`npm run dev`). On Railway, always bind to `process.env.PORT`. */
const localDevPortFallback = 3000;

const app = express();
const port = Number(process.env.PORT) || localDevPortFallback;
const host = process.env.HOST ?? '0.0.0.0';

const allowedOrigins = (process.env.ALLOWED_ORIGINS ?? '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

if (allowedOrigins.length > 0) {
  app.use(cors({ origin: allowedOrigins }));
} else {
  app.use(cors());
}
app.use(express.json());
app.use('/api', chatRouter);
app.use('/api', ttsRouter);

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'joe-talk-backend' });
});

app.listen(port, host, () => {
  console.log(`Backend listening on http://${host}:${port}`);
  if (process.env.RAILWAY_PROJECT_ID) {
    console.log(
      'Railway: use your service HTTPS URL for checks (e.g. GET /health). Do not add :PORT to the public hostname.',
    );
  }
});
