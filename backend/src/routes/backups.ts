import { Hono } from 'hono';
import { z } from 'zod';
import { authMiddleware } from '../auth';
import { ensureAccount } from '../db/accounts';
import { createBackup, listBackups, getBackup } from '../db/backups';
import { jsonError } from '../errors';
import type { Env, AppVariables } from '../types';

export const backupsRouter = new Hono<{ Bindings: Env; Variables: AppVariables }>();

// Alle /v1/backups Routen erfordern Authentifizierung
backupsRouter.use('*', authMiddleware);

const createBackupSchema = z.object({
  device_id: z.string().min(1, 'device_id ist erforderlich'),
  content: z.string().min(1, 'content ist erforderlich'),
});

function containsIban(text: string): boolean {
  if (/"iban"\s*:/i.test(text)) {
    return true;
  }
  const ibanPattern = /\b[A-Z]{2}\d{2}[ \t]?(?:\d{4}[ \t]?){2,7}\d{1,4}\b/i;
  if (ibanPattern.test(text)) {
    return true;
  }
  const compactIbanPattern = /\b[A-Z]{2}\d{2}[A-Z0-9]{11,30}\b/i;
  return compactIbanPattern.test(text);
}

/**
 * POST /v1/backups
 * Lädt eine Sicherung hoch und speichert sie in R2 und D1.
 * Prüft den Inhalt auf Abwesenheit von IBANs.
 */
backupsRouter.post('/', async (c) => {
  const user = c.get('user');
  if (!user?.sub) {
    return jsonError(c, 401, 'UNAUTHORIZED', 'Nicht authentifiziert');
  }

  let body: unknown;
  try {
    body = await c.req.json();
  } catch (_e) {
    return jsonError(c, 400, 'INVALID_INPUT', 'Ungültiges JSON im Request-Body');
  }

  const parseResult = createBackupSchema.safeParse(body);
  if (!parseResult.success) {
    const issue = parseResult.error.issues[0]?.message || 'Ungültige Eingabedaten';
    return jsonError(c, 400, 'INVALID_INPUT', issue);
  }

  const { device_id, content } = parseResult.data;

  // Datenschutzprüfung (Regel 4 / PRD): Keine IBANs im Sicherungsinhalt
  if (containsIban(content)) {
    return jsonError(
      c,
      400,
      'INVALID_BACKUP_CONTENT',
      'Sicherungsinhalt darf keine Zahlungsdaten oder IBANs enthalten'
    );
  }

  const account = await ensureAccount(c.env.DB, user.sub);
  const metadata = await createBackup(c.env.DB, c.env.BACKUPS_BUCKET, account.id, device_id, content);

  return c.json(
    {
      success: true,
      backup: {
        id: metadata.id,
        device_id: metadata.device_id,
        size: metadata.size,
        created_at: metadata.created_at,
      },
    },
    201
  );
});

/**
 * GET /v1/backups
 * Listet alle Sicherungen des angemeldeten Benutzers auf (neueste zuerst).
 */
backupsRouter.get('/', async (c) => {
  const user = c.get('user');
  if (!user?.sub) {
    return jsonError(c, 401, 'UNAUTHORIZED', 'Nicht authentifiziert');
  }

  const account = await ensureAccount(c.env.DB, user.sub);
  const backups = await listBackups(c.env.DB, account.id);

  return c.json({
    backups,
  });
});

/**
 * GET /v1/backups/:id
 * Lädt eine spezifische Sicherung herunter.
 * Gewährleistet Mandantentrennung (nur für den Besitzer zugänglich).
 */
backupsRouter.get('/:id', async (c) => {
  const user = c.get('user');
  if (!user?.sub) {
    return jsonError(c, 401, 'UNAUTHORIZED', 'Nicht authentifiziert');
  }

  const backupId = c.req.param('id');
  const account = await ensureAccount(c.env.DB, user.sub);
  const result = await getBackup(c.env.DB, c.env.BACKUPS_BUCKET, account.id, backupId);

  if (!result) {
    return jsonError(c, 404, 'BACKUP_NOT_FOUND', 'Sicherung nicht gefunden');
  }

  return c.json({
    backup: {
      id: result.metadata.id,
      device_id: result.metadata.device_id,
      size: result.metadata.size,
      created_at: result.metadata.created_at,
    },
    content: result.content,
  });
});
