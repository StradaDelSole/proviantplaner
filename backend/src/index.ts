import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { AppError, jsonError } from './errors';
import type { Env, AppVariables } from './types';

const app = new Hono<{ Bindings: Env; Variables: AppVariables }>();

// CORS-Middleware
app.use('*', async (c, next) => {
  const allowed = c.env.ALLOWED_ORIGINS
    ? c.env.ALLOWED_ORIGINS.split(',').map((o) => o.trim())
    : ['*'];

  const corsMiddleware = cors({
    origin: (origin) => {
      if (allowed.includes('*') || (origin && allowed.includes(origin))) {
        return origin || '*';
      }
      return null;
    },
    allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowHeaders: ['Content-Type', 'Authorization'],
    maxAge: 86400,
  });

  return corsMiddleware(c, next);
});

// Health-Check
app.get('/health', (c) => {
  return c.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
  });
});

// API Info
app.get('/v1/info', (c) => {
  return c.json({
    name: 'proviantplaner-backend',
    version: '0.1.0',
    environment: c.env.ENVIRONMENT || 'development',
  });
});

// 404 Handler
app.notFound((c) => {
  return jsonError(c, 404, 'NOT_FOUND', `Route ${c.req.path} nicht gefunden`);
});

// Globaler Error Handler (GEMINI.md Backend-Regeln: einheitlich Code + Meldung, keine internen Details)
app.onError((err, c) => {
  if (err instanceof AppError) {
    return jsonError(c, err.status, err.code, err.message);
  }

  // Unerwartete Fehler: Keine Interna an den Client leiten
  return jsonError(c, 500, 'INTERNAL_SERVER_ERROR', 'Ein unerwarteter Fehler ist aufgetreten');
});

export default app;
