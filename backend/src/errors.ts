import type { Context } from 'hono';
import type { ContentfulStatusCode } from 'hono/utils/http-status';

export interface ErrorResponseBody {
  error: {
    code: string;
    message: string;
  };
}

export class AppError extends Error {
  public readonly status: ContentfulStatusCode;
  public readonly code: string;

  constructor(status: ContentfulStatusCode, code: string, message: string) {
    super(message);
    this.name = 'AppError';
    this.status = status;
    this.code = code;
  }
}

export function jsonError(c: Context, status: ContentfulStatusCode, code: string, message: string): Response {
  const body: ErrorResponseBody = {
    error: {
      code,
      message,
    },
  };
  return c.json(body, status);
}
