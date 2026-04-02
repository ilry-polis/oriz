import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import { ForbiddenError } from "../utils/errors.js";

/**
 * requireOwner — Fastify preHandler hook.
 * Rejects requests from collaborators with 403 OWNER_ONLY.
 * Must run after authenticate + requireStudio.
 *
 * Used on: POST /professionals/invites, PATCH /professionals/:id, PATCH /professionals/:id/active
 *
 * Permission table:
 * | Endpoint                          | Owner | Collaborator |
 * |-----------------------------------|-------|--------------|
 * | POST /professionals/invites       | Yes   | 403          |
 * | GET /professionals                | Yes   | Yes (no commissions of others) |
 * | GET /professionals/:id            | Yes   | Own: full, Others: no commission |
 * | PATCH /professionals/:id          | Yes   | 403          |
 * | PATCH /professionals/:id/active   | Yes   | 403          |
 */
export async function requireOwner(
	request: FastifyRequest,
	reply: FastifyReply,
): Promise<void> {
	const ctx = request.authContext as StudioAuthContext;
	if (!ctx || ctx.role !== "owner") {
		return reply.status(403).send({
			errors: [
				{
					code: "OWNER_ONLY",
					message: "Apenas o proprietário pode realizar esta ação",
				},
			],
		});
	}
}

/**
 * requireSelf — Fastify preHandler hook.
 * Allows owner to access any professional's data.
 * Allows collaborator to access only their own data (by professionalId).
 * Rejects collaborator attempts to access other professionals' data with 403.
 *
 * Expects request.params.id to be the professional UUID being accessed.
 * Requires request.authContext.professionalId to be set (done in auth middleware
 * for professional role).
 */
export async function requireSelf(
	request: FastifyRequest,
	reply: FastifyReply,
): Promise<void> {
	const ctx = request.authContext as StudioAuthContext & {
		professionalId?: string;
	};
	if (!ctx) {
		return reply
			.status(403)
			.send({ errors: [{ code: "FORBIDDEN", message: "Acesso negado" }] });
	}

	// Owner can access any professional's data
	if (ctx.role === "owner") return;

	// Collaborator can only access their own data
	const params = request.params as { id?: string };
	if (!params.id || ctx.professionalId !== params.id) {
		return reply.status(403).send({
			errors: [
				{
					code: "FORBIDDEN",
					message: "Você só pode acessar seus próprios dados",
				},
			],
		});
	}
}
