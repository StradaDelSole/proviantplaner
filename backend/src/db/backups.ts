import type { D1Database, R2Bucket } from '@cloudflare/workers-types';

export interface BackupMetadata {
  id: string;
  account_id: string;
  device_id: string;
  r2_key: string;
  size: number;
  created_at: string;
}

export interface BackupContentResult {
  metadata: BackupMetadata;
  content: string;
}

/**
 * Erstellt eine neue Sicherung in R2 und D1.
 * Begrenzt die Anzahl auf maximal 5 Sicherungen je Konto (älteste über 5 hinausgehende werden gelöscht).
 */
export async function createBackup(
  db: D1Database,
  bucket: R2Bucket,
  accountId: string,
  deviceId: string,
  content: string
): Promise<BackupMetadata> {
  const backupId = crypto.randomUUID();
  const r2Key = `backups/${accountId}/${backupId}.json`;
  const size = new TextEncoder().encode(content).length;
  const now = new Date().toISOString();

  // 1. Inhalt in R2 schreiben
  await bucket.put(r2Key, content, {
    httpMetadata: {
      contentType: 'application/json',
    },
  });

  // 2. Metadaten in D1 schreiben
  await db
    .prepare(
      'INSERT INTO backups (id, account_id, device_id, r2_key, size, created_at) VALUES (?, ?, ?, ?, ?, ?)'
    )
    .bind(backupId, accountId, deviceId, r2Key, size, now)
    .run();

  // 3. Auf maximal 5 Sicherungen begrenzen (neueste 5 behalten)
  const allBackups = await db
    .prepare('SELECT id, r2_key FROM backups WHERE account_id = ? ORDER BY created_at DESC')
    .bind(accountId)
    .all<{ id: string; r2_key: string }>();

  const results = allBackups.results ?? [];
  if (results.length > 5) {
    const surplus = results.slice(5);
    for (const old of surplus) {
      if (old.r2_key) {
        await bucket.delete(old.r2_key);
      }
      await db.prepare('DELETE FROM backups WHERE id = ?').bind(old.id).run();
    }
  }

  return {
    id: backupId,
    account_id: accountId,
    device_id: deviceId,
    r2_key: r2Key,
    size,
    created_at: now,
  };
}

/**
 * Listet alle Sicherungen eines Kontos auf (neueste zuerst).
 */
export async function listBackups(
  db: D1Database,
  accountId: string
): Promise<Array<Omit<BackupMetadata, 'account_id' | 'r2_key'>>> {
  const query = await db
    .prepare(
      'SELECT id, device_id, size, created_at FROM backups WHERE account_id = ? ORDER BY created_at DESC'
    )
    .bind(accountId)
    .all<Omit<BackupMetadata, 'account_id' | 'r2_key'>>();

  return query.results ?? [];
}

/**
 * Ruft eine spezifische Sicherung ab und lädt den Inhalt aus R2.
 * Gewährleistet Mandantentrennung (nur für accountId zugänglich).
 */
export async function getBackup(
  db: D1Database,
  bucket: R2Bucket,
  accountId: string,
  backupId: string
): Promise<BackupContentResult | null> {
  const metadata = await db
    .prepare(
      'SELECT id, account_id, device_id, r2_key, size, created_at FROM backups WHERE id = ? AND account_id = ?'
    )
    .bind(backupId, accountId)
    .first<BackupMetadata>();

  if (!metadata) {
    return null;
  }

  const obj = await bucket.get(metadata.r2_key);
  if (!obj) {
    return null;
  }

  const content = await obj.text();
  return {
    metadata,
    content,
  };
}
