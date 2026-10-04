import { createRemoteJWKSet, jwtVerify, type JWTVerifyGetKey } from 'jose';
import type { Context, Next } from 'hono';
import { jsonError } from './errors';
import type { Env, AppVariables, AuthUser } from './types';

// Cache für Remote-JWKS-Sets nach URL
const jwksCache = new Map<string, JWTVerifyGetKey>();

// Hook für Tests zur Injektion gefälschter JWKS
let testJwks: JWTVerifyGetKey | null = null;

export function setTestJwks(jwks: JWTVerifyGetKey | null): void {
  testJwks = jwks;
}

export function getJwks(jwksUrl: string): JWTVerifyGetKey {
  if (testJwks) {
    return testJwks;
  }
  let jwks = jwksCache.get(jwksUrl);
  if (!jwks) {
    jwks = createRemoteJWKSet(new URL(jwksUrl));
    jwksCache.set(jwksUrl, jwks);
  }
  return jwks;
}

export async function authMiddleware(
  c: Context<{ Bindings: Env; Variables: AppVariables }>,
  next: Next
): Promise<Response | void> {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return jsonError(c, 401, 'UNAUTHORIZED', 'Fehlender oder ungültiger Authorization-Header');
  }

  const token = authHeader.substring(7).trim();
  if (!token) {
    return jsonError(c, 401, 'UNAUTHORIZED', 'Bearer-Token ist leer');
  }

  const issuer = c.env.AUTH0_ISSUER_BASE_URL;
  const audience = c.env.AUTH0_AUDIENCE;
  const jwksUrl = c.env.AUTH0_JWKS_URL || `${issuer.replace(/\/+$/, '')}/.well-known/jwks.json`;

  try {
    const keySet = getJwks(jwksUrl);
    const { payload } = await jwtVerify(token, keySet, {
      issuer,
      audience,
    });

    if (!payload.sub) {
      return jsonError(c, 401, 'UNAUTHORIZED', 'Token enthält kein sub-Claim');
    }

    const user: AuthUser = {
      sub: payload.sub,
      email: typeof payload.email === 'string' ? payload.email : undefined,
    };

    c.set('user', user);
    c.set('auth0Sub', user.sub);

    await next();
  } catch (_err: unknown) {
    return jsonError(c, 401, 'UNAUTHORIZED', 'Token ist ungültig oder abgelaufen');
  }
}
