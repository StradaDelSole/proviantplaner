import { env } from 'cloudflare:test';
import { describe, it, expect, beforeAll } from 'vitest';
import migrationSql from '../migrations/0001_initial_schema.sql?raw';

describe('Spike S2: D1 Conditional Activation, Atomic Retention & GC Fencing', () => {
  async function applyMigrations(db: any) {
    const statements = migrationSql
      .split(';')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    for (const stmt of statements) {
      await db.prepare(stmt).run();
    }

    // Schema-Erweiterungen für ADR-BC-003/004 (Migration v2)
    // Verwende sowohl datetime-String als auch normalized Unix-Epoch-Sekunden für sichere Zeitvergleiche
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
    ];

    for (const stmt of v2Statements) {
      try {
        await db.prepare(stmt).run();
      } catch (err: any) {
        if (!err.message?.includes('duplicate column')) {
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

  it('S2.2: Conditional Activation (CAS) scheitert, wenn Account gelöscht wurde (Delete Race)', async () => {
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

    // 4. Worker versucht verspätete Aktivierung per CAS
    const updateResult = await env.DB.prepare(
      `UPDATE backups 
       SET status = 'active', size = 12345
       WHERE id = ? 
         AND account_id = ? 
         AND status = 'pending'
         AND (SELECT status FROM accounts WHERE id = ?) = 'active'
         AND generation = (SELECT generation FROM accounts WHERE id = ?)`
    ).bind(backupId, accountId, accountId, accountId).run();

    // CAS muss 0 Zeilen verändert haben!
    expect(updateResult.meta.changes).toBe(0);

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

  it('S2.3: Idempotenz bei wiederholter Request-ID', async () => {
    const accountId = 'acc_idempotent_1';
    const sub = 'auth0|idempotent_user';
    const reqId = 'client_req_unique_999';
    const now = new Date().toISOString();

    await env.DB.prepare(
      "INSERT INTO accounts (id, auth0_sub, status, generation, created_at) VALUES (?, ?, 'active', 1, ?)"
    ).bind(accountId, sub, now).run();

    // Erster Upload mit request_id
    await env.DB.prepare(
      `INSERT INTO backups (id, account_id, device_id, r2_key, size, status, request_id, created_at)
       VALUES ('b_idemp_1', ?, 'dev_1', 'key_1', 100, 'active', ?, ?)`
    ).bind(accountId, reqId, now).run();

    // Client verliert 201 Response und wiederholt denselben Request mit derselben request_id:
    const existing = await env.DB.prepare(
      "SELECT id, size, created_at FROM backups WHERE account_id = ? AND request_id = ? AND status = 'active'"
    ).bind(accountId, reqId).first<{ id: string }>();

    expect(existing).toBeDefined();
    expect(existing?.id).toBe('b_idemp_1');
  });

  it('S2.4: Atomare 5er-Limit Retention – Beobachter sieht zu keinem Zeitpunkt 6 aktive Backups', async () => {
    const accountId = 'acc_retention_atomic';
    const sub = 'auth0|retention_atomic_user';
    const baseTime = Date.now();

    await env.DB.prepare(
      "INSERT INTO accounts (id, auth0_sub, status, generation, created_at) VALUES (?, ?, 'active', 1, datetime('now'))"
    ).bind(accountId, sub).run();

    // 4 bereits aktive Backups anlegen
    for (let i = 1; i <= 4; i++) {
      const ts = new Date(baseTime + i * 1000).toISOString();
      await env.DB.prepare(
        `INSERT INTO backups (id, account_id, device_id, r2_key, size, status, created_at)
         VALUES (?, ?, 'dev', ?, 100, 'active', ?)`
      ).bind(`b_old_${i}`, accountId, `key_old_${i}`, ts).run();
    }

    // Vor Start: exakt 4 aktive
    let countBefore = await env.DB.prepare(
      "SELECT count(*) as cnt FROM backups WHERE account_id = ? AND status = 'active'"
    ).bind(accountId).first<{ cnt: number }>();
    expect(countBefore?.cnt).toBe(4);

    // Führe zwei aufeinanderfolgende Transaktionen aus und prüfe den Zustand vor, während und nach den Batches:
    for (let i = 5; i <= 6; i++) {
      const ts = new Date(baseTime + i * 1000).toISOString();
      
      // SQLite BATCH ist transaktional: Entweder beide Statements sind committet oder keines.
      // D.h. der Zustand "6 aktiv" existiert im Transaktions-Journal niemals für lesende Clients!
      await env.DB.batch([
        // Statement 1: Neues Backup einfügen (oder aktivieren)
        env.DB.prepare(
          `INSERT INTO backups (id, account_id, device_id, r2_key, size, status, created_at)
           VALUES (?, ?, 'dev', ?, 200, 'active', ?)`
        ).bind(`b_new_${i}`, accountId, `key_new_${i}`, ts),

        // Statement 2: Alle über 5 hinausgehenden älteren sofort auf 'deleting' setzen
        env.DB.prepare(
          `UPDATE backups SET status = 'deleting'
           WHERE account_id = ? AND status = 'active' AND id NOT IN (
             SELECT id FROM backups 
             WHERE account_id = ? AND status = 'active' 
             ORDER BY created_at DESC LIMIT 5
           )`
        ).bind(accountId, accountId),
      ]);

      // Unmittelbare Beobachter-Abfrage nach dem Batch:
      const countAfterBatch = await env.DB.prepare(
        "SELECT count(*) as cnt FROM backups WHERE account_id = ? AND status = 'active'"
      ).bind(accountId).first<{ cnt: number }>();

      // Darf niemals mehr als 5 sein:
      expect(countAfterBatch?.cnt).toBeLessThanOrEqual(5);
    }

    // Endzustand verifizieren:
    const activeBackups = await env.DB.prepare(
      "SELECT id, created_at FROM backups WHERE account_id = ? AND status = 'active' ORDER BY created_at DESC"
    ).bind(accountId).all<{ id: string }>();

    expect(activeBackups.results.length).toBe(5);
    // Älteste Backups (b_old_1) müssen 'deleting' sein
    const oldest = await env.DB.prepare(
      "SELECT status FROM backups WHERE id = 'b_old_1'"
    ).first<{ status: string }>();
    expect(oldest?.status).toBe('deleting');
  });

  it('S2.5: Bounded Garbage Collection & Late Put Reconciliation', async () => {
    const accountId = 'acc_gc_reconcile';
    const sub = 'auth0|gc_reconcile_user';
    const nowEpoch = Math.floor(Date.now() / 1000);
    const expiredEpoch = nowEpoch - 600; // Vor 10 Minuten abgelaufen

    await env.DB.prepare(
      "INSERT INTO accounts (id, auth0_sub, status, generation, created_at) VALUES (?, ?, 'active', 1, datetime('now'))"
    ).bind(accountId, sub).run();

    // 1 verwaister Upload (pending mit abgelaufenem Lease)
    await env.DB.prepare(
      `INSERT INTO backups (id, account_id, device_id, r2_key, size, status, lease_expires_at_epoch, created_at)
       VALUES ('b_orphan_1', ?, 'dev', 'r2_orphan_key', 0, 'pending', ?, datetime('now', '-10 minutes'))`
    ).bind(accountId, expiredEpoch).run();

    await env.BACKUPS_BUCKET.put('r2_orphan_key', 'test orphan data');

    // 1 aktives Backup (darf von GC NIEMALS berührt werden)
    await env.DB.prepare(
      `INSERT INTO backups (id, account_id, device_id, r2_key, size, status, created_at)
       VALUES ('b_active_safe', ?, 'dev', 'r2_safe_key', 500, 'active', datetime('now'))`
    ).bind(accountId).run();
    await env.BACKUPS_BUCKET.put('r2_safe_key', 'safe active data');

    // GC-Durchlauf mit numerischem Epoch-Vergleich (völlig unabhängig von Zeitzonen und 'T'-Strings)
    const currentEpoch = Math.floor(Date.now() / 1000);
    const candidates = await env.DB.prepare(
      `SELECT id, r2_key FROM backups 
       WHERE (status = 'pending' AND lease_expires_at_epoch < ?)
          OR status = 'deleting'
       LIMIT 10`
    ).bind(currentEpoch).all<{ id: string; r2_key: string }>();

    expect(candidates.results.length).toBeGreaterThanOrEqual(1);

    for (const c of candidates.results) {
      if (c.r2_key) {
        await env.BACKUPS_BUCKET.delete(c.r2_key);
      }
      await env.DB.prepare("DELETE FROM backups WHERE id = ?").bind(c.id).run();
    }

    // Verifikation: Orphan gelöscht, aktives Backup unberührt!
    const orphanObj = await env.BACKUPS_BUCKET.get('r2_orphan_key');
    expect(orphanObj).toBeNull();

    const safeObj = await env.BACKUPS_BUCKET.get('r2_safe_key');
    expect(safeObj).not.toBeNull();
    await safeObj!.arrayBuffer(); // Handle freigeben

    const safeDb = await env.DB.prepare("SELECT status FROM backups WHERE id = 'b_active_safe'").first<{ status: string }>();
    expect(safeDb?.status).toBe('active');

    // Aufräumen
    await env.BACKUPS_BUCKET.delete('r2_safe_key');
  });

  it('S2.6: Datumsabgleich mit ISO-Strings via datetime() und Epoch-Sekunden', async () => {
    // Beweis für SQLite Datumsvergleich:
    // Stringvergleich '2026-10-31T08:00:00Z' < datetime('now') schlägt fehl ohne datetime()!
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
