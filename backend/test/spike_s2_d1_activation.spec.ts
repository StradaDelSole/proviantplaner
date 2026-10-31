import { env } from 'cloudflare:test';
import { describe, it, expect, beforeAll } from 'vitest';
import migrationSql from '../migrations/0001_initial_schema.sql?raw';

describe('Spike S2: D1 Conditional Activation, Concurrency, Idempotency & GC Fencing', () => {
  async function applyMigrations(db: any) {
    const statements = migrationSql
      .split(';')
      .map((s: string) => s.trim())
      .filter((s: string) => s.length > 0);

    for (const stmt of statements) {
      await db.prepare(stmt).run();
    }

    // HINWEIS ZUR ARCHITEKTUR-ABGRENZUNG:
    // Die folgenden v2-Schemafelder werden ausschließlich im Test-Harness zu Verifikationszwecken
    // der Phase-A-Integritätsmodelle (ADR-BC-003/004) angelegt. Sie stellen noch KEINE
    // produktive D1-Migrationsdatei dar; die formale Migration 0002 erfolgt in Phase B.
    const v2Statements = [
      "ALTER TABLE accounts ADD COLUMN status TEXT NOT NULL DEFAULT 'active'",
      "ALTER TABLE accounts ADD COLUMN tier TEXT NOT NULL DEFAULT 'trial'",
      "ALTER TABLE accounts ADD COLUMN generation INTEGER NOT NULL DEFAULT 1",
      "ALTER TABLE backups ADD COLUMN status TEXT NOT NULL DEFAULT 'active'",
      "ALTER TABLE backups ADD COLUMN request_id TEXT",
      "ALTER TABLE backups ADD COLUMN lease_expires_at TEXT",
      "ALTER TABLE backups ADD COLUMN lease_expires_at_epoch INTEGER",
      "ALTER TABLE backups ADD COLUMN generation INTEGER NOT NULL DEFAULT 1",
      "CREATE INDEX IF NOT EXISTS idx_backups_account_status ON backups(account_id, status, created_at DESC)",
      "CREATE INDEX IF NOT EXISTS idx_backups_gc_sweep ON backups(status, lease_expires_at_epoch)",
      "CREATE UNIQUE INDEX IF NOT EXISTS idx_backups_account_req_id ON backups(account_id, request_id)",
    ];

    for (const stmt of v2Statements) {
      try {
        await db.prepare(stmt).run();
      } catch (err: any) {
        if (!err.message?.includes('duplicate column') && !err.message?.includes('already exists')) {
          throw err;
        }
      }
    }
  }

  beforeAll(async () => {
    await applyMigrations(env.DB);
  });

  it('S2.1: Reale D1-Migration aus 0001_initial_schema.sql erfolgreich geladen', async () => {
    const tables = await env.DB.prepare(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='accounts'"
    ).first<{ name: string }>();
    expect(tables?.name).toBe('accounts');
  });

  it('S2.2: Conditional Activation (CAS) scheitert bei gelöschtem Account und liefert HTTP 404', async () => {
    const accountId = 'acc_del_race_1';
    const sub = 'auth0|del_race_user';
    const now = new Date().toISOString();

    // 1. Account anlegen
    await env.DB.prepare(
      "INSERT INTO accounts (id, auth0_sub, status, generation, created_at) VALUES (?, ?, 'active', 1, ?)"
    ).bind(accountId, sub, now).run();

    // 2. Backup reservieren (pending)
    const backupId = 'b_pending_1';
    const leaseExp = new Date(Date.now() + 5 * 60 * 1000).toISOString();
    const leaseEpoch = Math.floor(Date.now() / 1000) + 300;
    await env.DB.prepare(
      `INSERT INTO backups (id, account_id, device_id, r2_key, size, status, generation, lease_expires_at, lease_expires_at_epoch, created_at)
       VALUES (?, ?, 'dev_1', 'r2_key_1', 0, 'pending', 1, ?, ?, ?)`
    ).bind(backupId, accountId, leaseExp, leaseEpoch, now).run();

    // 3. Delete Race: Nutzer löscht Konto, status wird 'deleted' und generation inkrementiert
    await env.DB.prepare(
      "UPDATE accounts SET status = 'deleted', deleted_at = datetime('now'), generation = generation + 1 WHERE id = ?"
    ).bind(accountId).run();

    // Simulierter Worker CAS-Aktivierungs-Handler:
    async function activateBackupCas(bId: string, accId: string, sizeBytes: number) {
      const updateResult = await env.DB.prepare(
        `UPDATE backups 
         SET status = 'active', size = ?
         WHERE id = ? 
           AND account_id = ? 
           AND status = 'pending'
           AND (SELECT status FROM accounts WHERE id = ?) = 'active'
           AND generation = (SELECT generation FROM accounts WHERE id = ?)`
      ).bind(sizeBytes, bId, accId, accId, accId).run();

      // Bei 0 Änderungen: Account wurde gelöscht oder Backup existiert nicht mehr -> HTTP 404
      if (updateResult.meta.changes === 0) {
        return { status: 404, error: 'Account not found or deleted' };
      }
      return { status: 200, activated: true };
    }

    const res = await activateBackupCas(backupId, accountId, 12345);
    expect(res.status).toBe(404);
    expect(res.error).toBe('Account not found or deleted');

    // Backup bleibt 'pending' und wird dem Nutzer niemals als 'active' ausgeliefert
    const backup = await env.DB.prepare(
      "SELECT status FROM backups WHERE id = ?"
    ).bind(backupId).first<{ status: string }>();
    expect(backup?.status).toBe('pending');

    // GET /v1/backups liefert nur active -> 0 Backups
    const visible = await env.DB.prepare(
      "SELECT count(*) as cnt FROM backups WHERE account_id = ? AND status = 'active'"
    ).bind(accountId).first<{ cnt: number }>();
    expect(visible?.cnt).toBe(0);
  });

  describe('S2.3: Idempotenz vs. Konflikte bei wiederholter Request-ID', () => {
    it('S2.3a: Identischer Retry liefert bestehendes Backup (Idempotenz)', async () => {
      const accountId = 'acc_idempotent_1';
      const sub = 'auth0|idempotent_user_1';
      const reqId = 'client_req_unique_111';
      const now = new Date().toISOString();

      await env.DB.prepare(
        "INSERT INTO accounts (id, auth0_sub, status, generation, created_at) VALUES (?, ?, 'active', 1, ?)"
      ).bind(accountId, sub, now).run();

      // Erster Upload
      await env.DB.prepare(
        `INSERT INTO backups (id, account_id, device_id, r2_key, size, status, request_id, created_at)
         VALUES ('b_idemp_orig', ?, 'dev_1', 'key_1', 100, 'active', ?, ?)`
      ).bind(accountId, reqId, now).run();

      // Simulierter Worker-Handler mit Idempotenz-Prüfung:
      async function handleUpload(accId: string, bId: string, rId: string) {
        const existing = await env.DB.prepare(
          "SELECT id, size, created_at FROM backups WHERE account_id = ? AND request_id = ?"
        ).bind(accId, rId).first<{ id: string; size: number }>();

        if (existing) {
          if (existing.id === bId) {
            return { status: 200, idempotentReplay: true, id: existing.id };
          } else {
            return { status: 409, error: 'Conflict: request_id already used with different backup_id' };
          }
        }

        await env.DB.prepare(
          `INSERT INTO backups (id, account_id, device_id, r2_key, size, status, request_id, created_at)
           VALUES (?, ?, 'dev_1', 'key_new', 100, 'active', ?, datetime('now'))`
        ).bind(bId, accId, rId).run();

        return { status: 201, created: true, id: bId };
      }

      // Wiederholung mit identischer Backup-ID -> 200 OK Idempotent Replay
      const replay = await handleUpload(accountId, 'b_idemp_orig', reqId);
      expect(replay.status).toBe(200);
      expect(replay.idempotentReplay).toBe(true);
      expect(replay.id).toBe('b_idemp_orig');

      // Wiederholung mit ANDERER Backup-ID bei gleicher request_id -> 409 Conflict
      const conflict = await handleUpload(accountId, 'b_idemp_DIFFERENT', reqId);
      expect(conflict.status).toBe(409);
      expect(conflict.error).toContain('Conflict');
    });

    it('S2.3b: UNIQUE-Constraint auf (account_id, request_id) verhindert Race bei doppelter Einfügung', async () => {
      const accountId = 'acc_idempotent_2';
      const sub = 'auth0|idempotent_user_2';
      const reqId = 'client_req_race_222';

      await env.DB.prepare(
        "INSERT INTO accounts (id, auth0_sub, status, generation, created_at) VALUES (?, ?, 'active', 1, datetime('now'))"
      ).bind(accountId, sub).run();

      // Erster Insert succeeds
      await env.DB.prepare(
        `INSERT INTO backups (id, account_id, device_id, r2_key, size, status, request_id, created_at)
         VALUES ('b_race_1', ?, 'dev_1', 'key_race_1', 100, 'active', ?, datetime('now'))`
      ).bind(accountId, reqId).run();

      // Zweiter paralleler Insert mit gleicher (account_id, request_id) scheitert zwingend auf Datenbankebene:
      let caughtError: any = null;
      try {
        await env.DB.prepare(
          `INSERT INTO backups (id, account_id, device_id, r2_key, size, status, request_id, created_at)
           VALUES ('b_race_2', ?, 'dev_1', 'key_race_2', 100, 'active', ?, datetime('now'))`
        ).bind(accountId, reqId).run();
      } catch (err) {
        caughtError = err;
      }

      expect(caughtError).not.toBeNull();
      expect(String(caughtError)).toMatch(/UNIQUE constraint failed/i);
    });
  });

  it('S2.4: Echte Nebenläufigkeit – Parallele Aktivierungen & Beobachter sehen zu keinem Zeitpunkt > 5 aktive Backups', async () => {
    const accountId = 'acc_concurrency_retention';
    const sub = 'auth0|concurrency_retention_user';
    const baseTime = Date.now();

    await env.DB.prepare(
      "INSERT INTO accounts (id, auth0_sub, status, generation, created_at) VALUES (?, ?, 'active', 1, datetime('now'))"
    ).bind(accountId, sub).run();

    // Initial 5 aktive Backups anlegen
    for (let i = 1; i <= 5; i++) {
      const ts = new Date(baseTime + i * 1000).toISOString();
      await env.DB.prepare(
        `INSERT INTO backups (id, account_id, device_id, r2_key, size, status, created_at)
         VALUES (?, ?, 'dev', ?, 100, 'active', ?)`
      ).bind(`b_init_${i}`, accountId, `key_init_${i}`, ts).run();
    }

    const observedCounts: number[] = [];

    // Beobachter-Task: Führt parallele Lese-Abfragen während der Batch-Aktivierung aus
    const readTask = async () => {
      for (let j = 0; j < 5; j++) {
        const count = await env.DB.prepare(
          "SELECT count(*) as cnt FROM backups WHERE account_id = ? AND status = 'active'"
        ).bind(accountId).first<{ cnt: number }>();
        if (count?.cnt !== undefined) {
          observedCounts.push(count.cnt);
        }
      }
    };

    // Parallele Transaktion: Fügt Backup #6 ein und setzt älteste über 5 atomar auf 'deleting'
    const tx = env.DB.batch([
      env.DB.prepare(
        `INSERT INTO backups (id, account_id, device_id, r2_key, size, status, created_at)
         VALUES ('b_tx_6', ?, 'dev', 'key_tx_6', 150, 'active', ?)`
      ).bind(accountId, new Date(baseTime + 6000).toISOString()),
      env.DB.prepare(
        `UPDATE backups SET status = 'deleting'
         WHERE account_id = ? AND status = 'active' AND id NOT IN (
           SELECT id FROM backups 
           WHERE account_id = ? AND status = 'active' 
           ORDER BY created_at DESC LIMIT 5
         )`
      ).bind(accountId, accountId),
    ]);

    // Führe Batch-Transaktion und Beobachter-Reads parallel aus
    await Promise.all([tx, readTask()]);

    // Harte Invariante: Der Beobachter hat zu JEDEM Zeitpunkt maximal 5 aktive Backups gesehen!
    expect(observedCounts.length).toBeGreaterThanOrEqual(1);
    for (const count of observedCounts) {
      expect(count).toBeLessThanOrEqual(5);
    }

    // Endzustand verifizieren: Exakt 5 aktive Backups
    const finalActive = await env.DB.prepare(
      "SELECT count(*) as cnt FROM backups WHERE account_id = ? AND status = 'active'"
    ).bind(accountId).first<{ cnt: number }>();
    expect(finalActive?.cnt).toBe(5);
  });

  it('S2.5: Late Put / GC Ghost Race – D1-Lease verfällt vor Upload-Abschluss; Sweep löscht R2-Ghost', async () => {
    const accountId = 'acc_gc_race_test';
    const sub = 'auth0|gc_race_user';
    const nowEpoch = Math.floor(Date.now() / 1000);
    const expiredEpoch = nowEpoch - 600; // Vor 10 Minuten abgelaufen

    await env.DB.prepare(
      "INSERT INTO accounts (id, auth0_sub, status, generation, created_at) VALUES (?, ?, 'active', 1, datetime('now'))"
    ).bind(accountId, sub).run();

    // 1 aktives Backup vorhanden
    const activeKey = 'r2_safe_active_key';
    await env.DB.prepare(
      `INSERT INTO backups (id, account_id, device_id, r2_key, size, status, created_at)
       VALUES ('b_active_1', ?, 'dev', ?, 500, 'active', datetime('now'))`
    ).bind(accountId, activeKey).run();
    await env.BACKUPS_BUCKET.put(activeKey, 'ACTIVE_DATA');

    // 1 abgelaufenes Staging-Backup in D1
    const latePutKey = 'r2_late_put_ghost_key';
    await env.DB.prepare(
      `INSERT INTO backups (id, account_id, device_id, r2_key, size, status, lease_expires_at_epoch, created_at)
       VALUES ('b_staging_late', ?, 'dev', ?, 0, 'pending', ?, datetime('now', '-10 minutes'))`
    ).bind(accountId, latePutKey, expiredEpoch).run();

    // PHASE 1: D1-GC läuft zuerst und bereinigt den abgelaufenen Staging-Lease aus der DB:
    const expiredCandidates = await env.DB.prepare(
      "SELECT id, r2_key FROM backups WHERE status = 'pending' AND lease_expires_at_epoch < ?"
    ).bind(nowEpoch).all<{ id: string; r2_key: string }>();

    expect(expiredCandidates.results.length).toBe(1);
    for (const c of expiredCandidates.results) {
      await env.DB.prepare("DELETE FROM backups WHERE id = ?").bind(c.id).run();
    }

    // PHASE 2: Der verzögerte Client-Upload beendet JETZT seinen Transfer nach R2 (Ghost Object entsteht):
    await env.BACKUPS_BUCKET.put(latePutKey, 'DELAYED_LATE_PUT_DATA');

    // PHASE 3: Anschließender geplanter R2 Prefix-Sweep scannt R2 und gleicht gegen aktive D1-Backups ab:
    const r2Objects = await env.BACKUPS_BUCKET.list({ prefix: 'r2_' });
    for (const obj of r2Objects.objects) {
      const isKnownInD1 = await env.DB.prepare(
        "SELECT id FROM backups WHERE r2_key = ? AND status = 'active'"
      ).bind(obj.key).first();

      if (!isKnownInD1) {
        // Nicht in D1 als aktiv verzeichnet -> Ghost wird gelöscht!
        await env.BACKUPS_BUCKET.delete(obj.key);
      }
    }

    // Verifikation: Ghost gelöscht, aktives Backup unberührt!
    const ghostObj = await env.BACKUPS_BUCKET.get(latePutKey);
    expect(ghostObj).toBeNull();

    const safeObj = await env.BACKUPS_BUCKET.get(activeKey);
    expect(safeObj).not.toBeNull();
    expect(await safeObj!.text()).toBe('ACTIVE_DATA');

    await env.BACKUPS_BUCKET.delete(activeKey);
  });

  it('S2.6: Datumsabgleich mit ISO-Strings via datetime() und Epoch-Sekunden', async () => {
    const testDateIso = '2020-01-01T00:00:00.000Z';
    const testDateEpoch = Math.floor(new Date(testDateIso).getTime() / 1000);

    // 1. Mit datetime() Funktion in SQLite:
    const res1 = await env.DB.prepare(
      "SELECT (datetime(?) < datetime('now')) as is_past"
    ).bind(testDateIso).first<{ is_past: number }>();
    expect(res1?.is_past).toBe(1);

    // 2. Mit Epoch-Sekunden:
    const res2 = await env.DB.prepare(
      "SELECT (? < strftime('%s', 'now')) as is_past"
    ).bind(testDateEpoch).first<{ is_past: number }>();
    expect(res2?.is_past).toBe(1);
  });
});
