import { Router } from 'express';

import { getTutorReply } from '../services/gemini_service.js';

export const chatRouter = Router();

chatRouter.post('/chat', async (req, res) => {
  const studentMessage = (req.body?.studentMessage as string | undefined)?.trim();
  const language =
    typeof req.body?.language === 'string' ? req.body.language.trim() : undefined;

  if (!studentMessage) {
    res.status(400).json({ error: 'studentMessage is required' });
    return;
  }

  try {
    const reply = await getTutorReply(studentMessage, language);
    res.json({ reply });
  } catch (error) {
    console.error('chat error', error);
    const msg = error instanceof Error ? error.message : String(error);
    if (msg.startsWith('TUTOR_NOT_CONFIGURED:')) {
      res.status(503).json({
        error: 'Tutor is not configured',
        detail: msg.replace(/^TUTOR_NOT_CONFIGURED:\s*/, ''),
      });
      return;
    }
    if (msg.startsWith('TUTOR_UPSTREAM_AUTH:')) {
      res.status(502).json({
        error: 'Tutor API key rejected',
        detail: msg.replace(/^TUTOR_UPSTREAM_AUTH:\s*/, ''),
      });
      return;
    }
    res.status(500).json({ error: 'Tutor service failed' });
  }
});
