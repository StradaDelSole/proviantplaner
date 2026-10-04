import { env, createExecutionContext, waitOnExecutionContext } from 'cloudflare:test';
import { describe, it, expect } from 'vitest';
import worker from '../src/index';

describe('B0: Backend Endpoints & Routing', () => {
  it('GET /health liefert Status 200 und ok', async () => {
    const request = new Request('http://example.com/health');
    const ctx = createExecutionContext();
    const response = await worker.fetch(request, env, ctx);
    await waitOnExecutionContext(ctx);

    expect(response.status).toBe(200);
    const data = (await response.json()) as { status: string; timestamp: string };
    expect(data.status).toBe('ok');
    expect(data.timestamp).toBeDefined();
  });

  it('GET /v1/info liefert korrekte Metadaten', async () => {
    const request = new Request('http://example.com/v1/info');
    const ctx = createExecutionContext();
    const response = await worker.fetch(request, env, ctx);
    await waitOnExecutionContext(ctx);

    expect(response.status).toBe(200);
    const data = (await response.json()) as { name: string; version: string; environment: string };
    expect(data.name).toBe('proviantplaner-backend');
    expect(data.version).toBe('0.1.0');
    expect(data.environment).toBeDefined();
  });

  it('Unbekannte Route liefert standardisierten 404-Fehler ohne interne Details', async () => {
    const request = new Request('http://example.com/v1/nonexistent');
    const ctx = createExecutionContext();
    const response = await worker.fetch(request, env, ctx);
    await waitOnExecutionContext(ctx);

    expect(response.status).toBe(404);
    const data = (await response.json()) as { error: { code: string; message: string } };
    expect(data.error).toBeDefined();
    expect(data.error.code).toBe('NOT_FOUND');
    expect(data.error.message).toContain('/v1/nonexistent');
  });
});
