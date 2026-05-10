/**
 * Server-side text-to-speech via OpenAI's `/v1/audio/speech` endpoint.
 *
 * This is OpenAI **direct**, not OpenRouter — `OPENAI_BASE_URL` (which the chat
 * service uses for OpenRouter) is intentionally ignored here because OpenRouter
 * does not proxy the audio/speech endpoint. The function therefore reads
 * `OPENAI_TTS_API_KEY` first, then falls back to `OPENAI_API_KEY` (in case the
 * user already configured a real OpenAI key for chat).
 */

const openAiTtsUrl = 'https://api.openai.com/v1/audio/speech';
const defaultModel = 'gpt-4o-mini-tts';
const defaultVoice = 'nova';
const defaultFormat: SupportedFormat = 'mp3';

type SupportedFormat = 'mp3' | 'wav' | 'opus' | 'aac' | 'flac';

const formatMimeTypes: Record<SupportedFormat, string> = {
  mp3: 'audio/mpeg',
  wav: 'audio/wav',
  opus: 'audio/ogg',
  aac: 'audio/aac',
  flac: 'audio/flac',
};

function envTrim(name: string): string | undefined {
  const v = process.env[name];
  if (v == null) {
    return undefined;
  }
  const t = v.replace(/\r/g, '').replace(/\n/g, '').trim();
  return t || undefined;
}

function resolveFormat(raw: string | undefined): SupportedFormat {
  const v = (raw ?? '').toLowerCase();
  if (v in formatMimeTypes) {
    return v as SupportedFormat;
  }
  return defaultFormat;
}

export interface SynthesizedSpeech {
  audioBase64: string;
  mimeType: string;
  format: SupportedFormat;
  model: string;
  voice: string;
}

export interface SynthesizeOptions {
  /** Optional voice override (e.g. `nova`, `shimmer`, `coral`, `sage`, `alloy`). */
  voice?: string;
  /** Hint sent to the model via `instructions` (e.g. "speak slowly and clearly for a child"). */
  instructions?: string;
}

export async function synthesizeSpeech(
  text: string,
  options: SynthesizeOptions = {},
): Promise<SynthesizedSpeech> {
  const apiKey = envTrim('OPENAI_TTS_API_KEY') ?? envTrim('OPENAI_API_KEY');
  if (!apiKey) {
    throw new Error(
      'TUTOR_TTS_NOT_CONFIGURED: Set OPENAI_TTS_API_KEY (or OPENAI_API_KEY) to a real OpenAI API key to enable cloud TTS. OpenRouter keys (sk-or-…) are not accepted because OpenRouter does not proxy /v1/audio/speech.',
    );
  }
  if (apiKey.startsWith('sk-or-')) {
    throw new Error(
      'TUTOR_TTS_NOT_CONFIGURED: OPENAI_API_KEY looks like an OpenRouter key (sk-or-…). Set OPENAI_TTS_API_KEY to a real OpenAI key for cloud TTS.',
    );
  }

  const trimmed = text.trim();
  if (!trimmed) {
    throw new Error('TUTOR_TTS_EMPTY_TEXT: text is required');
  }

  const model = envTrim('OPENAI_TTS_MODEL') ?? defaultModel;
  const voice = options.voice?.trim() || envTrim('OPENAI_TTS_VOICE') || defaultVoice;
  const format = resolveFormat(envTrim('OPENAI_TTS_FORMAT'));

  // OpenAI auto-detects language from the input text, so we don't pass `language`.
  // `instructions` is supported only by `gpt-4o-mini-tts` / `gpt-4o-tts` (silently ignored by tts-1).
  const body: Record<string, unknown> = {
    model,
    voice,
    input: trimmed,
    response_format: format,
  };
  if (options.instructions) {
    body.instructions = options.instructions;
  }

  const response = await fetch(openAiTtsUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const errBody = await response.text();
    if (response.status === 401 || response.status === 403) {
      throw new Error(
        `TUTOR_TTS_UPSTREAM_AUTH: OpenAI TTS returned ${response.status}. Verify OPENAI_TTS_API_KEY is a valid OpenAI API key. Body: ${errBody}`,
      );
    }
    throw new Error(
      `TUTOR_TTS_UPSTREAM_ERROR: OpenAI TTS request failed (${response.status}): ${errBody}`,
    );
  }

  const arrayBuffer = await response.arrayBuffer();
  const audioBase64 = Buffer.from(arrayBuffer).toString('base64');

  return {
    audioBase64,
    mimeType: formatMimeTypes[format],
    format,
    model,
    voice,
  };
}
