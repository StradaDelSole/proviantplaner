import { env } from 'cloudflare:test';
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { generateKeyPair, exportJWK, SignJWT, createLocalJWKSet, type KeyLike, type JWK } from 'jose';
import app from '../src/index';
import { setTestJwks } from '../src/auth';
import { applyTestSchema } from './test-helpers';

describe('B1: Authentifizierung & JWT-Validierung', () => {
  let privateKey: KeyLike;
  let publicKey: KeyLike;
  let publicJwk: JWK;

  let otherPrivateKey: KeyLike;

  beforeAll(async () => {
    // D1-Schema migrieren
    await applyTestSchema(env.DB);

    // RSA-Schlüsselpaar generieren
    const keys = await generateKeyPair('RS256');
    privateKey = keys.privateKey;
    publicKey = keys.publicKey;

    publicJwk = await exportJWK(publicKey);
    publicJwk.kid = 'test-key-1';
    publicJwk.alg = 'RS256';
    publicJwk.use = 'sig';

    // Zweites, fremdes Schlüsselpaar für Signaturprüfung
    const otherKeys = await generateKeyPair('RS256');
    otherPrivateKey = otherKeys.privateKey;

    // Test-JWKS injizieren
    const testKeySet = createLocalJWKSet({
      keys: [publicJwk],
    });
    setTestJwks(testKeySet);
  });

  afterAll(() => {
    setTestJwks(null);
  });

  async function createTestToken(options?: {
    sub?: string;
    email?: string;
    issuer?: string;
    audience?: string;
    expiresIn?: string;
    key?: KeyLike;
  }): Promise<string> {
    const key = options?.key ?? privateKey;
    const jwt = new SignJWT({
      email: options?.email ?? 'skipper@example.com',
    })
      .setProtectedHeader({ alg: 'RS256', kid: 'test-key-1' })
      .setSubject(options?.sub ?? 'auth0|user_123456')
      .setIssuer(options?.issuer ?? env.AUTH0_ISSUER_BASE_URL)
      .setAudience(options?.audience ?? env.AUTH0_AUDIENCE)
      .setIssuedAt()
      .setExpirationTime(options?.expiresIn ?? '1h');

    return jwt.sign(key);
  }

  it('Lehnt Anfrage ohne Authorization-Header ab (401 UNAUTHORIZED)', async () => {
    const res = await app.request('/v1/me', {
      method: 'GET',
    }, env);

    expect(res.status).toBe(401);
    const data = await res.json<{ error: { code: string; message: string } }>();
    expect(data.error.code).toBe('UNAUTHORIZED');
  });

  it('Lehnt Anfrage mit ungültigem Header-Format ab (401 UNAUTHORIZED)', async () => {
    const res = await app.request('/v1/me', {
      method: 'GET',
      headers: {
        Authorization: 'Basic 12345',
      },
    }, env);

    expect(res.status).toBe(401);
    const data = await res.json<{ error: { code: string; message: string } }>();
    expect(data.error.code).toBe('UNAUTHORIZED');
  });

  it('Lehnt abgelaufenes Token ab (401 UNAUTHORIZED)', async () => {
    const expiredToken = await createTestToken({
      expiresIn: '-10s',
    });

    const res = await app.request('/v1/me', {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${expiredToken}`,
      },
    }, env);

    expect(res.status).toBe(401);
    const data = await res.json<{ error: { code: string; message: string } }>();
    expect(data.error.code).toBe('UNAUTHORIZED');
    expect(data.error.message).toContain('abgelaufen');
  });

  it('Lehnt Token mit falschem Issuer ab (401 UNAUTHORIZED)', async () => {
    const wrongIssuerToken = await createTestToken({
      issuer: 'https://attacker.example.com/',
    });

    const res = await app.request('/v1/me', {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${wrongIssuerToken}`,
      },
    }, env);

    expect(res.status).toBe(401);
    const data = await res.json<{ error: { code: string; message: string } }>();
    expect(data.error.code).toBe('UNAUTHORIZED');
  });

  it('Lehnt Token mit falscher Audience ab (401 UNAUTHORIZED)', async () => {
    const wrongAudienceToken = await createTestToken({
      audience: 'https://wrong-api.example.com',
    });

    const res = await app.request('/v1/me', {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${wrongAudienceToken}`,
      },
    }, env);

    expect(res.status).toBe(401);
    const data = await res.json<{ error: { code: string; message: string } }>();
    expect(data.error.code).toBe('UNAUTHORIZED');
  });

  it('Lehnt manipuliertes Token / fremde Signatur ab (401 UNAUTHORIZED)', async () => {
    const forgedToken = await createTestToken({
      key: otherPrivateKey,
    });

    const res = await app.request('/v1/me', {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${forgedToken}`,
      },
    }, env);

    expect(res.status).toBe(401);
    const data = await res.json<{ error: { code: string; message: string } }>();
    expect(data.error.code).toBe('UNAUTHORIZED');
  });

  it('Akzeptiert gültiges Token und liefert 200 OK', async () => {
    const validToken = await createTestToken({
      sub: 'auth0|test_skipper_valid',
    });

    const res = await app.request('/v1/me', {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${validToken}`,
      },
    }, env);

    expect(res.status).toBe(200);
    const data = await res.json<{ account: { auth0_sub: string } }>();
    expect(data.account.auth0_sub).toBe('auth0|test_skipper_valid');
  });
});
