import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type { InviteService } from "../services/invite.service.js";

export class InviteController {
	constructor(private service: InviteService) {}

	/**
	 * POST /api/v1/professionals/invites
	 * Auth: required + owner only
	 * Owner pre-configures: name, services, commission, card fee policy.
	 * Returns invite_token, expires_at, and whatsapp_link.
	 */
	async create(request: FastifyRequest, reply: FastifyReply) {
		const { studioId, userId } = request.authContext as StudioAuthContext;
		const body = request.body as {
			name: string;
			phone?: string;
			service_ids?: string[];
			commission_type: "percentage" | "fixed";
			commission_value: number;
			card_fee_policy: "studio" | "professional" | "split";
		};

		const result = await this.service.createInvite(studioId, userId, {
			name: body.name,
			phone: body.phone,
			serviceIds: body.service_ids ?? [],
			commissionType: body.commission_type,
			commissionValue: body.commission_value,
			cardFeePolicy: body.card_fee_policy,
		});

		return reply.status(201).send({ data: result });
	}

	/**
	 * GET /api/v1/professionals/invites
	 * Auth: required + owner only
	 * Lists pending invites for the studio.
	 */
	async listPending(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { cursor, limit } = request.query as {
			cursor?: string;
			limit?: number;
		};
		const result = await this.service.listPendingInvites(studioId, {
			cursor,
			limit,
		});
		return reply.send({ data: result.invites, meta: result.meta });
	}

	/**
	 * DELETE /api/v1/professionals/invites/:token
	 * Auth: required + owner only
	 * Cancels a pending invite.
	 */
	async cancel(request: FastifyRequest, reply: FastifyReply) {
		try {
			const authCtx = request.authContext as StudioAuthContext;
			request.log.info({ authCtx, params: request.params }, "[DEBUG] cancel invite — start");
			const { studioId } = authCtx;
			const { token } = request.params as { token: string };
			await this.service.cancelInvite(studioId, token);
			request.log.info({ token }, "[DEBUG] cancel invite — success");
			return reply.status(204).send();
		} catch (err) {
			request.log.error(err, "[DEBUG] cancel invite — error");
			throw err;
		}
	}

	/**
	 * POST /api/v1/professionals/invites/:token/resend
	 * Auth: required + owner only
	 * Extends invite expiry and returns new whatsapp_link.
	 */
	async resend(request: FastifyRequest, reply: FastifyReply) {
		try {
			const authCtx = request.authContext as StudioAuthContext;
			request.log.info({ authCtx, params: request.params }, "[DEBUG] resend invite — start");
			const { studioId } = authCtx;
			const { token } = request.params as { token: string };
			const result = await this.service.resendInvite(studioId, token);
			request.log.info({ token, result }, "[DEBUG] resend invite — success");
			return reply.send({ data: result });
		} catch (err) {
			request.log.error(err, "[DEBUG] resend invite — error");
			throw err;
		}
	}

	/**
	 * GET /api/v1/professionals/invites/:token
	 * Auth: public (no auth — collaborator entry point)
	 * Rate limit: 30/min per IP (prevents token enumeration)
	 * Returns studio_name and collaborator's pre-configured name for the accept screen.
	 */
	async getInfo(request: FastifyRequest, reply: FastifyReply) {
		const { token } = request.params as { token: string };
		const result = await this.service.getInviteInfo(token);
		return reply.send({ data: result });
	}

	/**
	 * POST /api/v1/auth/accept-invite
	 * Auth: public (no auth — creates the collaborator's account)
	 * Rate limit: 5/min per IP (prevents brute-force token guessing)
	 * Creates Supabase Auth user + professional row + service links.
	 * Returns session for immediate login.
	 */
	async accept(request: FastifyRequest, reply: FastifyReply) {
		const body = request.body as {
			token: string;
			email: string;
			password: string;
		};
		const session = await this.service.acceptInvite(
			body.token,
			body.email,
			body.password,
		);
		return reply.status(201).send({ data: session });
	}
}
