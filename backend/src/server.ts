import 'dotenv/config';

import cors from 'cors';
import express from 'express';

import { chatRouter } from './routes/chat.js';

const app = express();
const port = Number(process.env.PORT) || 3000;
const host = process.env.HOST ?? '0.0.0.0';

app.use(cors());
app.use(express.json());
app.use('/api', chatRouter);

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'joe-talk-backend' });
});

app.listen(port, host, () => {
  console.log(`Backend listening on http://${host}:${port}`);
});
