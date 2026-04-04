import type { FastifyReply, FastifyRequest } from "fastify";
import { createRemoteJWKSet, jwtVerify } from "jose";
import type { Pool } from "pg";
import { ForbiddenError, UnauthorizedError } from "../utils/errors.js";

export type AuthContext = {
	userId: string;
	userName?: string;
	studioId?: string;
	role?: "owner" | "professional";
};

/** AuthContext after requireStudio/requireStudioMember — studioId and role guaranteed. */
export type StudioAuthContext = {
	userId: string;
	studioId: string;
	role: "owner" | "professional";
};

type HookFn = (request: FastifyRequest, reply: FastifyReply) => Promise<void>;

/**
 * Verifies the Supabase JWT and looks up the user's studio membership.
 * Decorates request.authContext with { userId, studioId?, role? }.
 */
export function buildAuthHook(
	pool: Pool,
	jwtSecret: string,
	supabaseUrl?: string,
): HookFn {
	const hmacSecret = new TextEncoder().encode(jwtSecret);

	// Supabase cloud uses ES256 (JWKS), local uses HS256 (symmetric secret)
	const jwksUrl = supabaseUrl
		? new URL(`${supabaseUrl}/auth/v1/.well-known/jwks.json`)
		: null;
	const jwks = jwksUrl ? createRemoteJWKSet(jwksUrl) : null;

	const allowedIssuers = ["supabase"];
	if (supabaseUrl) {
		allowedIssuers.push(`${supabaseUrl}/auth/v1`);
	}

	return async (
		request: FastifyRequest,
		_reply: FastifyReply,
	): Promise<void> => {
		const header = request.headers.authorization;
		if (!header || !header.startsWith("Bearer ")) {
			throw new UnauthorizedError("Missing or invalid Authorization header");
		}

		const token = header.slice(7);
		let userId: string;
		let userName: string | undefined;

		try {
			// Try JWKS first (Supabase cloud, ES256), fall back to HMAC (local, HS256)
			let payload;
			if (jwks) {
				try {
					({ payload } = await jwtVerify(token, jwks, {
						issuer: allowedIssuers,
					}));
				} catch {
					// JWKS failed — try HMAC secret as fallback (local dev or HS256 tokens)
					({ payload } = await jwtVerify(token, hmacSecret, {
						issuer: allowedIssuers,
					}));
				}
			} else {
				({ payload } = await jwtVerify(token, hmacSecret, {
					issuer: allowedIssuers,
				}));
			}
			if (!payload.sub) {
				throw new Error("Missing sub claim");
			}
			userId = payload.sub;
			const userMeta = payload.user_metadata as
				| Record<string, unknown>
				| undefined;
			userName =
				(userMeta?.full_name as string | undefined) ?? undefined;
		} catch {
			throw new UnauthorizedError("Invalid or expired token");
		}

		// Look up studio membership: owner prioritized over professional
		// Note: studios table has no is_active column — filter only professionals.is_active
		const { rows } = await pool.query<{
			studio_id: string;
			role: "owner" | "professional";
		}>(
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
			userName,
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
	return async (
		request: FastifyRequest,
		_reply: FastifyReply,
	): Promise<void> => {
		if (!request.authContext?.studioId) {
			throw new ForbiddenError("No studio associated with this account");
		}
	};
}

/**
 * Requires the user to have one of the specified roles.
 * Must run after authenticate + requireStudio.
 */
export function buildRequireRole(
	...allowedRoles: Array<"owner" | "professional">
): HookFn {
	return async (
		request: FastifyRequest,
		_reply: FastifyReply,
	): Promise<void> => {
		const role = request.authContext?.role;
		if (!role || !allowedRoles.includes(role)) {
			throw new ForbiddenError("Insufficient role for this operation");
		}
	};
}
