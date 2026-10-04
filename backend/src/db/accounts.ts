import type { D1Database, R2Bucket } from '@cloudflare/workers-types';

export interface AccountRow {
  id: string;
  auth0_sub: string;
  created_at: string;
  deleted_at: string | null;
}

export interface ConsentItem {
  type: string;
  granted: boolean;
  granted_at: string | null;
  withdrawn_at: string | null;
  text_version: string;
}

export interface CharterMembershipItem {
  org_id: string;
  org_name: string;
  display_name: string;
  logo_asset: string | null;
  role: string;
}

/**
 * Ruft das Konto anhand von auth0_sub ab oder legt es automatisch an (Projektion der Auth0-Identität).
 */
export async function ensureAccount(db: D1Database, auth0Sub: string): Promise<AccountRow> {
  const existing = await db
    .prepare('SELECT id, auth0_sub, created_at, deleted_at FROM accounts WHERE auth0_sub = ?')
    .bind(auth0Sub)
    .first<AccountRow>();

  if (existing) {
    return existing;
  }

  const id = crypto.randomUUID();
  const now = new Date().toISOString();

  await db
    .prepare('INSERT INTO accounts (id, auth0_sub, created_at) VALUES (?, ?, ?)')
    .bind(id, auth0Sub, now)
    .run();

  return {
    id,
    auth0_sub: auth0Sub,
    created_at: now,
    deleted_at: null,
  };
}

/**
 * Sucht ein Konto anhand von auth0_sub.
 */
export async function getAccountBySub(db: D1Database, auth0Sub: string): Promise<AccountRow | null> {
  return db
    .prepare('SELECT id, auth0_sub, created_at, deleted_at FROM accounts WHERE auth0_sub = ?')
    .bind(auth0Sub)
    .first<AccountRow>();
}

/**
 * Liest alle Einwilligungen eines Kontos.
 */
export async function getConsentsForAccount(
  db: D1Database,
  accountId: string
): Promise<Record<string, ConsentItem>> {
  const query = await db
    .prepare(
      'SELECT type, granted, text_version, granted_at, withdrawn_at FROM consents WHERE account_id = ?'
    )
    .bind(accountId)
    .all<{
      type: string;
      granted: number;
      text_version: string;
      granted_at: string | null;
      withdrawn_at: string | null;
    }>();

  const result: Record<string, ConsentItem> = {};
  for (const row of query.results ?? []) {
    result[row.type] = {
      type: row.type,
      granted: Boolean(row.granted),
      text_version: row.text_version,
      granted_at: row.granted_at,
      withdrawn_at: row.withdrawn_at,
    };
  }
  return result;
}

/**
 * Setzt oder aktualisiert eine Einwilligung.
 */
export async function upsertConsent(
  db: D1Database,
  accountId: string,
  type: string,
  granted: boolean,
  textVersion: string
): Promise<ConsentItem> {
  const existing = await db
    .prepare('SELECT id FROM consents WHERE account_id = ? AND type = ?')
    .bind(accountId, type)
    .first<{ id: number }>();

  const now = new Date().toISOString();
  const grantedAt = granted ? now : null;
  const withdrawnAt = granted ? null : now;

  if (existing) {
    await db
      .prepare(
        'UPDATE consents SET granted = ?, granted_at = ?, withdrawn_at = ?, text_version = ? WHERE id = ?'
      )
      .bind(granted ? 1 : 0, grantedAt, withdrawnAt, textVersion, existing.id)
      .run();
  } else {
    await db
      .prepare(
        'INSERT INTO consents (account_id, type, granted, granted_at, withdrawn_at, text_version, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)'
      )
      .bind(accountId, type, granted ? 1 : 0, grantedAt, withdrawnAt, textVersion, now)
      .run();
  }

  return {
    type,
    granted,
    granted_at: grantedAt,
    withdrawn_at: withdrawnAt,
    text_version: textVersion,
  };
}

/**
 * Liest Charter-Mitgliedschaften des Kontos.
 */
export async function getCharterMembershipsForAccount(
  db: D1Database,
  accountId: string
): Promise<CharterMembershipItem[]> {
  const query = await db
    .prepare(
      `SELECT m.role, o.id as org_id, o.name as org_name, o.display_name, o.logo_asset
       FROM charter_members m
       JOIN charter_orgs o ON m.org_id = o.id
       WHERE m.account_id = ?`
    )
    .bind(accountId)
    .all<CharterMembershipItem>();

  return query.results ?? [];
}

/**
 * Löscht das Konto und alle zugehörigen Daten (D1 und R2).
 */
export async function deleteAccountCascade(
  db: D1Database,
  backupsBucket: R2Bucket,
  accountId: string
): Promise<void> {
  // 1. R2-Sicherungen löschen
  const backups = await db
    .prepare('SELECT r2_key FROM backups WHERE account_id = ?')
    .bind(accountId)
    .all<{ r2_key: string }>();

  for (const b of backups.results ?? []) {
    if (b.r2_key) {
      await backupsBucket.delete(b.r2_key);
    }
  }

  // 2. Konto aus D1 löschen (Kaskadierung löscht consents, backups, crew_forms, charter_members)
  await db.prepare('DELETE FROM accounts WHERE id = ?').bind(accountId).run();
}
