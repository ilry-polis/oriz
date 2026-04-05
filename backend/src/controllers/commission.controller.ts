import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type { CommissionService } from "../services/commission.service.js";

export class CommissionController {
	constructor(private service: CommissionService) {}

	/**
	 * GET /api/v1/commissions
	 * List commissions with optional filters. Owner only.
	 */
	async list(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;

		const query = request.query as {
			professional_id?: string;
			status?: "pending" | "paid";
			period_start?: string;
			period_end?: string;
			cursor?: string;
			limit: number;
		};

		const data = await this.service.list(studioId, {
			professionalId: query.professional_id,
			status: query.status,
			periodStart: query.period_start,
			periodEnd: query.period_end,
			cursor: query.cursor,
			limit: query.limit,
		});

		const hasMore = data.length > query.limit;
		const items = hasMore ? data.slice(0, query.limit) : data;
		const nextCursor = hasMore ? items[items.length - 1]?.id : undefined;

		return reply.send({
			data: items,
			meta: {
				has_more: hasMore,
				next_cursor: nextCursor ?? null,
			},
		});
	}

	/**
	 * POST /api/v1/commissions/pay
	 * Mark a list of commissions as paid. Owner only.
	 */
	async pay(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;

		const body = request.body as {
			commission_ids: string[];
		};

		const updatedCount = await this.service.markPaid(
			studioId,
			body.commission_ids,
		);

		return reply.send({
			data: { updated_count: updatedCount },
		});
	}

	/**
	 * GET /api/v1/commissions/summary
	 * Aggregate commissions by professional for a given period. Owner only.
	 */
	async sumByProfessional(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;

		const query = request.query as {
			period_start?: string;
			period_end?: string;
		};

		const today = new Date().toISOString().slice(0, 10);
		const periodStart = query.period_start ?? `${today.slice(0, 7)}-01`;
		const periodEnd = query.period_end ?? today;

		const data = await this.service.sumByProfessional(
			studioId,
			periodStart,
			periodEnd,
		);

		return reply.send({ data });
	}
}
