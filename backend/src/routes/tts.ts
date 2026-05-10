import { Router } from 'express';

import { synthesizeSpeech } from '../services/tts_service.js';

export const ttsRouter = Router();

const maxInputChars = 2000;

ttsRouter.post('/tts', async (req, res) => {
  const text = (req.body?.text as string | undefined)?.trim();
  const voice =
    typeof req.body?.voice === 'string' ? req.body.voice.trim() : undefined;
  const instructions =
    typeof req.body?.instructions === 'string'
      ? req.body.instructions.trim()
      : undefined;

  if (!text) {
    res.status(400).json({ error: 'text is required' });
    return;
  }
  if (text.length > maxInputChars) {
    res
      .status(413)
      .json({ error: `text exceeds ${maxInputChars} characters` });
    return;
  }

  try {
    const result = await synthesizeSpeech(text, { voice, instructions });
    res.json({
      audioBase64: result.audioBase64,
      mimeType: result.mimeType,
      format: result.format,
      model: result.model,
      voice: result.voice,
    });
  } catch (error) {
    console.error('tts error', error);
    const msg = error instanceof Error ? error.message : String(error);
    if (msg.startsWith('TUTOR_TTS_NOT_CONFIGURED:')) {
      res.status(503).json({
        error: 'TTS is not configured',
        detail: msg.replace(/^TUTOR_TTS_NOT_CONFIGURED:\s*/, ''),
      });
      return;
    }
    if (msg.startsWith('TUTOR_TTS_UPSTREAM_AUTH:')) {
      res.status(502).json({
        error: 'TTS API key rejected',
        detail: msg.replace(/^TUTOR_TTS_UPSTREAM_AUTH:\s*/, ''),
      });
      return;
    }
    if (msg.startsWith('TUTOR_TTS_EMPTY_TEXT:')) {
      res.status(400).json({ error: 'text is required' });
      return;
    }
    res.status(500).json({ error: 'TTS service failed' });
  }
});
