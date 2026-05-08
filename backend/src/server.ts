import 'dotenv/config';

import cors from 'cors';
import express from 'express';

import { chatRouter } from './routes/chat.js';

/** Only when `PORT` is unset (`npm run dev` locally). Railway always injects `PORT`. */
const listenFallback = 3000;

const app = express();
const port = Number(process.env.PORT) || listenFallback;
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

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'joe-talk-backend' });
});

app.listen(port, host, () => {
  console.log(`Backend listening on http://${host}:${port}`);
});
