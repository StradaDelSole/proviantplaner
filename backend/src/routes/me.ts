import { Hono } from 'hono';
import { authMiddleware } from '../auth';
import {
  ensureAccount,
  getAccountBySub,
  getConsentsForAccount,
  getCharterMembershipsForAccount,
  deleteAccountCascade,
} from '../db/accounts';
import { jsonError } from '../errors';
import type { Env, AppVariables } from '../types';

export const meRouter = new Hono<{ Bindings: Env; Variables: AppVariables }>();

// Alle /v1/me Routen erfordern gültige Authentifizierung
meRouter.use('*', authMiddleware);

/**
 * GET /v1/me
 * Ruft Kontoinformationen, Freischaltstatus und Mitgliedschaften ab.
 * Legt das Konto bei Bedarf automatisch an.
 */
meRouter.get('/', async (c) => {
  const user = c.get('user');
  if (!user?.sub) {
    return jsonError(c, 401, 'UNAUTHORIZED', 'Nicht authentifiziert');
  }

  const account = await ensureAccount(c.env.DB, user.sub);
  const consents = await getConsentsForAccount(c.env.DB, account.id);
  const memberships = await getCharterMembershipsForAccount(c.env.DB, account.id);

  return c.json({
    account: {
      id: account.id,
      auth0_sub: account.auth0_sub,
      created_at: account.created_at,
    },
    consents,
    charter_memberships: memberships,
  });
});

/**
 * DELETE /v1/me
 * Löscht das Konto und alle zugehörigen Daten aus D1 und R2 unwiderruflich.
 */
meRouter.delete('/', async (c) => {
  const user = c.get('user');
  if (!user?.sub) {
    return jsonError(c, 401, 'UNAUTHORIZED', 'Nicht authentifiziert');
  }

  const account = await getAccountBySub(c.env.DB, user.sub);
  if (!account) {
    return jsonError(c, 404, 'ACCOUNT_NOT_FOUND', 'Konto nicht gefunden');
  }

  await deleteAccountCascade(c.env.DB, c.env.BACKUPS_BUCKET, account.id);

  return c.json({
    success: true,
    message: 'Konto und alle zugehörigen Daten wurden gelöscht',
  });
});
