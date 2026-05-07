import { spawn, spawnSync } from 'node:child_process';
import { setTimeout as delay } from 'node:timers/promises';

const backendDir = new URL('../backend/', import.meta.url);
const baseUrl = process.env.VERIFY_BASE_URL || 'http://localhost:3100';
const port = new URL(baseUrl).port || '3100';

function runBuild() {
  const result = spawnSync('npm', ['run', 'build'], {
    cwd: backendDir,
    stdio: 'inherit',
    shell: process.platform === 'win32',
  });
  if (result.status !== 0) {
    throw new Error('Backend build failed.');
  }
}

async function waitForHealth(timeoutMs = 15000) {
  const startedAt = Date.now();
  while (Date.now() - startedAt < timeoutMs) {
    try {
      const response = await fetch(`${baseUrl}/health`);
      if (response.ok) {
        return;
      }
    } catch {
      // Retry until timeout.
    }
    await delay(500);
  }
  throw new Error('Backend did not become healthy in time.');
}

async function verifyChat() {
  const response = await fetch(`${baseUrl}/api/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ studentMessage: '请帮助我理解一元二次方程' }),
  });
  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Chat endpoint failed (${response.status}): ${body}`);
  }
  const json = await response.json();
  if (typeof json.reply !== 'string' || json.reply.trim().length === 0) {
    throw new Error('Chat endpoint returned empty reply.');
  }
}

async function main() {
  console.log('1) Building backend...');
  runBuild();

  console.log(`2) Starting backend on ${baseUrl}...`);
  const server = spawn('npm', ['run', 'start'], {
    cwd: backendDir,
    env: { ...process.env, PORT: port },
    shell: process.platform === 'win32',
    stdio: 'inherit',
  });

  try {
    console.log('3) Checking /health...');
    await waitForHealth();
    console.log('4) Checking /api/chat...');
    await verifyChat();
    console.log('MVP backend verification passed.');
  } finally {
    server.kill();
  }
}

main().catch((error) => {
  console.error('MVP verification failed:', error.message);
  process.exit(1);
});
