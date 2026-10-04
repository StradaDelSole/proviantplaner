import type { D1Database, R2Bucket } from '@cloudflare/workers-types';

export interface Env {
  DB: D1Database;
  BACKUPS_BUCKET: R2Bucket;
  ENVIRONMENT: string;
  AUTH0_ISSUER_BASE_URL: string;
  AUTH0_AUDIENCE: string;
  AUTH0_JWKS_URL?: string;
  ALLOWED_ORIGINS?: string;
}

export interface AuthUser {
  sub: string;
  email?: string;
}

export interface AppVariables {
  user?: AuthUser;
  accountId?: string;
  auth0Sub?: string;
}

declare module 'cloudflare:test' {
  interface ProvidedEnv extends Env {}
}

