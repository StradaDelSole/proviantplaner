import { env } from 'cloudflare:test';
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { generateKeyPair, exportJWK, SignJWT, createLocalJWKSet, type KeyLike } from 'jose';
import app from '../src/index';
import { setTestJwks } from '../src/auth';
import { applyTestSchema } from './test-helpers';

describe('B1: /v1/me, Einwilligungen und Kontolöschung', () => {
  let privateKey: KeyLike;

  beforeAll(async () => {
    // Migrationen anwenden
    await applyTestSchema(env.DB);

    // RSA-Schlüsselpaar generieren und injizieren
    const keys = await generateKeyPair('RS256');
    privateKey = keys.privateKey;
    const publicJwk = await exportJWK(keys.publicKey);
    publicJwk.kid = 'me-test-key';
    publicJwk.alg = 'RS256';
    publicJwk.use = 'sig';

    setTestJwks(createLocalJWKSet({ keys: [publicJwk] }));
  });

  afterAll(() => {
    setTestJwks(null);
  });

  async function createToken(sub: string): Promise<string> {
    return new SignJWT({ email: `${sub}@example.com` })
      .setProtectedHeader({ alg: 'RS256', kid: 'me-test-key' })
      .setSubject(sub)
      .setIssuer(env.AUTH0_ISSUER_BASE_URL)
      .setAudience(env.AUTH0_AUDIENCE)
      .setIssuedAt()
      .setExpirationTime('1h')
      .sign(privateKey);
  }

  it('/v1/me legt neues Konto in D1 an und liefert Profildaten', async () => {
    const sub = 'auth0|test_me_user_1';
    const token = await createToken(sub);

    const res = await app.request('/v1/me', {
      method: 'GET',
      headers: { Authorization: `Bearer ${token}` },
    }, env);

    expect(res.status).toBe(200);
    const body = await res.json<{
      account: { id: string; auth0_sub: string };
      consents: Record<string, unknown>;
      charter_memberships: unknown[];
    }>();

    expect(body.account.auth0_sub).toBe(sub);
    expect(body.account.id).toBeDefined();

    // Verifizieren, dass Konto in D1 existiert
    const dbAccount = await env.DB.prepare('SELECT * FROM accounts WHERE auth0_sub = ?')
      .bind(sub)
      .first<{ id: string; auth0_sub: string }>();

    expect(dbAccount).toBeDefined();
    expect(dbAccount?.id).toBe(body.account.id);

    // Zweiter Aufruf liefert dieselbe ID
    const res2 = await app.request('/v1/me', {
      method: 'GET',
      headers: { Authorization: `Bearer ${token}` },
    }, env);
    const body2 = await res2.json<{ account: { id: string } }>();
    expect(body2.account.id).toBe(body.account.id);
  });

  it('PUT /v1/consents/boat-market-news validiert Eingaben und speichert Textversion', async () => {
    const sub = 'auth0|test_me_user_consents';
    const token = await createToken(sub);

    // Ungültige Eingabe (fehlende text_version) -> 400
    const badRes = await app.request('/v1/consents/boat-market-news', {
      method: 'PUT',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ granted: true }),
    }, env);
    expect(badRes.status).toBe(400);

    // Gültige Einwilligung erteilen
    const putRes = await app.request('/v1/consents/boat-market-news', {
      method: 'PUT',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        granted: true,
        text_version: 'v1.0',
      }),
    }, env);

    expect(putRes.status).toBe(200);
    const putBody = await putRes.json<{
      success: boolean;
      consent: {
        type: string;
        granted: boolean;
        text_version: string;
        granted_at: string | null;
        withdrawn_at: string | null;
      };
    }>();

    expect(putBody.success).toBe(true);
    expect(putBody.consent.granted).toBe(true);
    expect(putBody.consent.text_version).toBe('v1.0');
    expect(putBody.consent.granted_at).not.toBeNull();
    expect(putBody.consent.withdrawn_at).toBeNull();

    // In /v1/me prüfen
    const meRes = await app.request('/v1/me', {
      method: 'GET',
      headers: { Authorization: `Bearer ${token}` },
    }, env);
    const meBody = await meRes.json<{
      consents: {
        boat_market_news?: { granted: boolean; text_version: string };
      };
    }>();
    expect(meBody.consents.boat_market_news?.granted).toBe(true);
    expect(meBody.consents.boat_market_news?.text_version).toBe('v1.0');

    // Einwilligung widerrufen
    const revokeRes = await app.request('/v1/consents/boat-market-news', {
      method: 'PUT',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        granted: false,
        text_version: 'v1.0',
      }),
    }, env);

    expect(revokeRes.status).toBe(200);
    const revokeBody = await revokeRes.json<{
      consent: { granted: boolean; withdrawn_at: string | null };
    }>();
    expect(revokeBody.consent.granted).toBe(false);
    expect(revokeBody.consent.withdrawn_at).not.toBeNull();
  });

  it('DELETE /v1/me löscht Konto, D1-Daten (Cascade) und R2-Sicherungen', async () => {
    const sub = 'auth0|test_me_user_delete';
    const token = await createToken(sub);

    // 1. Konto über GET /v1/me erzeugen
    const meRes = await app.request('/v1/me', {
      method: 'GET',
      headers: { Authorization: `Bearer ${token}` },
    }, env);
    const meBody = await meRes.json<{ account: { id: string } }>();
    const accountId = meBody.account.id;

    // 2. Einwilligung und Sicherung anlegen
    await app.request('/v1/consents/boat-market-news', {
      method: 'PUT',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ granted: true, text_version: 'v1.0' }),
    }, env);

    // R2-Objekt anlegen und in D1 erfassen
    const r2Key = `backups/${accountId}/test-backup.json`;
    await env.BACKUPS_BUCKET.put(r2Key, JSON.stringify({ trips: [] }));
    await env.DB.prepare(
      'INSERT INTO backups (id, account_id, device_id, r2_key, size) VALUES (?, ?, ?, ?, ?)'
    ).bind('backup-1', accountId, 'device-test', r2Key, 100).run();

    // Verifizieren, dass R2-Objekt existiert
    expect(await env.BACKUPS_BUCKET.head(r2Key)).not.toBeNull();

    // 3. DELETE /v1/me ausführen
    const deleteRes = await app.request('/v1/me', {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` },
    }, env);

    expect(deleteRes.status).toBe(200);
    const deleteBody = await deleteRes.json<{ success: boolean }>();
    expect(deleteBody.success).toBe(true);

    // 4. Prüfen, dass alles gelöscht ist
    const accountInDb = await env.DB.prepare('SELECT * FROM accounts WHERE id = ?')
      .bind(accountId)
      .first();
    expect(accountInDb).toBeNull();

    const consentsInDb = await env.DB.prepare('SELECT * FROM consents WHERE account_id = ?')
      .bind(accountId)
      .all();
    expect(consentsInDb.results?.length).toBe(0);

    const backupsInDb = await env.DB.prepare('SELECT * FROM backups WHERE account_id = ?')
      .bind(accountId)
      .all();
    expect(backupsInDb.results?.length).toBe(0);

    // R2-Objekt muss gelöscht sein
    expect(await env.BACKUPS_BUCKET.head(r2Key)).toBeNull();

    // Erneuter Aufruf liefert 404
    const secondDeleteRes = await app.request('/v1/me', {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` },
    }, env);
    expect(secondDeleteRes.status).toBe(404);
  });
});
