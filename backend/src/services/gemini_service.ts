import { GoogleGenAI } from '@google/genai';

import { buildTutorSystemInstruction } from '../prompts/tutor_prompt.js';

const defaultModel = 'gemini-2.5-flash';
const openRouterDefaultBaseUrl = 'https://openrouter.ai/api/v1';
const openRouterDefaultModel = 'google/gemini-2.5-flash';

function envTrim(name: string): string | undefined {
  const v = process.env[name];
  if (v == null) {
    return undefined;
  }
  // Strip CR/LF so Windows .env line endings don't leak into Bearer tokens or URLs.
  const t = v.replace(/\r/g, '').replace(/\n/g, '').trim();
  return t || undefined;
}

/** OpenRouter-compatible chat/completions base (no trailing slash). */
function normalizeCompletionsBaseUrl(raw: string | undefined): string {
  const fallback = openRouterDefaultBaseUrl;
  const trimmed = (raw ?? '').trim().replace(/\r/g, '').replace(/\n/g, '');
  if (!trimmed) {
    return fallback;
  }
  try {
    const urlNoTrail = trimmed.endsWith('/') ? trimmed.slice(0, -1) : trimmed;
    const u = new URL(urlNoTrail);
    // Avoid http→https redirects: fetch may drop Authorization on cross-scheme redirects.
    if (u.hostname === 'openrouter.ai' && u.protocol === 'http:') {
      u.protocol = 'https:';
    }
    return u.toString().replace(/\/$/, '');
  } catch {
    return fallback;
  }
}

export async function getTutorReply(
  studentMessage: string,
  language?: string,
): Promise<string> {
  const systemInstruction = buildTutorSystemInstruction(language);
  // Prefer GEMINI_API_KEY; GOOGLE_API_KEY is what @google/genai documents for Node.
  const apiKey = envTrim('GEMINI_API_KEY') ?? envTrim('GOOGLE_API_KEY');
  if (apiKey) {
    const ai = new GoogleGenAI({ apiKey });
    const model = process.env.GEMINI_MODEL || defaultModel;
    const response = await ai.models.generateContent({
      model,
      contents: `Student question: ${studentMessage}`,
      config: {
        systemInstruction,
        temperature: 0.5,
        maxOutputTokens: 300,
      },
    });

    const reply = response.text?.trim();
    const fallback =
      normalizeLanguageKey(language) === 'zh-cn'
        ? '我们一步一步来：你目前对哪一部分已经理解了？'
        : "Let's go step by step. What part do you understand so far?";
    return reply || fallback;
  }

  // OpenRouter uses OPENROUTER_API_KEY; many setups use OPENAI_API_KEY for OpenAI-compatible APIs.
  const openRouterApiKey =
    envTrim('OPENROUTER_API_KEY') ?? envTrim('OPENAI_API_KEY');
  if (!openRouterApiKey) {
    throw new Error(
      'TUTOR_NOT_CONFIGURED: Set GEMINI_API_KEY or GOOGLE_API_KEY (Gemini), or OPENROUTER_API_KEY / OPENAI_API_KEY for chat completions.',
    );
  }

  const baseUrl = normalizeCompletionsBaseUrl(envTrim('OPENAI_BASE_URL'));
  const model =
    envTrim('OPENROUTER_MODEL') ||
    envTrim('OPENAI_MODEL') ||
    openRouterDefaultModel;
  const url = `${baseUrl}/chat/completions`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${openRouterApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      messages: [
        { role: 'system', content: systemInstruction },
        { role: 'user', content: `Student question: ${studentMessage}` },
      ],
      temperature: 0.5,
      max_tokens: 300,
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    if (response.status === 401 || response.status === 403) {
      throw new Error(
        `TUTOR_UPSTREAM_AUTH: Chat completions returned ${response.status}. If using OpenRouter, set OPENROUTER_API_KEY (or OPENAI_API_KEY) and OPENAI_BASE_URL=https://openrouter.ai/api/v1. Body: ${body}`,
      );
    }
    throw new Error(`OpenRouter request failed (${response.status}): ${body}`);
  }

  const data = (await response.json()) as {
    choices?: Array<{ message?: { content?: string } }>;
  };
  const reply = data.choices?.[0]?.message?.content?.trim();
  const fallback =
    normalizeLanguageKey(language) === 'zh-cn'
      ? '我们一步一步来：你目前对哪一部分已经理解了？'
      : "Let's go step by step. What part do you understand so far?";
  return reply || fallback;
}

function normalizeLanguageKey(language: string | undefined): string {
  return (language || 'en').trim().toLowerCase().replace(/_/g, '-');
}
