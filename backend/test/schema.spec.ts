import { env } from 'cloudflare:test';
import { describe, it, expect, beforeAll } from 'vitest';

const SCHEMA_SQL = `
CREATE TABLE IF NOT EXISTS accounts (
  id TEXT PRIMARY KEY,
  auth0_sub TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  deleted_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_accounts_auth0_sub ON accounts(auth0_sub);

CREATE TABLE IF NOT EXISTS consents (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  granted INTEGER NOT NULL DEFAULT 0,
  granted_at TEXT,
  withdrawn_at TEXT,
  text_version TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_consents_account_type ON consents(account_id, type);

CREATE TABLE IF NOT EXISTS backups (
  id TEXT PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  r2_key TEXT NOT NULL UNIQUE,
  size INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_backups_account_created ON backups(account_id, created_at DESC);

CREATE TABLE IF NOT EXISTS crew_forms (
  id TEXT PRIMARY KEY,
  token_hash TEXT NOT NULL UNIQUE,
  account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  trip_ref TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_crew_forms_token_hash ON crew_forms(token_hash);

CREATE TABLE IF NOT EXISTS crew_answers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  form_id TEXT NOT NULL REFERENCES crew_forms(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  vegetarian INTEGER NOT NULL DEFAULT 0,
  no_alcohol INTEGER NOT NULL DEFAULT 0,
  dislikes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_crew_answers_form_id ON crew_answers(form_id);

CREATE TABLE IF NOT EXISTS charter_orgs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  display_name TEXT NOT NULL,
  logo_asset TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS charter_members (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  org_id TEXT NOT NULL REFERENCES charter_orgs(id) ON DELETE CASCADE,
  account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'admin',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(org_id, account_id)
);
CREATE INDEX IF NOT EXISTS idx_charter_members_account ON charter_members(account_id);

CREATE TABLE IF NOT EXISTS charter_bases (
  id TEXT PRIMARY KEY,
  org_id TEXT NOT NULL REFERENCES charter_orgs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  marina TEXT NOT NULL,
  handover_time TEXT,
  supplier_name TEXT,
  supplier_email TEXT,
  supplier_whatsapp TEXT,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_charter_bases_org ON charter_bases(org_id);

CREATE TABLE IF NOT EXISTS trip_code_batches (
  id TEXT PRIMARY KEY,
  org_id TEXT NOT NULL REFERENCES charter_orgs(id) ON DELETE CASCADE,
  base_id TEXT NOT NULL REFERENCES charter_bases(id) ON DELETE CASCADE,
  valid_from TEXT NOT NULL,
  valid_to TEXT NOT NULL,
  max_uses_per_code INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_trip_code_batches_org ON trip_code_batches(org_id);

CREATE TABLE IF NOT EXISTS trip_codes (
  code_hash TEXT PRIMARY KEY,
  batch_id TEXT NOT NULL REFERENCES trip_code_batches(id) ON DELETE CASCADE,
  uses INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_trip_codes_batch ON trip_codes(batch_id);

CREATE TABLE IF NOT EXISTS trip_code_redemptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code_hash TEXT NOT NULL REFERENCES trip_codes(code_hash) ON DELETE CASCADE,
  account_id TEXT REFERENCES accounts(id) ON DELETE SET NULL,
  device_id TEXT,
  redeemed_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_redemptions_code_hash ON trip_code_redemptions(code_hash);
`;

describe('B0: D1 Database Schema Migrationen & Tabellen', () => {
  beforeAll(async () => {
    // Migration 0001 anwenden: Statements einzeln ausführen
    const statements = SCHEMA_SQL
      .split(';')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    for (const sql of statements) {
      await env.DB.prepare(sql).run();
    }
  });

  it('Alle 11 Tabellen aus BACKEND_KONZEPT_v0.2 Abschnitt 4 existieren', async () => {
    const query = await env.DB.prepare(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_cf_%' ORDER BY name ASC"
    ).all<{ name: string }>();

    const results = (query.results ?? []) as Array<{ name: string }>;
    const tableNames = results.map((r: { name: string }) => r.name);

    const expectedTables = [
      'accounts',
      'backups',
      'charter_bases',
      'charter_members',
      'charter_orgs',
      'consents',
      'crew_answers',
      'crew_forms',
      'trip_code_batches',
      'trip_code_redemptions',
      'trip_codes',
    ];

    for (const expected of expectedTables) {
      expect(tableNames, `Tabelle ${expected} fehlt in D1`).toContain(expected);
    }
  });

  it('Accounts und Consents CRUD funktioniert mit Foreign-Keys', async () => {
    await env.DB.prepare(
      "INSERT INTO accounts (id, auth0_sub) VALUES (?, ?)"
    ).bind('acc_test_1', 'auth0|123456').run();

    await env.DB.prepare(
      "INSERT INTO consents (account_id, type, granted, text_version) VALUES (?, ?, 1, 'v1.0')"
    ).bind('acc_test_1', 'boat_market_news').run();

    const consent = await env.DB.prepare(
      "SELECT * FROM consents WHERE account_id = ?"
    ).bind('acc_test_1').first<{ account_id: string; granted: number; type: string }>();

    expect(consent).toBeDefined();
    expect(consent?.granted).toBe(1);
    expect(consent?.type).toBe('boat_market_news');
  });

  it('R2 Bucket Binding ist verfügbar', async () => {
    expect(env.BACKUPS_BUCKET).toBeDefined();
    await env.BACKUPS_BUCKET.put('test-key.txt', 'test content');
    const obj = await env.BACKUPS_BUCKET.get('test-key.txt');
    expect(obj).not.toBeNull();
    const text = await obj?.text();
    expect(text).toBe('test content');
    await env.BACKUPS_BUCKET.delete('test-key.txt');
  });
});