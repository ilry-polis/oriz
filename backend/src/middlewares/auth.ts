import type { FastifyReply, FastifyRequest } from 'fastify';
import { jwtVerify } from 'jose';
import type { Pool } from 'pg';
import { UnauthorizedError, ForbiddenError } from '../utils/errors.js';

export type AuthContext = {
  userId: string;
  studioId?: string;
  role?: 'owner' | 'professional';
};

/** AuthContext after requireStudio/requireStudioMember — studioId and role guaranteed. */
export type StudioAuthContext = {
  userId: string;
  studioId: string;
  role: 'owner' | 'professional';
};

type HookFn = (request: FastifyRequest, reply: FastifyReply) => Promise<void>;

/**
 * Verifies the Supabase JWT and looks up the user's studio membership.
 * Decorates request.authContext with { userId, studioId?, role? }.
 */
export function buildAuthHook(pool: Pool, jwtSecret: string, supabaseUrl?: string): HookFn {
  const secret = new TextEncoder().encode(jwtSecret);
  // Supabase local uses issuer "supabase", cloud uses "https://<ref>.supabase.co/auth/v1"
  const allowedIssuers = ['supabase'];
  if (supabaseUrl) {
    allowedIssuers.push(`${supabaseUrl}/auth/v1`);
  }

  return async (request: FastifyRequest, _reply: FastifyReply): Promise<void> => {
    const header = request.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      throw new UnauthorizedError('Missing or invalid Authorization header');
    }

    const token = header.slice(7);
    let userId: string;

    try {
      const { payload } = await jwtVerify(token, secret, {
        issuer: allowedIssuers,
      });
      if (!payload.sub) {
        throw new Error('Missing sub claim');
      }
      userId = payload.sub;
    } catch {
      throw new UnauthorizedError('Invalid or expired token');
    }

    // Look up studio membership: owner prioritized over professional
    const { rows } = await pool.query<{ studio_id: string; role: 'owner' | 'professional' }>(
      `(SELECT s.id AS studio_id, 'owner' AS role, 1 AS priority
        FROM studios s WHERE s.owner_id = $1)
       UNION ALL
       (SELECT p.studio_id, 'professional' AS role, 2 AS priority
        FROM professionals p
        JOIN studios s ON s.id = p.studio_id
        WHERE p.user_id = $1 AND p.is_active = true)
       ORDER BY priority
       LIMIT 1`,
      [userId],
    );

    const membership = rows[0];

    request.authContext = {
      userId,
      studioId: membership?.studio_id,
      role: membership?.role,
    };
  };
}

/**
 * Requires the user to be associated with a studio.
 * Must run after authenticate.
 */
export function buildRequireStudio(): HookFn {
  return async (request: FastifyRequest, _reply: FastifyReply): Promise<void> => {
    if (!request.authContext?.studioId) {
      throw new ForbiddenError('No studio associated with this account');
    }
  };
}

/**
 * Requires the user to have one of the specified roles.
 * Must run after authenticate + requireStudio.
 */
export function buildRequireRole(...allowedRoles: Array<'owner' | 'professional'>): HookFn {
  return async (request: FastifyRequest, _reply: FastifyReply): Promise<void> => {
    const role = request.authContext?.role;
    if (!role || !allowedRoles.includes(role)) {
      throw new ForbiddenError('Insufficient role for this operation');
    }
  };
}
