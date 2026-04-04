import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type { ProfessionalService } from "../services/professional.service.js";

export class ProfessionalController {
	constructor(private service: ProfessionalService) {}

	/**
	 * GET /api/v1/professionals
	 * Auth: owner + collaborator
	 * Collaborator sees all names but NOT commission data of other professionals.
	 * Owner sees full data including commissions.
	 */
	async list(request: FastifyRequest, reply: FastifyReply) {
		const { studioId, role } = request.authContext as StudioAuthContext;
		const query = request.query as { cursor?: string; limit?: number };

		const result = await this.service.listProfessionals(
			studioId,
			query.cursor,
			query.limit,
		);

		// Strip commission data for collaborators — they see their own, not others'
		if (role === "professional") {
			const { userId } = request.authContext as StudioAuthContext & { userId: string };
			result.data = result.data.map((p) => {
				if (p.user_id === userId) return p;
				const { commission_type, commission_value, card_fee_policy, ...safe } = p;
				return safe;
			}) as unknown as typeof result.data;
		}

		return reply.send(result);
	}

	/**
	 * GET /api/v1/professionals/me
	 * Auth: owner + collaborator
	 * Returns the current user's professional record in the current studio.
	 */
	async getMe(request: FastifyRequest, reply: FastifyReply) {
		const { studioId, userId } = request.authContext as StudioAuthContext;
		const professional = await this.service.getProfessionalByUserId(
			userId,
			studioId,
		);
		if (!professional) {
			return reply.status(404).send({
				errors: [
					{ code: "RESOURCE_NOT_FOUND", message: "Professional not found" },
				],
			});
		}
		return reply.send({ data: professional });
	}

	/**
	 * GET /api/v1/professionals/:id
	 * Auth: owner + collaborator
	 * Collaborator: full data for own record, commission stripped for others.
	 * Owner: full data for all professionals.
	 */
	async getById(request: FastifyRequest, reply: FastifyReply) {
		const { studioId, role } = request.authContext as StudioAuthContext & {
			professionalId?: string;
		};
		const { id } = request.params as { id: string };
		const selfId = (
			request.authContext as StudioAuthContext & { professionalId?: string }
		).professionalId;

		const professional = await this.service.getProfessionalById(studioId, id);

		// Collaborator cannot see other professionals' commission data
		if (role === "professional" && id !== selfId) {
			const { commission_type, commission_value, card_fee_policy, ...safe } =
				professional;
			return reply.send({ data: safe });
		}

		return reply.send({ data: professional });
	}

	/**
	 * PATCH /api/v1/professionals/:id
	 * Auth: owner only (enforced by requireOwner preHandler on the route)
	 * Updates professional fields; optionally replaces service links if service_ids provided.
	 * Note: also handles working_hours update (consolidates the previous stub).
	 */
	async update(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };
		const body = request.body as {
			name?: string;
			commission_type?: "percentage" | "fixed";
			commission_value?: number;
			card_fee_policy?: "studio" | "professional" | "split";
			is_active?: boolean;
			working_hours?: Record<string, unknown>;
			service_ids?: string[];
		};

		const updateData: Parameters<typeof this.service.updateProfessional>[2] = {
			service_ids: body.service_ids,
		};
		if (body.name !== undefined) updateData.name = body.name;
		if (body.commission_type !== undefined)
			updateData.commissionType = body.commission_type;
		if (body.commission_value !== undefined)
			updateData.commissionValue = body.commission_value;
		if (body.card_fee_policy !== undefined)
			updateData.cardFeePolicy = body.card_fee_policy;
		if (body.is_active !== undefined) updateData.isActive = body.is_active;
		if (body.working_hours !== undefined)
			updateData.workingHours = body.working_hours;

		const result = await this.service.updateProfessional(
			studioId,
			id,
			updateData,
		);
		return reply.send({ data: result });
	}

	/**
	 * PATCH /api/v1/professionals/:id/active
	 * Auth: owner only (enforced by requireOwner preHandler on the route)
	 */
	async toggleActive(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };
		const { is_active } = request.body as { is_active: boolean };

		const result = await this.service.toggleActive(studioId, id, is_active);
		return reply.send({ data: result });
	}
}
