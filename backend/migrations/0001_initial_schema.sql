-- D1 Initial Schema für proviantplaner (BACKEND_KONZEPT_v0.2 Abschnitt 4)

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