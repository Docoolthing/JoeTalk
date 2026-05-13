import { GoogleGenAI } from '@google/genai';

import { systemTutorInstruction } from '../prompts/tutor_prompt.js';

const defaultModel = 'gemini-2.5-flash';
const openRouterDefaultBaseUrl = 'https://openrouter.ai/api/v1';
const openRouterDefaultModel = 'google/gemini-2.5-flash';

export async function getTutorReply(studentMessage: string): Promise<string> {
  const apiKey = process.env.GEMINI_API_KEY;
  if (apiKey) {
    const ai = new GoogleGenAI({ apiKey });
    const model = process.env.GEMINI_MODEL || defaultModel;
    const response = await ai.models.generateContent({
      model,
      contents: `学生问题: ${studentMessage}`,
      config: {
        systemInstruction: systemTutorInstruction,
        temperature: 0.5,
        maxOutputTokens: 300,
      },
    });

    const reply = response.text?.trim();
    return reply || '我们一步一步来。先告诉我你目前理解到哪里了？';
  }

  const openRouterApiKey = process.env.OPENROUTER_API_KEY;
  if (!openRouterApiKey) {
    throw new Error('Neither GEMINI_API_KEY nor OPENROUTER_API_KEY is set');
  }

  const baseUrl = process.env.OPENAI_BASE_URL || openRouterDefaultBaseUrl;
  const model = process.env.OPENROUTER_MODEL || openRouterDefaultModel;
  const response = await fetch(`${baseUrl}/chat/completions`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${openRouterApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      messages: [
        { role: 'system', content: systemTutorInstruction },
        { role: 'user', content: `学生问题: ${studentMessage}` },
      ],
      temperature: 0.5,
      max_tokens: 300,
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`OpenRouter request failed (${response.status}): ${body}`);
  }

  const data = (await response.json()) as {
    choices?: Array<{ message?: { content?: string } }>;
  };
  const reply = data.choices?.[0]?.message?.content?.trim();
  return reply || '我们一步一步来。先告诉我你目前理解到哪里了？';
}
