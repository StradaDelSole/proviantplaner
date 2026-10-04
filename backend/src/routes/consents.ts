import { Hono } from 'hono';
import { z } from 'zod';
import { authMiddleware } from '../auth';
import { ensureAccount, upsertConsent } from '../db/accounts';
import { jsonError } from '../errors';
import type { Env, AppVariables } from '../types';

export const consentsRouter = new Hono<{ Bindings: Env; Variables: AppVariables }>();

// Alle /v1/consents Routen erfordern Authentifizierung
consentsRouter.use('*', authMiddleware);

const putConsentSchema = z.object({
  granted: z.boolean(),
  text_version: z.string().min(1, 'text_version muss angegeben werden'),
});

/**
 * PUT /v1/consents/boat-market-news
 * Erteilt oder widerruft die Einwilligung für Bootsmarkt-Informationen.
 */
consentsRouter.put('/boat-market-news', async (c) => {
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

  const parseResult = putConsentSchema.safeParse(body);
  if (!parseResult.success) {
    const issue = parseResult.error.issues[0]?.message || 'Ungültige Eingabedaten';
    return jsonError(c, 400, 'INVALID_INPUT', issue);
  }

  const { granted, text_version } = parseResult.data;
  const account = await ensureAccount(c.env.DB, user.sub);
  const consent = await upsertConsent(
    c.env.DB,
    account.id,
    'boat_market_news',
    granted,
    text_version
  );

  return c.json({
    success: true,
    consent,
  });
});
