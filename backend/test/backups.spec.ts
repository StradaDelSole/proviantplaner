import { env } from 'cloudflare:test';
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { generateKeyPair, exportJWK, SignJWT, createLocalJWKSet, type KeyLike } from 'jose';
import app from '../src/index';
import { setTestJwks } from '../src/auth';
import { applyTestSchema } from './test-helpers';

describe('B2: /v1/backups – Cloud-Sicherung (R2), Mandantentrennung, 5er-Limit und IBAN-Schutz', () => {
  let privateKey: KeyLike;

  beforeAll(async () => {
    // Schema in Test-D1 anwenden
    await applyTestSchema(env.DB);

    // RSA-Schlüsselpaar für Test-Tokens erzeugen
    const keys = await generateKeyPair('RS256');
    privateKey = keys.privateKey;
    const publicJwk = await exportJWK(keys.publicKey);
    publicJwk.kid = 'backups-test-key';
    publicJwk.alg = 'RS256';
    publicJwk.use = 'sig';

    setTestJwks(createLocalJWKSet({ keys: [publicJwk] }));
  });

  afterAll(() => {
    setTestJwks(null);
  });

  async function createToken(sub: string): Promise<string> {
    return new SignJWT({ email: `${sub}@example.com` })
      .setProtectedHeader({ alg: 'RS256', kid: 'backups-test-key' })
      .setSubject(sub)
      .setIssuer(env.AUTH0_ISSUER_BASE_URL)
      .setAudience(env.AUTH0_AUDIENCE)
      .setIssuedAt()
      .setExpirationTime('1h')
      .sign(privateKey);
  }

  it('POST, GET und GET /:id – Sicherung hochladen, auflisten und herunterladen', async () => {
    const sub = 'auth0|user_backup_test_1';
    const token = await createToken(sub);

    const backupContent = JSON.stringify({
      version: 1,
      trips: [
        {
          trip: { id: 1, name: 'Sommertörn Ostsee', daysCount: 7 },
          stops: [{ id: 1, name: 'Kiel Hafen', dayNumber: 1 }],
          crew: [{ id: 1, name: 'Skipper Hans', isChild: false }],
        },
      ],
    });

    // 1. POST /v1/backups
    const postRes = await app.request(
      '/v1/backups',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          device_id: 'device-iphone-14',
          content: backupContent,
        }),
      },
      env
    );

    expect(postRes.status).toBe(201);
    const postBody = await postRes.json<{
      success: boolean;
      backup: {
        id: string;
        device_id: string;
        size: number;
        created_at: string;
      };
    }>();

    expect(postBody.success).toBe(true);
    expect(postBody.backup.id).toBeDefined();
    expect(postBody.backup.device_id).toBe('device-iphone-14');
    expect(postBody.backup.size).toBe(new TextEncoder().encode(backupContent).length);

    const backupId = postBody.backup.id;

    // 2. GET /v1/backups – Auflisten
    const listRes = await app.request(
      '/v1/backups',
      {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${token}`,
        },
      },
      env
    );

    expect(listRes.status).toBe(200);
    const listBody = await listRes.json<{
      backups: Array<{ id: string; device_id: string; size: number; created_at: string }>;
    }>();

    expect(listBody.backups.length).toBeGreaterThanOrEqual(1);
    const found = listBody.backups.find((b) => b.id === backupId);
    expect(found).toBeDefined();
    expect(found?.device_id).toBe('device-iphone-14');

    // 3. GET /v1/backups/:id – Herunterladen
    const getRes = await app.request(
      `/v1/backups/${backupId}`,
      {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${token}`,
        },
      },
      env
    );

    expect(getRes.status).toBe(200);
    const getBody = await getRes.json<{
      backup: { id: string; device_id: string; size: number; created_at: string };
      content: string;
    }>();

    expect(getBody.backup.id).toBe(backupId);
    expect(getBody.content).toBe(backupContent);
  });

  it('Mandantentrennung: Konto B hat keinen Zugriff auf Sicherung von Konto A', async () => {
    const subA = 'auth0|tenant_user_a';
    const subB = 'auth0|tenant_user_b';
    const tokenA = await createToken(subA);
    const tokenB = await createToken(subB);

    // Konto A lädt Sicherung hoch
    const postResA = await app.request(
      '/v1/backups',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${tokenA}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          device_id: 'device-a',
          content: JSON.stringify({ note: 'Geheime Törndaten von A' }),
        }),
      },
      env
    );
    expect(postResA.status).toBe(201);
    const bodyA = await postResA.json<{ backup: { id: string } }>();
    const backupIdA = bodyA.backup.id;

    // Konto B listet Sicherungen auf -> darf backupIdA nicht sehen
    const listResB = await app.request(
      '/v1/backups',
      {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${tokenB}`,
        },
      },
      env
    );
    expect(listResB.status).toBe(200);
    const listBodyB = await listResB.json<{ backups: Array<{ id: string }> }>();
    const containsA = listBodyB.backups.some((b) => b.id === backupIdA);
    expect(containsA).toBe(false);

    // Konto B versucht direkt /v1/backups/:id von Konto A abzurufen -> 404
    const getResB = await app.request(
      `/v1/backups/${backupIdA}`,
      {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${tokenB}`,
        },
      },
      env
    );
    expect(getResB.status).toBe(404);
    const errorBody = await getResB.json<{ error: { code: string } }>();
    expect(errorBody.error.code).toBe('BACKUP_NOT_FOUND');
  });

  it('Begrenzung auf maximal 5 Sicherungen je Konto (älteste wird gelöscht)', async () => {
    const sub = 'auth0|retention_user_5';
    const token = await createToken(sub);

    const createdIds: string[] = [];

    // 6 Sicherungen nacheinander hochladen
    for (let i = 1; i <= 6; i++) {
      const res = await app.request(
        '/v1/backups',
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            device_id: `device-${i}`,
            content: JSON.stringify({ backupIndex: i, timestamp: Date.now() }),
          }),
        },
        env
      );
      expect(res.status).toBe(201);
      const data = await res.json<{ backup: { id: string } }>();
      createdIds.push(data.backup.id);
      // Kurze Pause für saubere Zeitstempel-Sortierung
      await new Promise((r) => setTimeout(r, 10));
    }

    // Sicherungen auflisten: Genau 5 Stück
    const listRes = await app.request(
      '/v1/backups',
      {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${token}`,
        },
      },
      env
    );
    expect(listRes.status).toBe(200);
    const listBody = await listRes.json<{ backups: Array<{ id: string }> }>();
    expect(listBody.backups.length).toBe(5);

    // Die erste (älteste) Sicherung darf nicht mehr existieren
    const oldestId = createdIds[0];
    expect(listBody.backups.some((b) => b.id === oldestId)).toBe(false);

    // Abruf der ältesten Sicherung liefert 404
    const getOldRes = await app.request(
      `/v1/backups/${oldestId}`,
      {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${token}`,
        },
      },
      env
    );
    expect(getOldRes.status).toBe(404);

    // Die 5 neuesten müssen noch vorhanden sein
    for (let i = 1; i < 6; i++) {
      expect(listBody.backups.some((b) => b.id === createdIds[i])).toBe(true);
    }
  });

  it('Schutz vor Zahlungsdaten: Inhalt mit IBAN wird mit 400 abgewiesen', async () => {
    const sub = 'auth0|iban_protection_user';
    const token = await createToken(sub);

    // 1. Inhalt mit JSON-Key "iban"
    const ibanPayloadKey = JSON.stringify({
      trips: [],
      payment: {
        iban: 'DE89370400440532013000',
      },
    });

    const res1 = await app.request(
      '/v1/backups',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          device_id: 'device-x',
          content: ibanPayloadKey,
        }),
      },
      env
    );
    expect(res1.status).toBe(400);
    const body1 = await res1.json<{ error: { code: string; message: string } }>();
    expect(body1.error.code).toBe('INVALID_BACKUP_CONTENT');

    // 2. Inhalt mit IBAN im Text
    const ibanPayloadText = JSON.stringify({
      trips: [{ note: 'Überweisung an DE89 3704 0044 0532 0130 00' }],
    });

    const res2 = await app.request(
      '/v1/backups',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          device_id: 'device-x',
          content: ibanPayloadText,
        }),
      },
      env
    );
    expect(res2.status).toBe(400);
    const body2 = await res2.json<{ error: { code: string } }>();
    expect(body2.error.code).toBe('INVALID_BACKUP_CONTENT');
  });

  it('Validierung: Fehlende Pflichtfelder führen zu 400 INVALID_INPUT', async () => {
    const sub = 'auth0|validation_user';
    const token = await createToken(sub);

    const res = await app.request(
      '/v1/backups',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          device_id: '',
        }),
      },
      env
    );
    expect(res.status).toBe(400);
    const body = await res.json<{ error: { code: string } }>();
    expect(body.error.code).toBe('INVALID_INPUT');
  });
});
